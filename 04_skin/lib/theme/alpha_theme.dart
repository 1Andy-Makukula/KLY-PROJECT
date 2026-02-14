import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlphaTheme {
  // Primary Colors
  static const Color orange = Color(0xFFF85A47);
  static const Color gold = Color(0xFFDAA520);
  static const Color darkBackground = Color(
    0xFF1A1A1A,
  ); // Dark background for glass effect

  // Aliases for compatibility
  static const Color primaryOrange = orange;
  static TextStyle get heading => headlineLarge;

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

  // Theme Data
  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: orange,
    colorScheme: const ColorScheme.dark(
      primary: orange,
      secondary: gold,
      surface: Colors.transparent, // Important for glass
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
