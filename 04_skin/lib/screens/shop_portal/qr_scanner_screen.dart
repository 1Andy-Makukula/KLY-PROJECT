/// =============================================================================
/// KithLy Global Protocol - QR SCANNER SCREEN (Phase IV-Extension)
/// qr_scanner_screen.dart - Handshake Scanner for Collection Verification
/// =============================================================================
///
/// Full-screen QR scanner for shops to verify collection tokens.
/// Hits /verify-handshake endpoint on successful scan.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../theme/alpha_theme.dart';
import '../../services/api_service.dart';
import '../../state_machine/dashboard_provider.dart';

/// QR Scanner Screen for Collection Handshake
class QRScannerScreen extends StatefulWidget {
  final String shopId;
  final String txId;
  final Function(String message)? onVerified;

  const QRScannerScreen({
    super.key,
    required this.shopId,
    required this.txId,
    this.onVerified,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  final ApiService _api = ApiService();
  bool _isProcessing = false;
  bool _showManualEntry = false;
  bool _showSuccess = false;
  final TextEditingController _manualCodeController = TextEditingController();

  // Token pattern: XXXX-XXXX (Escrow Protocol)
  final RegExp _tokenPattern = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$');

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;

    // Extract token from QR URL or direct code
    String? token;

    if (code.contains('token=')) {
      // Extract from URL: https://kithly.com/collect/{tx_id}?token=KT-XXXX-XX
      final uri = Uri.tryParse(code);
      token = uri?.queryParameters['token'];
    } else if (_tokenPattern.hasMatch(code)) {
      token = code;
    }

    if (token == null || !_tokenPattern.hasMatch(token)) {
      _showError('Invalid QR code. Please scan a KithLy collection code.');
      return;
    }

    await _verifyToken(token);
  }

  Future<void> _verifyToken(String token) async {
    setState(() => _isProcessing = true);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Extract tx_id from token or use token directly
      // For now, we'll send the token and let the backend resolve
      final result = await _api.verifyHandshake(
        txId: widget.txId,
        token: token,
        shopId: widget.shopId,
      );

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();

        // Finalize handover in provider
        if (mounted) {
          final txId = result['tx_id'] as String? ?? '';
          if (txId.isNotEmpty) {
            context.read<DashboardProvider>().finalizeHandover(txId);
          }

          // Show success overlay, then auto-pop after 1.5s
          setState(() => _showSuccess = true);
          _scannerController.stop();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context);
              widget.onVerified?.call(
                result['message'] ?? 'Collection verified! Payment released.',
              );
            }
          });
        }
      } else {
        _showError(result['message'] ?? 'Verification failed');
      }
    } catch (e) {
      _showError('Network error. Please try again.');
    } finally {
      if (mounted && !_showSuccess) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AlphaTheme.accentRed),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay
          _buildScanOverlay(),

          // Top Bar
          _buildTopBar(),

          // Bottom Controls
          _buildBottomControls(),

          // Manual Entry Sheet
          if (_showManualEntry) _buildManualEntrySheet(),

          // Processing Indicator
          if (_isProcessing) _buildProcessingOverlay(),

          // Success Checkmark Overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Scan Collection Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: ValueListenableBuilder<TorchState>(
                valueListenable: _scannerController.torchState,
                builder: (context, state, child) {
                  return Icon(
                    state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  );
                },
              ),
              onPressed: () => _scannerController.toggleTorch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: AlphaTheme.accentGreen,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Corner decorations
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),

            // Scanning line animation
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 20 + (_scanLineAnimation.value * 240),
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AlphaTheme.accentGreen.withOpacity(0.8),
                          AlphaTheme.accentGreen,
                          AlphaTheme.accentGreen.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AlphaTheme.accentGreen.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Positioned(
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight
          ? 0
          : null,
      bottom: alignment == Alignment.bottomLeft ||
              alignment == Alignment.bottomRight
          ? 0
          : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
          ? 0
          : null,
      right:
          alignment == Alignment.topRight || alignment == Alignment.bottomRight
              ? 0
              : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: AlphaTheme.accentGreen, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AlphaTheme.accentGreen, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: AlphaTheme.accentGreen, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AlphaTheme.accentGreen, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Point camera at collection QR code',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showManualEntry = true),
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter Code Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AlphaTheme.buttonRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntrySheet() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showManualEntry = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping sheet
              child: Container(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: AlphaTheme.backgroundCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter Collection Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Format: XXXX-XXXX',
                      style: TextStyle(
                        color: AlphaTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _manualCodeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: AlphaTheme.codeText,
                      decoration: InputDecoration(
                        hintText: '____-____',
                        hintStyle: TextStyle(
                          color: AlphaTheme.textMuted.withOpacity(0.5),
                          fontSize: 24,
                          fontFamily: 'monospace',
                        ),
                        filled: true,
                        fillColor: AlphaTheme.backgroundGlass,
                        border: OutlineInputBorder(
                          borderRadius: AlphaTheme.buttonRadius,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AlphaTheme.buttonRadius,
                          borderSide: const BorderSide(
                            color: AlphaTheme.accentGreen,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final code =
                              _manualCodeController.text.trim().toUpperCase();
                          if (_tokenPattern.hasMatch(code)) {
                            setState(() => _showManualEntry = false);
                            _verifyToken(code);
                          } else {
                            _showError('Invalid format. Use: XXXX-XXXX');
                          }
                        },
                        style: AlphaTheme.successButton,
                        child: const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AlphaTheme.accentGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AlphaTheme.accentGreen,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verifying Collection...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Releasing payment to your account',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AlphaTheme.accentGreen.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AlphaTheme.accentGreen,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Collection Complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Payment released to your account',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
