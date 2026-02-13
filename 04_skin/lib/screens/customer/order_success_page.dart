/// =============================================================================
/// KithLy Global Protocol - ORDER SUCCESS PAGE (Phase IV-Extension)
/// order_success_page.dart - Customer Verification & Rerouting HUD
/// =============================================================================
///
/// Shows buyer-side transparency during the 2-minute inventory check.
/// Phases: verifying → confirmed | rerouting_search → rerouted
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/alpha_theme.dart';
import '../../state_machine/gift_provider.dart';

/// Order Success Page with Protocol HUD
class OrderSuccessPage extends StatefulWidget {
  final String txId;

  const OrderSuccessPage({super.key, required this.txId});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  // Scanning pulse animation
  late AnimationController _scanPulseController;
  late Animation<double> _scanPulseAnimation;

  // Radar animation
  late AnimationController _radarController;

  // Confetti animation
  late AnimationController _confettiController;
  bool _confettiFired = false;

  // Track previous phase to detect transitions
  String _previousPhase = 'idle';

  @override
  void initState() {
    super.initState();

    // Scanning pulse: gentle scale 1.0 → 1.05 over 1.5s
    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanPulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scanPulseController, curve: Curves.easeInOut),
    );

    // Radar: continuous rotation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Confetti: one-shot burst
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _scanPulseController.dispose();
    _radarController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePhaseTransition(String newPhase) {
    if (newPhase == 'confirmed' && _previousPhase == 'verifying') {
      // Haptic success + confetti burst
      HapticFeedback.heavyImpact();
      if (!_confettiFired) {
        _confettiFired = true;
        _confettiController.forward();
      }
    }
    _previousPhase = newPhase;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaTheme.backgroundDark,
      body: Consumer<GiftProvider>(
        builder: (context, provider, _) {
          final phase = provider.verificationPhase;
          _handlePhaseTransition(phase);

          return SafeArea(
            child: Stack(
              children: [
                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildPhaseContent(provider, phase),
                  ),
                ),

                // Confetti overlay
                if (_confettiFired) _buildConfettiOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhaseContent(GiftProvider provider, String phase) {
    return switch (phase) {
      'verifying' => _buildVerifyingView(provider),
      'rerouting_search' => _buildReroutingView(),
      'rerouted' => _buildReroutedView(provider),
      'confirmed' => _buildConfirmedView(provider),
      _ => _buildIdleView(provider),
    };
  }

  // ===========================================================================
  // PHASE: IDLE (Normal Thank You)
  // ===========================================================================

  Widget _buildIdleView(GiftProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AlphaTheme.accentGreen.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            color: AlphaTheme.accentGreen,
            size: 64,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Thank You!',
          style: TextStyle(
            color: AlphaTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your gift is being processed.',
          style: TextStyle(
            color: AlphaTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 48),
        _buildGiftSummaryCard(provider),
        const SizedBox(height: 32),
        _buildBackButton(),
      ],
    );
  }

  // ===========================================================================
  // PHASE: VERIFYING (Countdown HUD)
  // ===========================================================================

  Widget _buildVerifyingView(GiftProvider provider) {
    final timer = provider.verificationTimer;
    final minutes = (timer ~/ 60).toString().padLeft(2, '0');
    final seconds = (timer % 60).toString().padLeft(2, '0');
    final progress = timer / 120.0;
    final gift = provider.activeGift;
    final shopName =
        gift?.shopName.isNotEmpty == true ? gift!.shopName : 'the shop';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),

        // Countdown ring + product icon with scan pulse
        ScaleTransition(
          scale: _scanPulseAnimation,
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AlphaTheme.backgroundGlass,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AlphaTheme.accentBlue,
                    ),
                  ),
                ),
                // Inner content
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AlphaTheme.backgroundCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AlphaTheme.accentBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AlphaTheme.accentBlue,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          color: AlphaTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AlphaTheme.accentBlue.withOpacity(0.15),
            borderRadius: AlphaTheme.chipRadius,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AlphaTheme.accentBlue,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Quality Check in Progress',
                style: TextStyle(
                  color: AlphaTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Explanation text
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AlphaTheme.glassCard,
          child: Column(
            children: [
              const Text(
                'Quality Check',
                style: TextStyle(
                  color: AlphaTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re confirming $shopName has your gift in stock to ensure a perfect delivery.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AlphaTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildGiftSummaryCard(provider),
      ],
    );
  }

  // ===========================================================================
  // PHASE: REROUTING SEARCH (Radar animation)
  // ===========================================================================

  Widget _buildReroutingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),

        // Radar animation
        SizedBox(
          width: 200,
          height: 200,
          child: AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(
                  progress: _radarController.value,
                  color: AlphaTheme.accentAmber,
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AlphaTheme.accentAmber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AlphaTheme.accentAmber,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AlphaTheme.accentAmber.withOpacity(0.15),
            borderRadius: AlphaTheme.chipRadius,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AlphaTheme.accentAmber,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Finding Alternative',
                style: TextStyle(
                  color: AlphaTheme.accentAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: AlphaTheme.glassCard,
          child: const Column(
            children: [
              Text(
                'Securing Your Gift',
                style: TextStyle(
                  color: AlphaTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Shop couldn\'t verify in time. KithLy is now securing your gift from a verified alternative nearby…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AlphaTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PHASE: REROUTED (New Shop Found)
  // ===========================================================================

  Widget _buildReroutedView(GiftProvider provider) {
    final newShop = provider.reroutedShopName ?? 'Nearby Partner';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),

        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AlphaTheme.accentGreen.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AlphaTheme.accentGreen.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            color: AlphaTheme.accentGreen,
            size: 64,
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Gift Secured!',
          style: TextStyle(
            color: AlphaTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Now being prepared by $newShop',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AlphaTheme.textSecondary,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 32),

        // Rerouted info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AlphaTheme.glassCard,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AlphaTheme.accentGreen.withOpacity(0.15),
                  borderRadius: AlphaTheme.buttonRadius,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AlphaTheme.accentGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newShop,
                      style: const TextStyle(
                        color: AlphaTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Verified alternative • No extra charge',
                      style: TextStyle(
                        color: AlphaTheme.accentGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildGiftSummaryCard(provider),
        const SizedBox(height: 32),
        _buildBackButton(),
      ],
    );
  }

  // ===========================================================================
  // PHASE: CONFIRMED (Confetti + Success)
  // ===========================================================================

  Widget _buildConfirmedView(GiftProvider provider) {
    final gift = provider.activeGift;
    final shopName =
        gift?.shopName.isNotEmpty == true ? gift!.shopName : 'the shop';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AlphaTheme.accentGreen.withOpacity(0.15),
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
              Icons.check_circle_rounded,
              color: AlphaTheme.accentGreen,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Confirmed!',
          style: TextStyle(
            color: AlphaTheme.accentGreen,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your gift is being prepared by $shopName.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AlphaTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        _buildGiftSummaryCard(provider),
        const SizedBox(height: 32),
        _buildBackButton(),
      ],
    );
  }

  // ===========================================================================
  // SHARED WIDGETS
  // ===========================================================================

  Widget _buildGiftSummaryCard(GiftProvider provider) {
    final gift = provider.activeGift;
    if (gift == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AlphaTheme.glassCard,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AlphaTheme.primaryOrange.withOpacity(0.15),
              borderRadius: AlphaTheme.buttonRadius,
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: AlphaTheme.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.productName,
                  style: const TextStyle(
                    color: AlphaTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'For ${gift.receiverName}',
                  style: const TextStyle(
                    color: AlphaTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'K${gift.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AlphaTheme.accentGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        style: ElevatedButton.styleFrom(
          backgroundColor: AlphaTheme.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AlphaTheme.buttonRadius,
          ),
        ),
        child: const Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, _) {
        if (_confettiController.value == 0) return const SizedBox.shrink();
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            progress: _confettiController.value,
          ),
        );
      },
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

/// Radar sweep animation painter
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Expanding concentric rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.4;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    // Sweep arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 2,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.15),
        ],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius * 0.8, sweepPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

/// Simple confetti burst painter
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _random = Random(42); // Fixed seed for consistent pattern

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      AlphaTheme.accentGreen,
      AlphaTheme.accentBlue,
      AlphaTheme.secondaryGold,
      AlphaTheme.primaryOrange,
    ];

    final centerX = size.width / 2;
    final startY = size.height * 0.3;

    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 80 + _random.nextDouble() * 200;
      final x = centerX + cos(angle) * speed * progress;
      final y = startY +
          sin(angle) * speed * progress * 0.6 +
          progress * progress * 300; // gravity
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 6, height: 10),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
