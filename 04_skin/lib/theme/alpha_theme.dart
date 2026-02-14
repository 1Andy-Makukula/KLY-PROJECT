import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KithLyColors {
  static const Color orange = Color(0xFFF85A47);
  static const Color gold = Color(0xFFDAA520);
  static const Color emerald = Color(0xFF2ECC71);
  static const Color alert = Color(0xFFE74C3C);
  static const Color darkBackground = Color(0xFF1A1A1A);
}

class GlassStyles {
  static BoxDecoration get basic => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: KithLyColors.orange.withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get active => BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: KithLyColors.orange.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: KithLyColors.orange.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration get scoreCard => BoxDecoration(
    gradient: const LinearGradient(
      colors: [KithLyColors.orange, KithLyColors.gold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: KithLyColors.orange.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class AlphaTheme {
  static const Color orange = KithLyColors.orange;
  static const Color gold = KithLyColors.gold;

  // Performance Settings
  static bool useLowPowerMode = false;

  // Aliases for compatibility
  static const Color emerald = KithLyColors.emerald;
  static const Color alert = KithLyColors.alert;
  static const Color primaryOrange = orange;
  static TextStyle get heading => headlineLarge;
  static TextStyle get body => bodyMedium;

  // Glassmorphism Constants
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.2;
  static const double glassBorderOpacity = 0.3;

  // Text Styles
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, color: Colors.white);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8));

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KithLyColors.darkBackground,
    primaryColor: KithLyColors.orange,
    colorScheme: const ColorScheme.dark(
      primary: KithLyColors.orange,
      secondary: KithLyColors.gold,
      surface: Colors.transparent,
      error: KithLyColors.alert,
    ),
    textTheme: TextTheme(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: labelLarge,
    ),
    useMaterial3: true,
  );
}
