import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/cart_item_model.dart';
import '../../models/menu_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';
import '../../widgets/option_pill.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuModel menu;
  const MenuDetailScreen({super.key, required this.menu});
  @override
  State<MenuDetailScreen> createState() => _State();
}

class _State extends State<MenuDetailScreen> {
  String? _size, _sugar, _ice;
  int _qty = 1;
  bool _expanded = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    if (m.sizeOptions?.isNotEmpty == true)  _size  = m.sizeOptions!.first;
    if (m.sugarOptions?.isNotEmpty == true) _sugar = m.sugarOptions!.first;
    if (m.iceOptions?.isNotEmpty == true)   _ice   = m.iceOptions!.first;
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  void _addToCart() {
    final p = context.read<AppProvider>();
    if (!p.isLoggedIn) {
      Navigator.pushNamed(context, AppConstants.routeLogin);
      return;
    }
    if (!widget.menu.isAvailable) {
      BrewSnackbar.show(context, 'Menu ini tidak tersedia', isError: true);
      return;
    }
    if (!p.canAddToCart(widget.menu.id, _qty)) {
      BrewSnackbar.show(context, 'Maksimal 10 item per menu', isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    final opts = [_size, _sugar, _ice].where((v) => v != null).join(' · ');
    final note = _noteCtrl.text.trim();
    final fullNote = [opts, note].where((v) => v.isNotEmpty).join(' | ');
    p.addToCart(CartItemModel(
      menuItemId:   widget.menu.id,
      menuName:     widget.menu.name,
      menuImageUrl: widget.menu.imageUrl,
      size: _size, sugar: _sugar, ice: _ice,
      notes: fullNote,
      quantity:  _qty,
      unitPrice: widget.menu.price,
    ));
    BrewSnackbar.show(context, '${widget.menu.name} added to cart!');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.menu;
    final isSoldOut = !m.isAvailable;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(children: [
        // ── Scrollable content ──────────────────────────────
        SingleChildScrollView(
          child: Column(children: [
            // Hero image
            Stack(children: [
              Container(
                height: 280,
                width: double.infinity,
                color: AppColors.silverGray,
                child: m.imageUrl != null && m.imageUrl!.isNotEmpty
                    ? Image.network(m.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.coffee_rounded,
                                size: 60, color: Colors.white54)))
                    : const Center(child: Icon(Icons.coffee_rounded,
                        size: 60, color: Colors.white54)),
              ),
              // Sold out overlay on image
              if (isSoldOut)
                Positioned.fill(child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: const Center(child: Text('SOLD OUT',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900, letterSpacing: 3))))),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.45),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                    onPressed: () => Navigator.pop(context)))),
              // Badge
              if (m.badge != null)
                Positioned(bottom: 12, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _badgeColor(m.badge!),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(m.badge!, style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w800)))),
            ]),

            // ── Detail content ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(m.name,
                      style: AppTextStyles.displayMedium.copyWith(
                          color: isSoldOut ? AppColors.midGray : null)),
                  const SizedBox(height: 4),
                  Text(m.categoryName, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),

                  // Description
                  if (m.description != null && m.description!.isNotEmpty) ...[
                    GestureDetector(
                      onTap: m.description!.length > 120
                          ? () => setState(() => _expanded = !_expanded)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.description!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary, height: 1.65),
                              maxLines: m.description!.length > 120
                                  ? (_expanded ? null : 3) : null,
                              overflow: m.description!.length > 120 && !_expanded
                                  ? TextOverflow.ellipsis : null),
                          if (m.description!.length > 120) ...[
                            const SizedBox(height: 4),
                            Text(_expanded ? 'Show less ↑' : 'Read more ↓',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 30),
                  ],

                  // Options — disabled if sold out
                  if (!isSoldOut) ...[
                    if (m.sizeOptions != null)
                      _opts('Size', m.sizeOptions!, _size,
                          (v) => setState(() => _size = v)),
                    if (m.sugarOptions != null)
                      _opts('Sugar', m.sugarOptions!, _sugar,
                          (v) => setState(() => _sugar = v)),
                    if (m.iceOptions != null)
                      _opts('Ice / Temp', m.iceOptions!, _ice,
                          (v) => setState(() => _ice = v)),

                    // Note
                    Text('Note to Barista', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 4),
                    Text('Optional — any special requests?',
                        style: AppTextStyles.caption),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3, maxLength: 200,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Extra hot, less ice...')),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.silverGray)),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 20, color: AppColors.midGray),
                        const SizedBox(width: 12),
                        Expanded(child: Text(
                            'Menu ini sedang tidak tersedia. '
                            'Silakan cek lagi nanti!',
                            style: AppTextStyles.bodySmall)),
                      ])),
                  ],
                ],
              ),
            ),
          ]),
        ),

        // ── Bottom bar ──────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, -4))]),
            child: Row(children: [
              // Price
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Helpers.formatPrice(m.price * _qty),
                    style: AppTextStyles.priceLarge),
                if (m.originalPrice != null)
                  Text(Helpers.formatPrice(m.originalPrice! * _qty),
                      style: AppTextStyles.priceStrike),
              ])),
              // Qty selector (hidden when sold out)
              if (!isSoldOut) ...[
                _qBtn(Icons.remove_rounded,
                    () => setState(() { if (_qty > 1) _qty--; })),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$_qty',
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 18))),
                _qBtn(Icons.add_rounded,
                    () { if (_qty < 10) setState(() => _qty++); }),
                const SizedBox(width: 12),
              ],
              // Button
              SizedBox(width: 130, child: BrewButton(
                  label: isSoldOut ? 'Sold Out' : 'Add to Cart',
                  onPressed: isSoldOut ? null : _addToCart)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _opts(String label, List<String> opts, String? selected,
      ValueChanged<String> onSelect) =>
    Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
          children: opts.map((o) => OptionPill(
              label: o, isActive: selected == o,
              onTap: () => onSelect(o))).toList()),
      ]));

  Widget _qBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.silverGray)),
      child: Icon(icon, size: 16, color: AppColors.black)));
}

Color _badgeColor(String label) => switch (label) {
  'Recommended'  => const Color(0xFF1565C0),
  'High Sales'   => const Color(0xFFB71C1C),
  'New Menu'     => const Color(0xFF2E7D32),
  'Limited'      => const Color(0xFFE65100),
  'Chef Special' => const Color(0xFF4A148C),
  _              => const Color(0xFF0A0A0A),
};