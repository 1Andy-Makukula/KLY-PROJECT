import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import '../theme/alpha_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double width;
  final double? height;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.zero,
    this.width = double.infinity,
    this.height,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (AlphaTheme.useLowPowerMode) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: GlassStyles.basic.copyWith(
          color: Colors.black.withOpacity(0.8), // Fallback opaque color for performance
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
    }

    return Container(
       margin: margin,
       child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: GlassStyles.basic,
            child: child,
          ),
        ),
      ),
    );
  }
}
