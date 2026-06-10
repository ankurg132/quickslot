import 'package:flutter/material.dart';

class AppTheme {
  // Lush Precision Theme Colors
  static const primaryColor = Color(0xFF006C49); // Lush Deep Green
  static const accentColor = Color(0xFF10B981);  // Vibrant Emerald Green
  static const backgroundColor = Color(0xFFF8F9FF); // Soft Canvas Off-White/Blue
  static const cardColor = Color(0xFFFFFFFF);     // Pure White
  static const textColor = Color(0xFF0B1C30);     // Slate Navy Text
  static const secondaryTextColor = Color(0xFF565E74); // Slate Gray Text
  static const borderColor = Color(0xFFE2E8F0);    // Thin Light Gray Border

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: accentColor,
        secondary: secondaryTextColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textColor,
        onSurface: textColor,
        outline: borderColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Manrope',
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Manrope',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Manrope',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'Manrope',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textColor,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: secondaryTextColor,
          fontFamily: 'Inter',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'JetBrains Mono',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          fontFamily: 'JetBrains Mono',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0, // No shadow as per specifications (Level 1 is thin border)
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 8px corner radius
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0, // 0 elevation as depth is conveyed by thin border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 8px radius
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }
}
