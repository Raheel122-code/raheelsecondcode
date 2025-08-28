import 'package:flutter/material.dart';

class CreatorTheme {
  static const Color primaryRed = Color(0xFFE31837);
  static const Color darkRed = Color(0xFF890620);
  static const Color accentRed = Color(0xFFFF1744);
  static const Color lightRed = Color(0xFFFFCDD2);
  static const Color backgroundRed = Color(0xFFFBE9E7);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundRed,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: accentRed,
        surface: Colors.white,
        background: backgroundRed,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconTheme: const IconThemeData(color: darkRed),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: lightRed,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
