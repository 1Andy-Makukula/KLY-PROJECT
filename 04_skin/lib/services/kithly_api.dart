/// =============================================================================
/// KithLy Global Protocol - OFFLINE-FIRST API SERVICE (Phase IV)
/// kithly_api.dart - API Bridge with SQLite Queue Integration
/// =============================================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'sync_db.dart';
import 'sync_manager.dart';

/// Upload result with ZRA status
class UploadResult {
  final bool success;
  final bool isQueued;
  final String? zraStatus;
  final String message;
  final Map<String, dynamic>? data;
  
  UploadResult({
    required this.success,
    this.isQueued = false,
    this.zraStatus,
    required this.message,
    this.data,
  });
  
  bool get isSyncingWithZra => zraStatus == 'RETRY_QUEUED';
}

/// KithLy API Service with offline-first support
class KithlyApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  String? _accessToken;
  final SyncManager _syncManager = SyncManager.instance;
  final SyncDatabase _syncDb = SyncDatabase.instance;
  
  // === Initialization ===
  
  Future<void> init() async {
    await _syncManager.init();
  }
  
  void dispose() {
    _syncManager.dispose();
  }
  
  // === Authentication ===
  
  void setToken(String token) => _accessToken = token;
  void clearToken() => _accessToken = null;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
  
  // === Core Request Methods ===
  
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: _headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: _headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: _headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: _headers);
        break;
      default:
        throw Exception('Unsupported method: $method');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
  
  // === Upload Proof (Offline-First) ===
  
  /// Upload delivery proof with offline queue support
  Future<UploadResult> uploadProof({
    required String txId,
    required String expectedSku,
    required File imageFile,
  }) async {
    // Step 1: Save image to local app directory
    final localPath = await _saveImageLocally(txId, imageFile);
    
    // Step 2: Create payload
    final payload = {
      'tx_id': txId,
      'expected_sku': expectedSku,
    };
    
    // Step 3: Try immediate upload
    try {
      final result = await _uploadToGateway(txId, expectedSku, localPath);
      
      // Handle ZRA RETRY_QUEUED
      if (result['zra_status'] == 'RETRY_QUEUED') {
        // Queue for background sync
        await _syncManager.enqueue(
          endpoint: '/gifts/$txId/upload-proof?expected_sku=$expectedSku',
          payload: payload,
          imagePath: localPath,
        );
        
        return UploadResult(
          success: true,
          isQueued: true,
          zraStatus: 'RETRY_QUEUED',
          message: 'Syncing with ZRA...',
          data: result,
        );
      }
      
      // Success - clean up local file
      await File(localPath).delete();
      
      return UploadResult(
        success: true,
        zraStatus: result['zra_status'],
        message: result['message'] ?? 'Upload successful',
        data: result,
      );
      
    } on SocketException {
      // Network error - queue for later
      return await _queueForSync(txId, expectedSku, payload, localPath);
      
    } on TimeoutException {
      // Timeout - queue for later
      return await _queueForSync(txId, expectedSku, payload, localPath);
      
    } catch (e) {
      // Other error - queue for later
      return await _queueForSync(txId, expectedSku, payload, localPath);
    }
  }
  
  /// Save image to local storage
  Future<String> _saveImageLocally(String txId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final proofDir = Directory('${appDir.path}/pending_proofs');
    
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final localPath = '${proofDir.path}/${txId}_$timestamp.jpg';
    
    await imageFile.copy(localPath);
    return localPath;
  }
  
  /// Upload to Python Gateway
  Future<Map<String, dynamic>> _uploadToGateway(
    String txId,
    String expectedSku,
    String imagePath,
  ) async {
    final uri = Uri.parse('$baseUrl/gifts/$txId/upload-proof?expected_sku=$expectedSku');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
  
  /// Queue upload for background sync
  Future<UploadResult> _queueForSync(
    String txId,
    String expectedSku,
    Map<String, dynamic> payload,
    String localPath,
  ) async {
    await _syncManager.enqueue(
      endpoint: '/gifts/$txId/upload-proof?expected_sku=$expectedSku',
      payload: payload,
      imagePath: localPath,
    );
    
    return UploadResult(
      success: true,
      isQueued: true,
      message: 'Queued for sync when online',
    );
  }
  
  // === Gift API Methods ===
  
  Future<Map<String, dynamic>> createGift({
    required String receiverPhone,
    required String receiverName,
    required String shopId,
    required String productId,
    int quantity = 1,
    String? message,
  }) async {
    return _request('POST', '/gifts/', body: {
      'receiver_phone': receiverPhone,
      'receiver_name': receiverName,
      'shop_id': shopId,
      'product_id': productId,
      'quantity': quantity,
      'message': message,
    });
  }
  
  Future<Map<String, dynamic>> getGift(String txId) async {
    return _request('GET', '/gifts/$txId');
  }
  
  Future<List<dynamic>> listGifts({String role = 'sender'}) async {
    final result = await _request('GET', '/gifts/?role=$role');
    return result['items'] ?? [];
  }
  
  // === Sync Status ===
  
  Stream<SyncStatus> get syncStatusStream => _syncManager.statusStream;
  Stream<int> get queueCountStream => _syncManager.queueStream;
  SyncStatus get currentSyncStatus => _syncManager.currentStatus;
}
