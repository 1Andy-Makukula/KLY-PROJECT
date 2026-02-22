/// =============================================================================
/// KithLy Global Protocol - PIPELINE 1: LOCAL-FIRST STORAGE ENGINE
/// local_database_helper.dart - Offline Action Queue (The Mobile Shock Absorber)
/// =============================================================================
///
/// In low-connectivity environments (e.g. Lusaka during MTN outages), every
/// user action that needs to reach the backend is first persisted in a LOCAL
/// SQLite queue.  When connectivity returns, the [SyncManager] drains this
/// queue in FIFO order, exactly like a Redis list on the server side.
///
/// KEY DESIGN DECISIONS:
///   • Singleton — only one write-lock on the SQLite file at a time.
///   • idempotency_key (UUID) — the server uses this to de-duplicate actions
///     even if the phone retransmits after a timeout.
///   • status enum (pending → syncing → completed / failed) — lets the sync
///     engine distinguish "never tried" from "tried and failed" so it can
///     apply exponential back-off without re-sending completed work.
///   • retry_count — caps retries and drives back-off intervals.
/// =============================================================================
library;

import 'dart:convert';
import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// CONSTANTS
// ---------------------------------------------------------------------------

/// Bump this when you ALTER the schema to trigger [onUpgrade].
const int _kDbVersion = 1;

/// Separate DB file from sync_db.dart to avoid migration conflicts.
const String _kDbName = 'kithly_offline_queue.db';

/// The four lifecycle states an offline action passes through.
///
/// ```
///  ┌─────────┐   SyncManager picks it up    ┌─────────┐
///  │ pending │ ──────────────────────────▶   │ syncing │
///  └─────────┘                               └────┬────┘
///                                                  │
///                              ┌───────────────────┼───────────────────┐
///                              ▼                                       ▼
///                        ┌───────────┐                          ┌───────────┐
///                        │ completed │                          │  failed   │
///                        └───────────┘                          └───────────┘
/// ```
abstract class ActionStatus {
  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String failed = 'failed';
  static const String completed = 'completed';
}

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

/// A single queued action that the phone wants to send to the gateway.
class OfflineAction {
  final int? id;
  final String idempotencyKey;
  final String endpoint;
  final String payload; // JSON-encoded body
  final String status;
  final int retryCount;
  final String createdAt; // ISO 8601

  OfflineAction({
    this.id,
    required this.idempotencyKey,
    required this.endpoint,
    required this.payload,
    this.status = ActionStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
  });

  /// Deserialise a SQLite row into an [OfflineAction].
  factory OfflineAction.fromMap(Map<String, dynamic> map) => OfflineAction(
        id: map['id'] as int?,
        idempotencyKey: map['idempotency_key'] as String,
        endpoint: map['endpoint'] as String,
        payload: map['payload'] as String,
        status: (map['status'] as String?) ?? ActionStatus.pending,
        retryCount: (map['retry_count'] as int?) ?? 0,
        createdAt: map['created_at'] as String,
      );

  /// Serialise to a map suitable for `db.insert()`.
  Map<String, dynamic> toMap() => {
        // `id` is omitted — SQLite auto-generates it on INSERT.
        'idempotency_key': idempotencyKey,
        'endpoint': endpoint,
        'payload': payload,
        'status': status,
        'retry_count': retryCount,
        'created_at': createdAt,
      };
}

// ---------------------------------------------------------------------------
// SINGLETON DATABASE HELPER
// ---------------------------------------------------------------------------

/// Manages the `offline_action_queue` table — the phone's local write-ahead
/// log for every action destined for the KithLy Gateway.
///
/// Usage:
/// ```dart
/// final db = LocalDatabaseHelper.instance;
/// await db.initDB();
///
/// await db.enqueueAction(
///   endpoint: '/api/gifts',
///   payload: {'receiver_phone': '+260977...', ...},
///   idempotencyKey: uuid.v4(),
/// );
///
/// final pending = await db.getPendingActions();
/// ```
class LocalDatabaseHelper {
  // ── Singleton boilerplate ──────────────────────────────────────────────
  // Guarantees a single write-lock on the SQLite file across the entire app.
  static final LocalDatabaseHelper _instance = LocalDatabaseHelper._internal();
  static Database? _database;

  /// Private constructor — prevents external instantiation.
  LocalDatabaseHelper._internal();

  /// The single, app-wide instance.
  static LocalDatabaseHelper get instance => _instance;

  // ── Database accessor ──────────────────────────────────────────────────

  /// Returns the open database, initialising it lazily on first access.
  Future<Database> get database async {
    _database ??= await initDB();
    return _database!;
  }

  // -----------------------------------------------------------------------
  // 1. initDB() — Create / open the SQLite database
  // -----------------------------------------------------------------------

  /// Opens (or creates) the local SQLite database and ensures the
  /// `offline_action_queue` table + indices exist.
  ///
  /// Safe to call multiple times — the Singleton ensures only one DB handle.
  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_kDbName';

    return openDatabase(
      path,
      version: _kDbVersion,
      onCreate: (Database db, int version) async {
        // -- The core queue table ----------------------------------------
        await db.execute('''
          CREATE TABLE offline_action_queue (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            idempotency_key  TEXT    UNIQUE NOT NULL,
            endpoint         TEXT    NOT NULL,
            payload          TEXT    NOT NULL,
            status           TEXT    NOT NULL DEFAULT 'pending',
            retry_count      INTEGER NOT NULL DEFAULT 0,
            created_at       TEXT    NOT NULL
          )
        ''');

        // -- Indices for the SyncManager's hot queries --------------------
        // The sync loop always asks: "give me rows that are pending or failed,
        // oldest first."  These two indices keep that query O(log n).
        await db.execute('''
          CREATE INDEX idx_oaq_status ON offline_action_queue(status)
        ''');
        await db.execute('''
          CREATE INDEX idx_oaq_created ON offline_action_queue(created_at ASC)
        ''');

        // Unique constraint on idempotency_key is declared inline above
        // (TEXT UNIQUE).  If the phone accidentally enqueues the same action
        // twice, SQLite will reject the duplicate INSERT — no double-charge.
      },
    );
  }

  // -----------------------------------------------------------------------
  // 2. enqueueAction() — The "front door" for every offline write
  // -----------------------------------------------------------------------

  /// Serialises [payload] to JSON and inserts a new row with status='pending'.
  ///
  /// Returns the auto-generated row `id`.
  ///
  /// Throws if a row with the same [idempotencyKey] already exists —
  /// this is intentional: the UNIQUE constraint prevents double-enqueue.
  Future<int> enqueueAction({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final db = await database;

    final action = OfflineAction(
      idempotencyKey: idempotencyKey,
      endpoint: endpoint,
      payload: jsonEncode(payload),
      status: ActionStatus.pending,
      retryCount: 0,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // INSERT OR ABORT — the UNIQUE(idempotency_key) constraint acts
    // as an automatic de-duplication guard on the client side.
    return db.insert(
      'offline_action_queue',
      action.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // -----------------------------------------------------------------------
  // 3. getPendingActions() — Feed the SyncManager's drain loop
  // -----------------------------------------------------------------------

  /// Returns all actions that are either 'pending' (never tried) or 'failed'
  /// (tried but the server was unreachable).  Ordered oldest-first (FIFO)
  /// so the user's earliest action lands on the server first.
  Future<List<OfflineAction>> getPendingActions() async {
    final db = await database;

    final rows = await db.query(
      'offline_action_queue',
      where: 'status IN (?, ?)',
      whereArgs: [ActionStatus.pending, ActionStatus.failed],
      orderBy: 'created_at ASC',
    );

    return rows.map(OfflineAction.fromMap).toList();
  }

  // -----------------------------------------------------------------------
  // 4. updateActionStatus() — Generic status transition
  // -----------------------------------------------------------------------

  /// Moves a row to a new lifecycle state.
  ///
  /// Example: `updateActionStatus(42, ActionStatus.syncing)` when the
  /// SyncManager picks the action up, or `ActionStatus.completed` when
  /// the server responds with 202 Accepted.
  Future<int> updateActionStatus(int id, String newStatus) async {
    final db = await database;

    return db.update(
      'offline_action_queue',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -----------------------------------------------------------------------
  // 5. incrementRetry() — Exponential back-off bookkeeping
  // -----------------------------------------------------------------------

  /// Bumps `retry_count` by 1 and sets status back to 'failed' so the
  /// action re-enters the drain loop on the next cycle.
  ///
  /// The SyncManager should read `retry_count` and apply an exponential
  /// delay: `delay = min(2^retryCount, 300)` seconds.
  Future<int> incrementRetry(int id) async {
    final db = await database;

    // Raw SQL for an atomic read-modify-write — avoids a race between
    // two concurrent sync attempts touching the same row.
    return db.rawUpdate('''
      UPDATE offline_action_queue
         SET retry_count = retry_count + 1,
             status      = ?
       WHERE id = ?
    ''', [ActionStatus.failed, id]);
  }

  // -----------------------------------------------------------------------
  // 6. removeCompletedAction() — Garbage-collect confirmed work
  // -----------------------------------------------------------------------

  /// Hard-deletes the row once the server has acknowledged receipt.
  ///
  /// We DELETE rather than soft-delete to keep the SQLite file small on
  /// low-storage devices.  If an audit trail is needed, the server's
  /// PostgreSQL database is the system of record.
  Future<int> removeCompletedAction(int id) async {
    final db = await database;

    return db.delete(
      'offline_action_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -----------------------------------------------------------------------
  // UTILITIES
  // -----------------------------------------------------------------------

  /// Returns the total number of actions still waiting to sync.
  /// Useful for showing a badge count in the UI ("3 actions pending").
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt
        FROM offline_action_queue
       WHERE status IN (?, ?)
    ''', [ActionStatus.pending, ActionStatus.failed]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Closes the database connection.  Call this on app disposal.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
