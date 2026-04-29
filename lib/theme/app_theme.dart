import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFFF9F0);
  static const Color primary = Color(0xFFFF7F7F);
  static const Color secondary = Color(0xFF7FC8FF);
  static const Color accent = Color(0xFFFFD700);
  static const Color navBar = Color(0xFFFFEEDD);

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          surface: background,
        ),
        useMaterial3: true,
      );

  static TextStyle odiaLetterStyle({double size = 36}) => TextStyle(
        fontFamily: 'NotoSansOriya',
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF333333),
        height: 1.2,
      );

  static TextStyle labelStyle({double size = 14}) => const TextStyle(
        fontFamily: 'NotoSansOriya',
        fontSize: 14,
        color: Color(0xFF666666),
      );
}
