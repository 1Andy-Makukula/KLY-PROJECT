/// =============================================================================
/// KithLy Global Protocol - APPROVAL QUEUE (Phase IV-Extension)
/// approval_queue.dart - Pending Shop Approvals
/// =============================================================================
/// 
/// Lists shops with admin_approval_status = 'pending'.
/// Shows NRC photo, satellite location, approve/reject actions.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/alpha_theme.dart';
import '../../services/api_service.dart';

/// Pending shop model
class PendingShop {
  final String shopId;
  final String name;
  final String ownerName;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? nrcIdUrl;
  final String? shopfrontPhotoUrl;
  final String? tpin;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  
  PendingShop({
    required this.shopId,
    required this.name,
    required this.ownerName,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.nrcIdUrl,
    this.shopfrontPhotoUrl,
    this.tpin,
    this.email,
    this.phone,
    required this.createdAt,
  });
  
  factory PendingShop.fromJson(Map<String, dynamic> json) {
    return PendingShop(
      shopId: json['shop_id'] ?? '',
      name: json['name'] ?? 'Unknown Shop',
      ownerName: json['owner_name'] ?? 'Unknown',
      address: json['address'] ?? '',
      city: json['city'] ?? 'Lusaka',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      nrcIdUrl: json['nrc_id_url'],
      shopfrontPhotoUrl: json['shopfront_photo_url'],
      tpin: json['tpin'],
      email: json['email'],
      phone: json['phone_number'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Approval Queue showing pending shop applications
class ApprovalQueue extends StatefulWidget {
  const ApprovalQueue({super.key});
  
  @override
  State<ApprovalQueue> createState() => _ApprovalQueueState();
}

class _ApprovalQueueState extends State<ApprovalQueue> {
  List<PendingShop> _pendingShops = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadPendingShops();
  }
  
  Future<void> _loadPendingShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await ApiService.getPendingShops();
      _pendingShops = data.map((json) => PendingShop.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      // Use mock data for development
      _pendingShops = _getMockShops();
    }
    
    setState(() => _isLoading = false);
  }
  
  List<PendingShop> _getMockShops() {
    return [
      PendingShop(
        shopId: 'mock-shop-1',
        name: 'Manda Hill Flowers',
        ownerName: 'Grace Mwanza',
        address: 'Manda Hill Mall, Shop 42',
        city: 'Lusaka',
        latitude: -15.3892,
        longitude: 28.3228,
        tpin: '1234567890',
        email: 'grace@mandaflowers.com',
        phone: '+260977123456',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      PendingShop(
        shopId: 'mock-shop-2',
        name: 'Cairo Road Gifts',
        ownerName: 'John Banda',
        address: '123 Cairo Road',
        city: 'Lusaka',
        latitude: -15.4167,
        longitude: 28.2833,
        tpin: '0987654321',
        email: 'john@cairogifts.com',
        phone: '+260955987654',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
  
  Future<void> _approveShop(PendingShop shop) async {
    final confirmed = await _showConfirmDialog(
      'Approve ${shop.name}?',
      'This will activate the shop and allow them to receive orders.',
      isApprove: true,
    );
    
    if (confirmed != true) return;
    
    try {
      await ApiService.approveShop(shop.shopId);
      _showSnackbar('${shop.name} approved!', isSuccess: true);
      _loadPendingShops();
    } catch (e) {
      _showSnackbar('Failed to approve: $e', isSuccess: false);
    }
  }
  
  Future<void> _rejectShop(PendingShop shop) async {
    final reason = await _showRejectDialog(shop.name);
    
    if (reason == null) return;
    
    try {
      await ApiService.rejectShop(shop.shopId, reason: reason);
      _showSnackbar('${shop.name} rejected', isSuccess: true);
      _loadPendingShops();
    } catch (e) {
      _showSnackbar('Failed to reject: $e', isSuccess: false);
    }
  }
  
  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? AlphaTheme.accentGreen : AlphaTheme.accentRed,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AlphaTheme.backgroundCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AlphaTheme.accentBlue),
        ),
      );
    }
    
    if (_error != null && _pendingShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AlphaTheme.accentRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load shops',
              style: AlphaTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPendingShops,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_pendingShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AlphaTheme.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AlphaTheme.accentGreen,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: AlphaTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'No pending shop approvals',
              style: TextStyle(color: AlphaTheme.textMuted),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPendingShops,
      color: AlphaTheme.accentBlue,
      backgroundColor: AlphaTheme.backgroundCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingShops.length,
        itemBuilder: (context, index) => _ShopApprovalCard(
          shop: _pendingShops[index],
          onApprove: () => _approveShop(_pendingShops[index]),
          onReject: () => _rejectShop(_pendingShops[index]),
        ),
      ),
    );
  }
  
  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isApprove = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlphaTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: AlphaTheme.cardRadius),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: AlphaTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isApprove ? AlphaTheme.successButton : AlphaTheme.dangerButton,
            child: Text(isApprove ? 'Approve' : 'Confirm'),
          ),
        ],
      ),
    );
  }
  
  Future<String?> _showRejectDialog(String shopName) {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlphaTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: AlphaTheme.cardRadius),
        title: Text(
          'Reject $shopName?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: AlphaTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid NRC, Missing TPIN...',
                hintStyle: TextStyle(color: AlphaTheme.textMuted),
                filled: true,
                fillColor: AlphaTheme.backgroundGlass,
                border: OutlineInputBorder(
                  borderRadius: AlphaTheme.buttonRadius,
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              }
            },
            style: AlphaTheme.dangerButton,
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

/// Shop approval card
class _ShopApprovalCard extends StatelessWidget {
  final PendingShop shop;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  
  const _ShopApprovalCard({
    required this.shop,
    required this.onApprove,
    required this.onReject,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AlphaTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Shop Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentBlue.withOpacity(0.1),
                    borderRadius: AlphaTheme.buttonRadius,
                  ),
                  child: shop.shopfrontPhotoUrl != null
                      ? ClipRRect(
                          borderRadius: AlphaTheme.buttonRadius,
                          child: CachedNetworkImage(
                            imageUrl: shop.shopfrontPhotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(
                              Icons.store,
                              color: AlphaTheme.accentBlue,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.store,
                              color: AlphaTheme.accentBlue,
                            ),
                          ),
                        )
                      : const Icon(Icons.store, color: AlphaTheme.accentBlue),
                ),
                const SizedBox(width: 16),
                
                // Shop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${shop.ownerName}',
                        style: AlphaTheme.captionText,
                      ),
                      Text(
                        shop.address,
                        style: AlphaTheme.captionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentAmber.withOpacity(0.2),
                    borderRadius: AlphaTheme.chipRadius,
                  ),
                  child: Text(
                    _getTimeAgo(shop.createdAt),
                    style: const TextStyle(
                      color: AlphaTheme.accentAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          
          // Details Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Location preview
                Expanded(
                  child: _buildDetailChip(
                    Icons.location_on,
                    '${shop.city}${shop.latitude != null ? ' (GPS ✓)' : ''}',
                  ),
                ),
                const SizedBox(width: 8),
                // TPIN
                Expanded(
                  child: _buildDetailChip(
                    Icons.badge,
                    shop.tpin != null ? 'TPIN: ${shop.tpin!.substring(0, 4)}...' : 'No TPIN',
                  ),
                ),
                const SizedBox(width: 8),
                // NRC
                Expanded(
                  child: _buildDetailChip(
                    Icons.credit_card,
                    shop.nrcIdUrl != null ? 'NRC ✓' : 'No NRC',
                    isError: shop.nrcIdUrl == null,
                  ),
                ),
              ],
            ),
          ),
          
          // Satellite Map Preview (if coordinates available)
          if (shop.latitude != null && shop.longitude != null)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundGlass,
                borderRadius: AlphaTheme.buttonRadius,
              ),
              child: ClipRRect(
                borderRadius: AlphaTheme.buttonRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _getStaticMapUrl(shop.latitude!, shop.longitude!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.map_outlined,
                          color: AlphaTheme.textMuted,
                          size: 32,
                        ),
                      ),
                    ),
                    // Location marker overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AlphaTheme.accentRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AlphaTheme.accentRed.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // NRC Preview (if available)
          if (shop.nrcIdUrl != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showNrcPreview(context, shop.nrcIdUrl!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AlphaTheme.backgroundGlass,
                    borderRadius: AlphaTheme.buttonRadius,
                    border: Border.all(
                      color: AlphaTheme.accentBlue.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, color: AlphaTheme.accentBlue),
                      SizedBox(width: 8),
                      Text(
                        'View NRC Document',
                        style: TextStyle(color: AlphaTheme.accentBlue),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.open_in_new, color: AlphaTheme.accentBlue, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AlphaTheme.accentRed,
                      side: const BorderSide(color: AlphaTheme.accentRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AlphaTheme.buttonRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: AlphaTheme.successButton,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailChip(IconData icon, String label, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isError
            ? AlphaTheme.accentRed.withOpacity(0.1)
            : AlphaTheme.backgroundGlass,
        borderRadius: AlphaTheme.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isError ? AlphaTheme.accentRed : AlphaTheme.textMuted,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isError ? AlphaTheme.accentRed : AlphaTheme.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
  
  String _getStaticMapUrl(double lat, double lng) {
    // Using OpenStreetMap static tiles (free, no API key)
    // Zoom level 15, 400x200 pixels
    return 'https://tile.openstreetmap.org/15/'
        '${((lng + 180) / 360 * 32768).floor()}/'
        '${((1 - (1 / 3.141592653589793 * (0.5 * (1 + (lat * 3.141592653589793 / 180).sin()) / (1 - (lat * 3.141592653589793 / 180).sin())).log())) / 2 * 32768).floor()}.png';
  }
  
  void _showNrcPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AlphaTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: AlphaTheme.cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('NRC Document'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: AlphaTheme.accentRed,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
