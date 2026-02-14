import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/alpha_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/alpha_buttons.dart';

class ShopScannerView extends StatefulWidget {
  final void Function(String) onScan;
  final VoidCallback onCancel;

  const ShopScannerView({
    super.key,
    required this.onScan,
    required this.onCancel,
  });

  @override
  State<ShopScannerView> createState() => _ShopScannerViewState();
}

class _ShopScannerViewState extends State<ShopScannerView> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanning = false);
        widget.onScan(barcode.rawValue!);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(controller: controller, onDetect: _handleBarcode),

          // Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 50,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: widget.onCancel,
                        ),
                      ),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        borderRadius: 20,
                        child: Text(
                          'Scan Rider QR',
                          style: AlphaTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                const Spacer(),

                // Center Guide (Visual only)
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AlphaTheme.orange, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AlphaTheme.orange.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Corners
                        _buildCorner(Alignment.topLeft),
                        _buildCorner(Alignment.topRight),
                        _buildCorner(Alignment.bottomLeft),
                        _buildCorner(Alignment.bottomRight),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Instructions
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Align Rider\'s QR Code',
                          style: AlphaTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan the code to hand over the package and complete status 420.',
                          style: AlphaTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AlphaGlassButton(
                          text: 'Enter Code Manually',
                          onPressed: () {
                            // TODO: Implement manual entry
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y == -1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: alignment.y == 1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: alignment.x == -1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: alignment.x == 1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
