/// =============================================================================
/// KithLy Global Protocol - BULLETPROOF SYNC MANAGER (Phase IV)
/// sync_manager.dart - Stage-Attempt-Confirm Pattern
/// =============================================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'sync_db.dart';

/// Sync status for UI display
enum SyncStatus {
  idle,
  syncing,
  syncingZra,
  offline,
  error,
}

/// Bulletproof Sync Manager with Stage-Attempt-Confirm pattern
class SyncManager {
  static SyncManager? _instance;

  final SyncDatabase _db = SyncDatabase.instance;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;
  Timer? _heartbeatTimer;

  // Status stream for UI
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;

  // Queue count stream
  final _queueController = StreamController<int>.broadcast();
  Stream<int> get queueStream => _queueController.stream;

  static const String baseUrl = 'http://localhost:8000';
  static const int maxRetries = 5;

  SyncManager._();

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  SyncStatus get currentStatus => _currentStatus;

  /// Initialize and start heartbeat
  Future<void> init() async {
    await _updateQueueCount();
    monitorConnectivity();
    _startHeartbeat();
  }

  /// The Heartbeat: Listen for internet returning
  void monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          _setStatus(SyncStatus.syncing);
          processQueue();
        } else {
          _setStatus(SyncStatus.offline);
        }
      },
    );
  }

  /// Periodic heartbeat check
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => processQueue(),
    );
  }

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> _updateQueueCount() async {
    final count = await _db.getQueueLength();
    _queueController.add(count);
  }

  /// Process the queue with Stage-Attempt-Confirm pattern
  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      // Fetch all pending uploads from the local "Black Box"
      final pending = await _db.getPendingUploads();

      for (var item in pending) {
        // STAGE: Mark as syncing
        await _db.markAsSyncing(item.id!);

        // ATTEMPT: Try upload
        final success = await _attemptUpload(item);

        if (success) {
          // CONFIRM: Only delete if Gateway confirms receipt
          await _db.deleteUpload(item.id!);

          // Clean up local image
          if (item.imagePath != null) {
            final file = File(item.imagePath!);
            if (await file.exists()) {
              await file.delete();
            }
          }
        } else {
          // Exponential Backoff
          final newRetryCount = item.retryCount + 1;

          if (newRetryCount >= maxRetries) {
            await _db.markAsFailed(item.id!);
          } else {
            final delay = _calculateBackoff(newRetryCount);
            final nextRetry = DateTime.now().add(delay);
            await _db.markForRetry(item.id!, newRetryCount, nextRetry);

            // Wait before trying next item
            await Future.delayed(delay);
          }
        }
      }

      await _updateQueueCount();
      _setStatus(SyncStatus.idle);
    } catch (e) {
      _setStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Calculate exponential backoff: 2^retryCount seconds (capped at 1 hour)
  Duration _calculateBackoff(int retryCount) {
    final seconds = pow(2, retryCount).toInt();
    return Duration(seconds: min(seconds, 3600));
  }

  /// Attempt upload to Python Gateway
  Future<bool> _attemptUpload(PendingUpload item) async {
    try {
      http.Response response;

      if (item.imagePath != null) {
        // Multipart upload for images
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl${item.endpoint}'),
        );
        request.headers['Content-Type'] = 'multipart/form-data';

        final payload = jsonDecode(item.payloadJson);
        payload.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        request.files
            .add(await http.MultipartFile.fromPath('photo', item.imagePath!));

        final streamedResponse = await request.send().timeout(
              const Duration(seconds: 30),
            );
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // JSON request
        response = await http
            .post(
              Uri.parse('$baseUrl${item.endpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: item.payloadJson,
            )
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);

        // Check ZRA status
        if (body['zra_status'] == 'RETRY_QUEUED') {
          _setStatus(SyncStatus.syncingZra);
          return false; // Keep in queue for ZRA retry
        }

        // resultCd 000 = ZRA success
        if (body['zra_result_code'] == '000' ||
            body['zra_result_code'] == '001') {
          return true;
        }

        return response.statusCode == 200;
      }

      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Enqueue a new upload
  Future<int> enqueue({
    required String endpoint,
    required Map<String, dynamic> payload,
    String? imagePath,
  }) async {
    final upload = PendingUpload(
      endpoint: endpoint,
      payloadJson: jsonEncode(payload),
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertUpload(upload);
    await _updateQueueCount();

    // Attempt immediate sync
    processQueue();

    return id;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _statusController.close();
    _queueController.close();
  }
}
