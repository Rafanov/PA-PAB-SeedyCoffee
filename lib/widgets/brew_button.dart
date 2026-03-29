import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum BrewButtonStyle { primary, outline, ghost }

class BrewButton extends StatelessWidget {
  final String label;
  final String? prefixIcon;
  final VoidCallback? onPressed;
  final BrewButtonStyle style;
  final bool isLoading;
  final double? width;

  const BrewButton({
    super.key,
    required this.label,
    this.prefixIcon,
    this.onPressed,
    this.style = BrewButtonStyle.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = isLoading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, children: [
            if (prefixIcon != null) ...[
              Text(prefixIcon!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(label),
          ]);

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: switch (style) {
        BrewButtonStyle.primary => DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: AppColors.black.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
            child: DefaultTextStyle(
              style: const TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700),
              child: content))),

        BrewButtonStyle.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: const BorderSide(color: AppColors.black, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
          child: DefaultTextStyle(
            style: const TextStyle(
                color: AppColors.black, fontSize: 15,
                fontWeight: FontWeight.w700),
            child: content)),

        BrewButtonStyle.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.midGray,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
          child: DefaultTextStyle(
            style: const TextStyle(
                color: AppColors.midGray, fontSize: 15,
                fontWeight: FontWeight.w600),
            child: content)),
      });
  }
}
