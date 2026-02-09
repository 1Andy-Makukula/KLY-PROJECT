/// =============================================================================
/// KithLy Global Protocol - SYNC DATABASE (Phase IV)
/// sync_db.dart - SQLite Schema for Offline Queue
/// =============================================================================
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database schema version
const int _dbVersion = 1;
const String _dbName = 'kithly_sync.db';

/// Pending upload record
class PendingUpload {
  final int? id;
  final String endpoint;
  final String payloadJson;
  final String? imagePath;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? nextRetryAt;
  final String status; // PENDING, SYNCING, RETRY_QUEUED, FAILED
  
  PendingUpload({
    this.id,
    required this.endpoint,
    required this.payloadJson,
    this.imagePath,
    this.retryCount = 0,
    required this.createdAt,
    this.nextRetryAt,
    this.status = 'PENDING',
  });
  
  Map<String, dynamic> toMap() => {
    'endpoint': endpoint,
    'payload_json': payloadJson,
    'image_path': imagePath,
    'retry_count': retryCount,
    'created_at': createdAt.toIso8601String(),
    'next_retry_at': nextRetryAt?.toIso8601String(),
    'status': status,
  };
  
  factory PendingUpload.fromMap(Map<String, dynamic> map) => PendingUpload(
    id: map['id'],
    endpoint: map['endpoint'],
    payloadJson: map['payload_json'],
    imagePath: map['image_path'],
    retryCount: map['retry_count'] ?? 0,
    createdAt: DateTime.parse(map['created_at']),
    nextRetryAt: map['next_retry_at'] != null 
        ? DateTime.parse(map['next_retry_at']) 
        : null,
    status: map['status'] ?? 'PENDING',
  );
  
  PendingUpload copyWith({
    int? retryCount,
    DateTime? nextRetryAt,
    String? status,
  }) => PendingUpload(
    id: id,
    endpoint: endpoint,
    payloadJson: payloadJson,
    imagePath: imagePath,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    status: status ?? this.status,
  );
}

/// Sync database manager
class SyncDatabase {
  static SyncDatabase? _instance;
  static Database? _db;
  
  SyncDatabase._();
  
  static SyncDatabase get instance {
    _instance ??= SyncDatabase._();
    return _instance!;
  }
  
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_uploads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        image_path TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        next_retry_at TEXT,
        status TEXT DEFAULT 'PENDING'
      )
    ''');
    
    await db.execute('''
      CREATE INDEX idx_pending_status ON pending_uploads(status)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_pending_retry ON pending_uploads(next_retry_at)
    ''');
  }
  
  // === CRUD Operations ===
  
  Future<int> insertUpload(PendingUpload upload) async {
    final db = await database;
    return db.insert('pending_uploads', upload.toMap());
  }
  
  Future<List<PendingUpload>> getPendingUploads() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'pending_uploads',
      where: "status IN ('PENDING', 'RETRY_QUEUED') AND (next_retry_at IS NULL OR next_retry_at <= ?)",
      whereArgs: [now],
      orderBy: 'created_at ASC',
      limit: 10,
    );
    
    return maps.map((m) => PendingUpload.fromMap(m)).toList();
  }
  
  Future<int> getQueueLength() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pending_uploads WHERE status IN ('PENDING', 'RETRY_QUEUED')"
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  Future<void> updateUpload(PendingUpload upload) async {
    final db = await database;
    await db.update(
      'pending_uploads',
      upload.toMap(),
      where: 'id = ?',
      whereArgs: [upload.id],
    );
  }
  
  Future<void> deleteUpload(int id) async {
    final db = await database;
    await db.delete('pending_uploads', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> markAsSyncing(int id) async {
    final db = await database;
    await db.update(
      'pending_uploads',
      {'status': 'SYNCING'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> markForRetry(int id, int retryCount, DateTime nextRetry) async {
    final db = await database;
    await db.update(
      'pending_uploads',
      {
        'status': 'RETRY_QUEUED',
        'retry_count': retryCount,
        'next_retry_at': nextRetry.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> markAsFailed(int id) async {
    final db = await database;
    await db.update(
      'pending_uploads',
      {'status': 'FAILED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
