import 'package:flutter/material.dart';
import '../theme/alpha_theme.dart';
import 'glass_container.dart';

// TOOL 1: The Glass Back Button
// Usage: Just put AlphaBackButton() in your AppBar or Stack
class AlphaBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AlphaBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        // Make it circular by forcing equal width/height if needed,
        // or letting the parent constrain it.
        // Here we just use the GlassContainer's default rounded look.
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// TOOL 2: Primary Action Button (The "Orange" Button)
// Usage: AlphaPrimaryButton(text: "PAY NOW", onPressed: () {})
class AlphaPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? icon;

  const AlphaPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AlphaTheme.primaryOrange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AlphaTheme.primaryOrange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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

// TOOL 3: Secondary Glass Button (The "Cancel" or "Decline" Button)
// Usage: AlphaGlassButton(text: "Cancel", onPressed: () {})
class AlphaGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AlphaGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
