/// =============================================================================
/// KithLy Global Protocol - SYNC STATUS WIDGET (Phase IV)
/// sync_status_widget.dart - UI for Sync Status Display
/// =============================================================================
library;

import 'package:flutter/material.dart';
import '../services/sync_manager.dart';

/// Widget to display sync status with ZRA handling
class SyncStatusWidget extends StatelessWidget {
  final SyncStatus status;
  final int queueCount;
  
  const SyncStatusWidget({
    super.key,
    required this.status,
    this.queueCount = 0,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 8),
          Text(
            _statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (queueCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$queueCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color get _backgroundColor {
    switch (status) {
      case SyncStatus.idle:
        return const Color(0xFF10B981); // Green
      case SyncStatus.syncing:
        return const Color(0xFF3B82F6); // Blue
      case SyncStatus.syncingZra:
        return const Color(0xFFF59E0B); // Amber
      case SyncStatus.offline:
        return const Color(0xFF6B7280); // Gray
      case SyncStatus.error:
        return const Color(0xFFEF4444); // Red
    }
  }
  
  String get _statusText {
    switch (status) {
      case SyncStatus.idle:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.syncingZra:
        return 'Syncing with ZRA...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }
  
  Widget _buildIcon() {
    switch (status) {
      case SyncStatus.idle:
        return const Icon(Icons.cloud_done, color: Colors.white, size: 16);
      case SyncStatus.syncing:
      case SyncStatus.syncingZra:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        );
      case SyncStatus.offline:
        return const Icon(Icons.cloud_off, color: Colors.white, size: 16);
      case SyncStatus.error:
        return const Icon(Icons.error_outline, color: Colors.white, size: 16);
    }
  }
}

/// Stream-based sync status widget
class SyncStatusStreamWidget extends StatelessWidget {
  final SyncManager syncManager;
  
  const SyncStatusStreamWidget({super.key, required this.syncManager});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: syncManager.statusStream,
      initialData: syncManager.currentStatus,
      builder: (context, statusSnapshot) {
        return StreamBuilder<int>(
          stream: syncManager.queueStream,
          initialData: 0,
          builder: (context, queueSnapshot) {
            return SyncStatusWidget(
              status: statusSnapshot.data ?? SyncStatus.idle,
              queueCount: queueSnapshot.data ?? 0,
            );
          },
        );
      },
    );
  }
}
