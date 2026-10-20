import 'package:flutter/material.dart';

abstract final class ShopColors {
  static const ink = Color(0xFF101923);
  static const blue = Color(0xFF22A5D5);
  static const card = Color(0xFFF6F7F8);
  static const muted = Color(0xFF92989D);
  static const orange = Color(0xFFFF7546);
}

final shopTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ShopColors.blue,
    primary: ShopColors.blue,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: ShopColors.ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: ShopColors.ink),
  ),
);
