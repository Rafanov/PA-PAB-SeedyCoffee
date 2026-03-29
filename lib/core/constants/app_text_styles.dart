import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge  = GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.1);
  static TextStyle displayMedium = GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2);
  static TextStyle displaySmall  = GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);
  static TextStyle brandTitle      = GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1);
  static TextStyle brandTitleWhite = GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1);
  static TextStyle headerTitle     = GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white);
  static TextStyle headerSubtitle  = GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70);

  static TextStyle bodyLarge  = GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6);
  static TextStyle bodyMedium = GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6);
  static TextStyle bodySmall  = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle bodyXSmall = GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);

  static TextStyle labelLarge  = GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle labelMedium = GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle labelSmall  = GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5);
  static TextStyle caption     = GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted);

  static TextStyle priceMain   = GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brown500);
  static TextStyle priceLarge  = GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brown500);
  static TextStyle priceStrike = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, decoration: TextDecoration.lineThrough);
  static TextStyle buttonLarge = GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3);
  static TextStyle buttonMedium= GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brown500);
}
