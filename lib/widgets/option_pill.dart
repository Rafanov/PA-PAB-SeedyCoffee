import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class OptionPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const OptionPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.black : AppColors.silverGray,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
    ),
  );
}
