import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class BrewSnackbar {
  BrewSnackbar._();
  static void show(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: isError ? AppColors.error : AppColors.graphite,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 2500),
      ));
  }
}

class BrewErrorDialog {
  BrewErrorDialog._();

  static Future<void> show(BuildContext context, String message, {
    String title = 'Perhatian',
    String buttonText = 'OK',
  }) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFD32F2F), size: 28)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A))),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF666666),
                    height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(buttonText, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)))),
          ])),
      ),
    );
  }

  static Future<void> showSuccess(BuildContext context, String message, {
    String title = 'Berhasil',
  }) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF2E7D32), size: 28)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A))),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF666666),
                    height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('OK', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)))),
          ])),
      ),
    );
  }
}