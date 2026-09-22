import 'package:flutter/material.dart';

/// Spacing system — chỉ dùng các bước này.
abstract final class Spacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadius {
  static const double card = 16;
  static const double button = 14;
}

class AppTheme {
  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3E7D32),
      secondary: const Color(0xFFF9A825),
      error: const Color(0xFFC62828),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F6F1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3E7D32),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF3E7D32).withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3E7D32),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.shade200),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// Số liệu lớn (tổng kg, thành tiền).
  static const TextStyle numberXL = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle numberL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6D6A60),
  );
}
