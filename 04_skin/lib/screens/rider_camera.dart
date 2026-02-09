/// =============================================================================
/// KithLy Global Protocol - RIDER CAMERA (Phase IV)
/// rider_camera.dart - High-Resolution Capture with Receipt Guide Overlay
/// =============================================================================
library;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Rider camera screen with ZRA receipt guide overlay
class RiderCameraScreen extends StatefulWidget {
  final String txId;
  final String expectedSku;
  final Function(XFile photo) onCaptured;
  
  const RiderCameraScreen({
    super.key,
    required this.txId,
    required this.expectedSku,
    required this.onCaptured,
  });
  
  @override
  State<RiderCameraScreen> createState() => _RiderCameraScreenState();
}

class _RiderCameraScreenState extends State<RiderCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isCapturing = false;
  
  @override
  void initState() {
    super.initState();
    _initCamera();
  }
  
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high, // High resolution for OCR
        enableAudio: false,
      );
      
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isReady) return;
    
    setState(() => _isCapturing = true);
    
    try {
      final photo = await _controller!.takePicture();
      widget.onCaptured(photo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    } finally {
      setState(() => _isCapturing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Capture Delivery Proof'),
        actions: [
          // ZRA Guide toggle
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showGuide,
          ),
        ],
      ),
      body: _isReady
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreview(_controller!),
                
                // Receipt Guide Overlay
                const ReceiptGuideOverlay(),
                
                // Bottom Controls
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: _buildControls(),
                ),
                
                // Status Bar
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _buildStatusBar(),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildControls() {
    return Column(
      children: [
        // Instructions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Align ZRA receipt TPIN within the guide box',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        
        // Capture Button
        GestureDetector(
          onTap: _capturePhoto,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCapturing ? Colors.grey : Colors.white,
              ),
              child: _isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt, size: 32, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Order: ${widget.txId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.expectedSku,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📸 Photo Guide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Position the ZRA receipt clearly'),
            SizedBox(height: 8),
            Text('2. Align the TPIN (10 digits) in the guide box'),
            SizedBox(height: 8),
            Text('3. Ensure good lighting'),
            SizedBox(height: 8),
            Text('4. Include the delivery item if possible'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}

/// Receipt Guide Overlay for ZRA TPIN alignment
class ReceiptGuideOverlay extends StatelessWidget {
  const ReceiptGuideOverlay({super.key});
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReceiptGuidePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ReceiptGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Guide box for receipt (center-top area)
    final boxWidth = size.width * 0.85;
    final boxHeight = size.height * 0.35;
    final left = (size.width - boxWidth) / 2;
    final top = size.height * 0.15;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);
    
    // Corner brackets (visual guides)
    final cornerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    const cornerSize = 30.0;
    
    // Top-left
    canvas.drawLine(Offset(left, top + cornerSize), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerSize, top), cornerPaint);
    
    // Top-right
    canvas.drawLine(Offset(left + boxWidth - cornerSize, top), Offset(left + boxWidth, top), cornerPaint);
    canvas.drawLine(Offset(left + boxWidth, top), Offset(left + boxWidth, top + cornerSize), cornerPaint);
    
    // Bottom-left
    canvas.drawLine(Offset(left, top + boxHeight - cornerSize), Offset(left, top + boxHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + boxHeight), Offset(left + cornerSize, top + boxHeight), cornerPaint);
    
    // Bottom-right
    canvas.drawLine(Offset(left + boxWidth - cornerSize, top + boxHeight), Offset(left + boxWidth, top + boxHeight), cornerPaint);
    canvas.drawLine(Offset(left + boxWidth, top + boxHeight - cornerSize), Offset(left + boxWidth, top + boxHeight), cornerPaint);
    
    // TPIN Label area
    final tpinLabelRect = Rect.fromLTWH(
      left + 20,
      top + boxHeight * 0.3,
      boxWidth - 40,
      40,
    );
    
    final tpinPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(tpinLabelRect, tpinPaint);
    
    final tpinBorderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(tpinLabelRect, tpinBorderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ZRA Tax Verified Badge Widget
class ZRAVerifiedBadge extends StatelessWidget {
  final String? resultCode;
  
  const ZRAVerifiedBadge({super.key, this.resultCode});
  
  bool get isVerified => resultCode == '000' || resultCode == '001';
  
  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'TAX VERIFIED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
