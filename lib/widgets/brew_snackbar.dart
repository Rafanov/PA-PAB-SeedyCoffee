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
