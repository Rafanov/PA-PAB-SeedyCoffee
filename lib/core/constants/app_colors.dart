import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Monochrome core (matches Seedy logo — black & white) ─────
  static const Color black      = Color(0xFF0A0A0A);
  static const Color charcoal   = Color(0xFF1A1A1A);
  static const Color graphite   = Color(0xFF2D2D2D);
  static const Color darkGray   = Color(0xFF444444);
  static const Color midGray    = Color(0xFF777777);
  static const Color lightGray  = Color(0xFFAAAAAA);
  static const Color silverGray = Color(0xFFCCCCCC);
  static const Color offWhite   = Color(0xFFF2F2F2);
  static const Color white      = Color(0xFFFFFFFF);

  // ── Brown accent (warm coffee tones — secondary palette) ─────
  static const Color brown900   = Color(0xFF1C0A00);
  static const Color brown800   = Color(0xFF2C1A0E);
  static const Color brown700   = Color(0xFF3D2314);
  static const Color brown600   = Color(0xFF5C3317);
  static const Color brown500   = Color(0xFF7B4A1E);  // primary accent
  static const Color brown400   = Color(0xFF9E6B3A);
  static const Color brown300   = Color(0xFFC49A6C);
  static const Color brown200   = Color(0xFFDDBF9A);
  static const Color brown150   = Color(0xFFE8D5BC);
  static const Color brown100   = Color(0xFFF0E6D6);
  static const Color brown50    = Color(0xFFF8F3EE);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color cream      = Color(0xFFF5EFE6);
  static const Color divider    = Color(0xFFE8E8E8);

  static const Color success    = Color(0xFF2E7D32);
  static const Color successBg  = Color(0xFFE8F5E9);
  static const Color successText= Color(0xFF1B5E20);
  static const Color error      = Color(0xFFC62828);
  static const Color errorBg    = Color(0xFFFFEBEE);
  static const Color warning    = Color(0xFFF57F17);
  static const Color warningBg  = Color(0xFFFFF8E1);

  static const Color textPrimary   = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textMuted     = Color(0xFF777777);

  // ── Gradients — monochrome style ─────────────────────────────
  // Main header: deep black to charcoal
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0A), Color(0xFF2D2D2D)],
  );

  // Splash: pure black background to match logo
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
  );

  // Button: dark charcoal with slight warmth
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)],
  );

  // Banner gradients (for banners without images)
  static const List<LinearGradient> bannerGradients = [
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF0A0A0A), Color(0xFF3D2314)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A1A), Color(0xFF5C3317)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF2D2D2D), Color(0xFF7B4A1E)]),
  ];

  // Card gradient (for menu cards without images)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
  );

  // Card subtle shadow color
  static const Color shadowColor = Color(0x1A000000);
}
