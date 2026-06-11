import 'package:flutter/material.dart';

class AppTheme {
  // Paleta principal
  static const Color blue50 = Color(0xFFE6F1FB);
  static const Color blue100 = Color(0xFFB5D4F4);
  static const Color blue400 = Color(0xFF378ADD);
  static const Color blue600 = Color(0xFF185FA5);
  static const Color blue800 = Color(0xFF0C447C);
  static const Color blue900 = Color(0xFF042C53);

  static const Color purple50 = Color(0xFFEEEDFE);
  static const Color purple200 = Color(0xFFAFA9EC);
  static const Color purple600 = Color(0xFF534AB7);
  static const Color purple800 = Color(0xFF3C3489);
  static const Color purple900 = Color(0xFF26215C);

  static const Color red50 = Color(0xFFFCEBEB);
  static const Color red100 = Color(0xFFF7C1C1);
  static const Color red200 = Color(0xFFF09595);
  static const Color red400 = Color(0xFFE24B4A);
  static const Color red600 = Color(0xFFA32D2D);
  static const Color red900 = Color(0xFF501313);

  static const Color amber50 = Color(0xFFFAEEDA);
  static const Color amber100 = Color(0xFFFAC775);
  static const Color amber400 = Color(0xFFEF9F27);
  static const Color amber600 = Color(0xFF854F0B);
  static const Color amber900 = Color(0xFF412402);

  static const Color green50 = Color(0xFFEAF3DE);
  static const Color green100 = Color(0xFFC0DD97);
  static const Color green600 = Color(0xFF3B6D11);
  static const Color green900 = Color(0xFF173404);

  static const Color coral50 = Color(0xFFFAECE7);
  static const Color coral200 = Color(0xFFF0997B);
  static const Color coral600 = Color(0xFF993C1D);
  static const Color coral900 = Color(0xFF4A1B0C);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue600,
      primary: blue600,
      secondary: purple600,
      error: red400,
      surface: const Color(0xFFF8F9FA),
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F4F7),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A2E),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: blue600,
        side: const BorderSide(color: blue600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: blue600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: red400),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: blue600,
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:
      TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 0.5,
    ),
  );
}