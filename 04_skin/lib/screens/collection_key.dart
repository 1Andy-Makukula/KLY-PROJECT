/// =============================================================================
/// KithLy Global Protocol - COLLECTION KEY SCREEN (Phase III-V)
/// collection_key.dart - QR Code & 10-Digit Code Display
/// =============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

/// Collection key screen displaying QR code and manual code
class CollectionKeyScreen extends StatefulWidget {
  final String txId;
  final String collectionToken;
  final String qrCodeBase64;
  final String recipientName;
  final String productName;
  final DateTime expiryTimestamp;
  
  const CollectionKeyScreen({
    super.key,
    required this.txId,
    required this.collectionToken,
    required this.qrCodeBase64,
    required this.recipientName,
    required this.productName,
    required this.expiryTimestamp,
  });
  
  @override
  State<CollectionKeyScreen> createState() => _CollectionKeyScreenState();
}

class _CollectionKeyScreenState extends State<CollectionKeyScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _codeCopied = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  String get _shareMessage => '''
🎁 Your KithLy Gift is Ready!

Collection Code: ${widget.collectionToken}
Valid until: ${_formatExpiry(widget.expiryTimestamp)}

Gift: ${widget.productName}
For: ${widget.recipientName}

Show this code to the shop or scan the QR.

Powered by KithLy Global Protocol
https://kithly.com
''';
  
  String _formatExpiry(DateTime dt) {
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Collection Key'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success header
            _buildSuccessHeader(),
            const SizedBox(height: 32),
            
            // QR Code
            _buildQRCode(),
            const SizedBox(height: 24),
            
            // Divider with "OR"
            _buildOrDivider(),
            const SizedBox(height: 24),
            
            // 10-Digit Manual Code
            _buildManualCode(),
            const SizedBox(height: 32),
            
            // Expiry warning
            _buildExpiryWarning(),
            const SizedBox(height: 32),
            
            // Share button
            _buildShareButton(),
            const SizedBox(height: 16),
            
            // Copy button
            _buildCopyButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.2),
                const Color(0xFF10B981).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Payment Confirmed!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share this key with ${widget.recipientName}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQRCode() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code image from base64
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.qrCodeBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(widget.qrCodeBase64),
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.productName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR ENTER CODE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
      ],
    );
  }
  
  Widget _buildManualCode() {
    return GestureDetector(
      onTap: _copyToClipboard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Bold 10-digit code
            Text(
              widget.collectionToken,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _codeCopied ? Icons.check : Icons.copy,
                  color: _codeCopied ? const Color(0xFF10B981) : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _codeCopied ? 'Copied!' : 'Tap to copy',
                  style: TextStyle(
                    color: _codeCopied ? const Color(0xFF10B981) : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpiryWarning() {
    final now = DateTime.now();
    final remaining = widget.expiryTimestamp.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFFF59E0B),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valid for 48 hours',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${hours}h ${minutes}m remaining',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _shareKey,
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text(
          'Share via WhatsApp/SMS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCopyButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _copyToClipboard,
        icon: const Icon(Icons.copy),
        label: const Text('Copy Code'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.collectionToken));
    setState(() => _codeCopied = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Collection code copied!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }
  
  void _shareKey() {
    Share.share(_shareMessage, subject: 'Your KithLy Gift Collection Key');
  }
}
