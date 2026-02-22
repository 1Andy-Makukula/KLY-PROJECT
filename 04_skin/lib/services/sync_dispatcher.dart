/// =============================================================================
/// KithLy Global Protocol - PIPELINE 1: SYNC DISPATCHER
/// sync_dispatcher.dart - The Engine that Drains the Offline Action Queue
/// =============================================================================
///
/// ARCHITECTURE OVERVIEW:
///
///   ┌──────────┐   enqueue    ┌──────────────────────┐   LPUSH    ┌─────────┐
///   │  Flutter  │ ──────────▶ │ local_database_helper │           │  Redis  │
///   │    UI     │             │  (SQLite Queue)       │           │ (Server)│
///   └──────────┘             └──────────┬───────────┘           └─────────┘
///                                       │                            ▲
///                                       │ getPendingActions()        │
///                                       ▼                            │
///                              ┌─────────────────┐   HTTP POST      │
///                              │ SyncDispatcher   │ ─────────────────┘
///                              │ (this file)      │   + Idempotency-Key
///                              └─────────────────┘
///
/// The SyncDispatcher is a Singleton that:
///   1. Reads queued actions from SQLite (oldest first / FIFO).
///   2. POSTs each one to the Gateway with the `Idempotency-Key` header.
///   3. Garbage-collects confirmed actions and retries failed ones.
///   4. Listens for network recovery via `connectivity_plus` and auto-drains.
///
/// It does NOT touch `sync_db.dart` or `sync_manager.dart` — those handle
/// the older Phase IV upload pipeline.  This dispatcher is the new Phase V+
/// offline-first engine.
/// =============================================================================
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'local_database_helper.dart';

// ---------------------------------------------------------------------------
// CONSTANTS
// ---------------------------------------------------------------------------

/// Gateway base URL — same as ApiService so all traffic goes through one door.
/// In production, swap via env / flavour config.
const String _kBaseUrl = 'http://localhost:8000';

/// Maximum retries before we give up on a row permanently.
/// With exponential back-off (2^n seconds, capped at 5 min), 8 retries ≈ 8.5 min
/// of total wait — enough to ride out a short MTN outage.
const int _kMaxRetries = 8;

/// Per-request timeout.  Lusaka mobile latency can spike, but anything over
/// 30 s is effectively a dead connection.
const Duration _kRequestTimeout = Duration(seconds: 30);

// ---------------------------------------------------------------------------
// SYNC DISPATCHER (SINGLETON)
// ---------------------------------------------------------------------------

/// The engine that drains [LocalDatabaseHelper]'s `offline_action_queue`.
///
/// ```dart
/// // At app startup (e.g. in main.dart or a top-level provider):
/// final dispatcher = SyncDispatcher.instance;
/// dispatcher.listenToNetwork();       // auto-drain on reconnect
/// await dispatcher.processQueue();    // drain anything already queued
/// ```
class SyncDispatcher {
  // ── Singleton boilerplate ──────────────────────────────────────────────
  static final SyncDispatcher _instance = SyncDispatcher._internal();
  SyncDispatcher._internal();
  static SyncDispatcher get instance => _instance;

  // ── Dependencies ───────────────────────────────────────────────────────
  final LocalDatabaseHelper _db = LocalDatabaseHelper.instance;

  // ── Internal state ─────────────────────────────────────────────────────
  /// Guard flag — prevents two `processQueue()` runs from overlapping.
  bool _isSyncing = false;

  /// Subscription to the connectivity stream; cancelled in [dispose].
  StreamSubscription<ConnectivityResult>? _networkSub;

  /// Tracks the last-known connectivity so we can detect `none → online`.
  bool _wasOffline = false;

  // ── Observable streams for the UI ──────────────────────────────────────
  final _statusController = StreamController<String>.broadcast();

  /// Stream that emits human-readable status strings for debug / UI badges.
  Stream<String> get statusStream => _statusController.stream;

  // =====================================================================
  //  processQueue()  — The core drain loop
  // =====================================================================

  /// Fetches every pending/failed action from SQLite and attempts to POST
  /// each one to the Gateway, oldest first (FIFO).
  ///
  /// **Idempotency**: The `Idempotency-Key` header is injected into every
  /// request.  Even if the phone sends the same payload twice (e.g. after a
  /// timeout where the server actually received it), the Gateway will
  /// de-duplicate on its Redis side — no double-charge.
  Future<void> processQueue() async {
    // ── Re-entrancy guard ─────────────────────────────────────────────
    // If processQueue() is already running (e.g. the heartbeat timer fires
    // while a network-recovery drain is in progress), we skip silently.
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add('syncing');

    try {
      final actions = await _db.getPendingActions();

      if (actions.isEmpty) {
        _statusController.add('idle');
        return; // nothing to do
      }

      for (final action in actions) {
        // Mark as "syncing" so the UI can show a spinner on this row.
        await _db.updateActionStatus(action.id!, ActionStatus.syncing);

        final result = await _attemptPost(action);

        switch (result) {
          case _PostResult.success:
            // ── 202 / 200 / 201: Server confirmed receipt ────────────
            // The Gateway has the payload in Redis.  Remove the local
            // row to keep the SQLite file small on low-storage phones.
            await _db.removeCompletedAction(action.id!);
            break;

          case _PostResult.clientError:
            // ── 400 / 401 / 403: Permanent rejection ─────────────────
            // Something is wrong with the request itself (bad auth,
            // invalid payload).  Retrying will never succeed — mark as
            // failed permanently so we don't waste battery & bandwidth.
            await _db.updateActionStatus(action.id!, ActionStatus.failed);
            break;

          case _PostResult.serverOrNetworkError:
            // ── 500+ or SocketException: Transient failure ───────────
            // The server is down or the MTN link dropped mid-flight.
            // Bump retry_count for exponential back-off and try again
            // on the next pass.
            final newRetryCount = action.retryCount + 1;

            if (newRetryCount >= _kMaxRetries) {
              // We've exhausted all retries — park it as permanently failed.
              await _db.updateActionStatus(action.id!, ActionStatus.failed);
            } else {
              await _db.incrementRetry(action.id!);

              // Apply exponential back-off WITHIN this drain pass:
              // wait before attempting the next row, giving the server
              // a moment to recover.
              final backoff = _exponentialBackoff(newRetryCount);
              await Future.delayed(backoff);
            }
            break;
        }
      }

      // Report final count for UI badges.
      final remaining = await _db.getPendingCount();
      _statusController.add(remaining == 0 ? 'idle' : 'pending:$remaining');
    } catch (e) {
      // Catch-all so the dispatcher never crashes.  Errors here are
      // typically SQLite I/O issues — extremely rare.
      _statusController.add('error');
    } finally {
      _isSyncing = false;
    }
  }

  // =====================================================================
  //  listenToNetwork()  — Auto-drain on reconnect
  // =====================================================================

  /// Subscribes to `connectivity_plus` and triggers [processQueue] whenever
  /// the device transitions from **offline → online**.
  ///
  /// Call once at app startup.  Idempotent — calling again replaces the
  /// existing subscription.
  void listenToNetwork() {
    // Cancel any previous subscription to avoid duplicate listeners.
    _networkSub?.cancel();

    _networkSub = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        // We consider "online" as anything that is NOT `none`.
        final isOnline = result != ConnectivityResult.none;

        if (isOnline && _wasOffline) {
          // ──────────────────────────────────────────────────────────
          //  TRANSITION: none → wifi / mobile / ethernet
          //  This is the exact moment Lusaka's MTN comes back.
          //  Drain the queue immediately.
          // ──────────────────────────────────────────────────────────
          _statusController.add('reconnected — draining queue');
          processQueue();
        }

        _wasOffline = !isOnline;
      },
    );
  }

  // =====================================================================
  //  PRIVATE HELPERS
  // =====================================================================

  /// Attempts a single HTTP POST for the given [action].
  ///
  /// Returns a [_PostResult] so the caller can decide how to update the
  /// row in SQLite.
  Future<_PostResult> _attemptPost(OfflineAction action) async {
    try {
      final uri = Uri.parse('$_kBaseUrl${action.endpoint}');

      // ── THE KEY LINE: Idempotency injection ─────────────────────────
      // The Gateway reads this header to de-duplicate requests.  Even if
      // the phone retransmits (e.g. after a timeout), the server will
      // recognise the key and return the original response — no double
      // charge, no duplicate gift.
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Idempotency-Key': action.idempotencyKey,
        // TODO: inject auth token from secure storage once auth flow is wired
        // 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(uri, headers: headers, body: action.payload)
          .timeout(_kRequestTimeout);

      // ── Classify the response ─────────────────────────────────────
      final code = response.statusCode;

      if (code == 200 || code == 201 || code == 202) {
        // Server accepted the action.
        return _PostResult.success;
      } else if (code >= 400 && code < 500) {
        // Client-side error — will never succeed on retry.
        return _PostResult.clientError;
      } else {
        // 5xx or any unexpected code — treat as transient.
        return _PostResult.serverOrNetworkError;
      }
    } on SocketException {
      // No internet — classic MTN dropout.
      return _PostResult.serverOrNetworkError;
    } on TimeoutException {
      // Server didn't respond within _kRequestTimeout.
      return _PostResult.serverOrNetworkError;
    } on http.ClientException {
      // Connection reset, broken pipe, etc.
      return _PostResult.serverOrNetworkError;
    } catch (_) {
      // Unknown error — safe default is to retry.
      return _PostResult.serverOrNetworkError;
    }
  }

  /// Exponential back-off: `2^retryCount` seconds, capped at 5 minutes.
  ///
  /// Retry 1 → 2 s,  2 → 4 s,  3 → 8 s,  …  8 → 256 s (capped → 300 s).
  Duration _exponentialBackoff(int retryCount) {
    final seconds = min(pow(2, retryCount).toInt(), 300);
    return Duration(seconds: seconds);
  }

  // =====================================================================
  //  LIFECYCLE
  // =====================================================================

  /// Cancels the network subscription.  Call on app disposal.
  void dispose() {
    _networkSub?.cancel();
    _statusController.close();
  }
}

// ---------------------------------------------------------------------------
// INTERNAL ENUM
// ---------------------------------------------------------------------------

/// Classifies an HTTP response so [processQueue] can decide what to do
/// with the SQLite row.
enum _PostResult {
  /// 200 / 201 / 202 — server confirmed receipt.
  success,

  /// 400 / 401 / 403 — permanent client error, stop retrying.
  clientError,

  /// 500+ / SocketException / Timeout — transient, worth retrying.
  serverOrNetworkError,
}
