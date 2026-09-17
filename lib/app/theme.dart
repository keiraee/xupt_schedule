import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 与 panel 前端一致：暖墨色纸面风
  static const ink = Color(0xFF26251E);
  static const muted = Color(0x9426251E); // rgba(38,37,30,.58)
  static const faint = Color(0x6126251E); // rgba(38,37,30,.38)
  static const line = Color(0x1A26251E); // rgba(38,37,30,.1)
  static const lineStrong = Color(0x2926251E); // rgba(38,37,30,.16)
  static const soft = Color(0x0A26251E); // rgba(38,37,30,.04)
  static const soft2 = Color(0x0F26251E); // rgba(38,37,30,.06)
  static const accent = ink;
  static const onAccent = Colors.white;
  static const danger = Color(0xFF9B3D36);
  static const focus = Color(0x3826251E);
  static const today = Color(0x0A26251E);
  static const courseBg = Color(0xFFFAFAFA);

  static const tagPlaceBg = Color(0xFFEEF2F6);
  static const tagPlace = Color(0xFF4D5B68);
  static const tagTeacherBg = Color(0xFFF3EFE8);
  static const tagTeacher = Color(0xFF5F5649);
  static const tagClassBg = Color(0xFFEEF1EC);
  static const tagClass = Color(0xFF4F5A4C);
  static const tagWeekBg = Color(0xFFF4ECEB);
  static const tagWeek = Color(0xFF6D4540);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: ink, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
