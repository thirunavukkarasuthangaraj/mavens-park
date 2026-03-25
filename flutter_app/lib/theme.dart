import 'package:flutter/material.dart';

// ── Mavens-i Brand Colors (from web.mavens-i.com) ───────
class AppColors {
  static const navy     = Color(0xFF1A2744); // dark navy — hero bg, appbar
  static const orange   = Color(0xFFF16522); // orange — CTA buttons, accents
  static const navyMid  = Color(0xFF2D3F6B); // mid navy — cards, secondary
  static const navyLight= Color(0xFF3D5A99); // light navy — icon bg, borders
  static const bgWhite  = Color(0xFFFFFFFF); // screen background
  static const bgSoft   = Color(0xFFF4F6FB); // soft light bg for sections
  static const textDark = Color(0xFF1A2744); // primary text
  static const textGrey = Color(0xFF7B8BB2); // secondary text
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.orange,
    ),
    scaffoldBackgroundColor: AppColors.bgWhite,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
  );
}
