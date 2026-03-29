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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Image ───────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Stack(children: [
                // Image
                Positioned.fill(child:
                  menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                      ? Image.network(menu.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.coffee_rounded,
                                  size: 50, color: AppColors.lightGray)))
                      : const Center(child: Icon(Icons.coffee_rounded,
                          size: 50, color: AppColors.lightGray))),

                // Sold Out overlay
                if (isSoldOut)
                  Positioned.fill(child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(child: Text('SOLD OUT',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13, letterSpacing: 2))))),

                // Label badge (top-left)
                if (menu.badge != null && !isSoldOut)
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _labelColor(menu.badge!),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(menu.badge!, style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800)))),
              ])),
          ),

          // ── Info ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(menu.name,
                  style: AppTextStyles.labelMedium
                      .copyWith(fontWeight: FontWeight.w800,
                          color: isSoldOut
                              ? AppColors.midGray : AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text(Helpers.formatPrice(menu.price),
                    style: AppTextStyles.priceMain.copyWith(
                        fontSize: 13,
                        color: isSoldOut
                            ? AppColors.midGray : null)),
                if (!isSoldOut)
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 18)),
              ]),
              if (menu.originalPrice != null && !isSoldOut)
                Text(Helpers.formatPrice(menu.originalPrice!),
                    style: AppTextStyles.priceStrike),
            ]),
          ),
        ]),
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
