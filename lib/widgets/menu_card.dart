import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/helpers.dart';
import '../models/menu_model.dart';

class MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback? onTap;
  const MenuCard({super.key, required this.menu, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = !menu.isAvailable;
    return GestureDetector(
      onTap: isSoldOut ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(fit: StackFit.expand, children: [
                  // Image
                  menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                      ? Image.network(menu.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.offWhite,
                            child: const Icon(Icons.coffee_rounded,
                                size: 40, color: AppColors.lightGray)))
                      : Container(color: AppColors.offWhite,
                          child: const Icon(Icons.coffee_rounded,
                              size: 40, color: AppColors.lightGray)),

                  // Sold out overlay
                  if (isSoldOut)
                    Container(
                      color: Colors.black.withOpacity(0.58),
                      child: const Center(child: Text('SOLD OUT',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12, letterSpacing: 2)))),

                  // Badge
                  if (menu.badge != null && !isSoldOut)
                    Positioned(top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _labelColor(menu.badge!),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(menu.badge!, style: const TextStyle(
                            color: Colors.white, fontSize: 8,
                            fontWeight: FontWeight.w800)))),
                ])),
            ),

            // ── Info ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(menu.name,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: isSoldOut
                              ? AppColors.midGray : AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Helpers.formatPrice(menu.price),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSoldOut
                                        ? AppColors.midGray
                                        : const Color(0xFF8B4513))),
                            if (menu.originalPrice != null && !isSoldOut)
                              Text(Helpers.formatPrice(menu.originalPrice!),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.midGray,
                                      decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ),
                      if (!isSoldOut)
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _labelColor(String label) => switch (label) {
  'Recommended'  => const Color(0xFF1565C0),
  'High Sales'   => const Color(0xFFB71C1C),
  'New Menu'     => const Color(0xFF2E7D32),
  'Limited'      => const Color(0xFFE65100),
  'Chef Special' => const Color(0xFF4A148C),
  _              => const Color(0xFF0A0A0A),
};