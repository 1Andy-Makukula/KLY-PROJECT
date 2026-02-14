import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/alpha_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool animateOnHover;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.zero,
    this.animateOnHover = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: _buildGlassContent(),
      ),
    );
  }

  Widget _buildGlassContent() {
    final decoration = _isHovered ? GlassStyles.active : GlassStyles.basic;
    
    if (AlphaTheme.useLowPowerMode) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding,
        transform: widget.animateOnHover && _isHovered
            ? (Matrix4.identity()
              ..scale(1.02)
              ..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: decoration.copyWith(color: Colors.black.withOpacity(0.8)),
        child: widget.child,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: widget.margin,
      transform: widget.animateOnHover && _isHovered
          ? (Matrix4.identity()
            ..scale(1.02)
            ..translate(0.0, -4.0))
          : Matrix4.identity(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: widget.padding,
            decoration: decoration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
