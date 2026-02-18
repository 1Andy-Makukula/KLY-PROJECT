/// =============================================================================
/// KithLy Global Protocol - ALPHA THEME (Phase IV-Extension)
/// alpha_theme.dart - Project Alpha Design System
/// =============================================================================
///
/// Design Directive: Soft shadows, rounded cards, "glass" overlays.
/// Based on existing dark theme patterns from collection_key.dart
library;

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

/// Alpha Theme - Project Alpha Design System
class AlphaTheme {
  AlphaTheme._();

  // ===========================================================================
  // COLORS
  // ===========================================================================

  /// Primary dark background
  static const Color backgroundDark = Color(0xFF0F172A);

  /// Secondary background for cards
  static const Color backgroundCard = Color(0xFF1E293B);

  /// Tertiary card surface (glass effect base)
  static const Color backgroundGlass = Color(0xFF334155);

  /// PROJECT ALPHA Primary - Orange
  static const Color primaryOrange = Color(0xFFF85A47);

  /// PROJECT ALPHA Secondary - Gold
  static const Color secondaryGold = Color(0xFFDAA520);

  /// Primary accent - Blue
  static const Color accentBlue = Color(0xFF3B82F6);

  /// Success - Green
  static const Color accentGreen = Color(0xFF10B981);

  /// Warning - Amber
  static const Color accentAmber = Color(0xFFF59E0B);

  /// Error - Red
  static const Color accentRed = Color(0xFFEF4444);

  /// WhatsApp green for share buttons
  static const Color whatsappGreen = Color(0xFF25D366);

  /// Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================

  /// Revenue chart gradient (green to transparent)
  static LinearGradient get revenueGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentGreen.withOpacity(0.4),
          accentGreen.withOpacity(0.0),
        ],
      );

  /// Card gradient (glass effect)
  static LinearGradient get cardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backgroundCard, backgroundGlass],
      );

  /// Success gradient for confirmation states
  static LinearGradient get successGradient => LinearGradient(
        colors: [
          accentGreen.withOpacity(0.2),
          accentGreen.withOpacity(0.05),
        ],
      );

  /// Accent gradient for hero elements
  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentBlue.withOpacity(0.8),
          accentGreen.withOpacity(0.6),
        ],
      );

  // ===========================================================================
  // SHADOWS
  // ===========================================================================

  /// Soft elevation shadow
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  /// Accent glow shadow (for prominent elements)
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentBlue.withOpacity(0.3),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ];

  /// Green glow for scan button (THE TRIGGER)
  static List<BoxShadow> get scanButtonGlow => [
        BoxShadow(
          color: accentGreen.withOpacity(0.5),
          blurRadius: 40,
          spreadRadius: 10,
        ),
      ];

  // ===========================================================================
  // BORDERS & RADII
  // ===========================================================================

  /// Standard card radius
  static BorderRadius get cardRadius => BorderRadius.circular(20);

  /// Button radius
  static BorderRadius get buttonRadius => BorderRadius.circular(12);

  /// Chip/tag radius
  static BorderRadius get chipRadius => BorderRadius.circular(8);

  /// Glass border for cards
  static Border get glassBorder => Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1,
      );

  /// Accent border for highlighted elements
  static Border accentBorder([double opacity = 0.5]) => Border.all(
        color: accentBlue.withOpacity(opacity),
        width: 2,
      );

  // ===========================================================================
  // CARD DECORATIONS
  // ===========================================================================

  /// Standard glass card decoration
  static BoxDecoration get glassCard => BoxDecoration(
        gradient: cardGradient,
        borderRadius: cardRadius,
        border: glassBorder,
        boxShadow: softShadow,
      );

  /// Elevated glass card with glow
  static BoxDecoration get elevatedGlassCard => BoxDecoration(
        gradient: cardGradient,
        borderRadius: cardRadius,
        border: glassBorder,
        boxShadow: glowShadow,
      );

  /// Scan button decoration (THE TRIGGER - most prominent)
  static BoxDecoration get scanButtonDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentGreen,
            accentGreen.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: scanButtonGlow,
      );

  /// Urgent order card decoration (pulsing red border variant of glassCard)
  static BoxDecoration get urgentCardDecoration => BoxDecoration(
        gradient: cardGradient,
        borderRadius: cardRadius,
        border: Border.all(color: accentRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentRed.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Low-stock warning banner decoration
  static BoxDecoration get urgentBannerDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentAmber.withOpacity(0.15),
            accentRed.withOpacity(0.08),
          ],
        ),
        borderRadius: cardRadius,
        border: Border.all(color: accentAmber.withOpacity(0.4), width: 1),
      );

  // ===========================================================================
  // TEXT STYLES
  // ===========================================================================

  /// Large heading (e.g., "Revenue Today")
  static TextStyle get headingLarge => const TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  /// Medium heading (e.g., card titles)
  static TextStyle get headingMedium => const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  /// Body text
  static TextStyle get bodyText => const TextStyle(
        color: textSecondary,
        fontSize: 14,
      );

  /// Caption/muted text
  static TextStyle get captionText => const TextStyle(
        color: textMuted,
        fontSize: 12,
      );

  /// Currency display (ZMW amounts)
  static TextStyle get currencyLarge => const TextStyle(
        color: accentGreen,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      );

  /// Code/token display
  static TextStyle get codeText => const TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
        fontFamily: 'monospace',
      );

  // ===========================================================================
  // BUTTON STYLES
  // ===========================================================================

  /// Primary action button
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        elevation: 0,
      );

  /// Success button (approve action)
  static ButtonStyle get successButton => ElevatedButton.styleFrom(
        backgroundColor: accentGreen,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        elevation: 0,
      );

  /// Danger button (reject action)
  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: accentRed,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        elevation: 0,
      );

  /// Ghost/outline button
  static ButtonStyle get ghostButton => OutlinedButton.styleFrom(
        foregroundColor: textSecondary,
        side: const BorderSide(color: textMuted),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      );

  // ===========================================================================
  // THEME DATA
  // ===========================================================================

  /// Full ThemeData for MaterialApp
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: accentBlue,
        colorScheme: const ColorScheme.dark(
          primary: accentBlue,
          secondary: accentGreen,
          surface: backgroundCard,
          error: accentRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: backgroundCard,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          elevation: 0,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
        outlinedButtonTheme: OutlinedButtonThemeData(style: ghostButton),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: buttonRadius,
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.1),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: backgroundCard,
          contentTextStyle: bodyText,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          behavior: SnackBarBehavior.floating,
        ),
      );
}

/// =============================================================================
/// ALPHA GLASS CONTAINER (Glassmorphism Widget)
/// =============================================================================

/// Glass container with backdrop blur and white opacity overlay
class AlphaGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const AlphaGlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.padding,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? AlphaTheme.cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: borderRadius ?? AlphaTheme.cardRadius,
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Re-route dialog glass container with higher contrast
class AlphaReRouteGlass extends StatelessWidget {
  final Widget child;

  const AlphaReRouteGlass({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AlphaGlassContainer(
      blur: 20,
      opacity: 0.15,
      borderColor: AlphaTheme.primaryOrange.withOpacity(0.3),
      child: child,
    );
  }
}
