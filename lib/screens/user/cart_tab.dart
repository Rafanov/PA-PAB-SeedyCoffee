import '../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import 'order_detail_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cart = p.cart;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _Header(p: p)),

        if (cart.isEmpty)
          SliverFillRemaining(child: _Empty()),

        if (cart.isNotEmpty) ...[
          _secTitle('Active Order', '${cart.length} items'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _CartTile(item: cart[i], index: i, p: p),
                childCount: cart.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Summary(p: p)),
        ],


      ]),
    );
  }

  SliverToBoxAdapter _secTitle(String title, String sub) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.displaySmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(sub,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
        ),
      );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AppProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 18),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cart', style: AppTextStyles.headerTitle),
            const SizedBox(height: 2),
            Text(
              p.cart.isNotEmpty
                  ? '${p.cartItemCount} items · ${Helpers.formatPrice(p.cartTotal)}'
                  : 'No active order',
              style: AppTextStyles.headerSubtitle,
            ),
          ]),
        ),
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.shopping_bag_outlined,
              color: Colors.white, size: 20),
        ),
      ]),
    );
  }
}

// ── Cart Item Tile ────────────────────────────────────────────────────────────
class _CartTile extends StatelessWidget {
  final CartItemModel item;
  final int index;
  final AppProvider p;
  const _CartTile({required this.item, required this.index, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(width: 52, height: 52,
            child: item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty
                ? Image.network(item.menuImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.offWhite,
                      child: const Icon(Icons.coffee_rounded,
                          color: AppColors.midGray, size: 26)))
                : Container(color: AppColors.offWhite,
                    child: const Icon(Icons.coffee_rounded,
                        color: AppColors.midGray, size: 26))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.menuName,
                style: AppTextStyles.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (item.customizationText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(item.customizationText,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.brown400)),
            ],
            // Barista note (part after " | " in notes)
            Builder(builder: (_) {
              final parts = item.notes.split(' | ');
              final baristaNote = parts.length > 1 ? parts.last.trim() : '';
              if (baristaNote.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Note: $baristaNote',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.midGray,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis));
            }),
            const SizedBox(height: 6),
            Text(Helpers.formatPrice(item.subtotal),
                style: AppTextStyles.priceMain.copyWith(fontSize: 14)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            _QBtn(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                p.updateCartQty(index, item.quantity - 1);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${item.quantity}',
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 15)),
            ),
            _QBtn(
              icon: Icons.add_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                p.updateCartQty(index, item.quantity + 1);
              },
            ),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              p.removeFromCart(index);
            },
            child: Text('Remove',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ]),
      ]),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.black),
        ),
      );
}

// ── Summary + Checkout ────────────────────────────────────────────────────────
class _Summary extends StatefulWidget {
  final AppProvider p;
  const _Summary({required this.p});

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  bool _checkingOut = false;

  void _showCheckoutConfirm() {
    Navigator.pushNamed(context, AppConstants.routeCheckout);
  }

  void _showCheckoutConfirmOLD() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: const BoxDecoration(
                color: AppColors.offWhite, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.black, size: 30)),
            const SizedBox(height: 16),
            Text('Check Your Order',
                style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Please make sure your order is correct before proceeding to payment.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
            const SizedBox(height: 22),
            // "Check first" button
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.midGray),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Let me check first 🔍',
                    style: TextStyle(color: AppColors.black,
                        fontWeight: FontWeight.w700)))),
            const SizedBox(height: 10),
            // "All good" button
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text("Looks good, pay now! ✅",
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)))),
          ]),
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    setState(() => _checkingOut = true);
    HapticFeedback.mediumImpact();
    try {
      final order = await widget.p.checkout();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order, showCode: true),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.07),
                blurRadius: 12,
              )
            ],
          ),
          child: Column(children: [
            _row('Subtotal', Helpers.formatPrice(widget.p.cartTotal)),
            const SizedBox(height: 8),
            _row('Service Fee', 'Free'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.offWhite, thickness: 1.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Bill', style: AppTextStyles.labelLarge),
                Text(Helpers.formatPrice(widget.p.cartTotal),
                    style: AppTextStyles.priceLarge),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),
        BrewButton(
          label: 'Checkout Now',
          prefixIcon: '💳',
          isLoading: _checkingOut,
          onPressed: _showCheckoutConfirm,
        ),
      ]),
    );
  }

  Widget _row(String a, String b) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(b, style: AppTextStyles.bodyMedium),
        ],
      );
}

// ── History Card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  const _HistoryCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 12,
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: order.isPaid
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  order.isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.access_time_rounded,
                  color: order.isPaid
                      ? AppColors.success
                      : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(order.id, style: AppTextStyles.labelMedium),
                  Text(Helpers.formatDate(order.createdAt),
                      style: AppTextStyles.caption),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isPaid
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: order.isPaid
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  order.isPaid ? 'Paid ✅' : 'Unpaid ⏳',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: order.isPaid
                        ? AppColors.successText
                        : AppColors.warning,
                  ),
                ),
              ),
            ]),
          ),
          // Item chips
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              children: order.items
                  .map((it) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${it.quantity}× ${it.menuName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Unique code
          if (!order.isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: AppColors.silverGray, width: 1.5),
                ),
                child: Row(children: [
                  const Icon(Icons.qr_code_rounded,
                      color: AppColors.brown400, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    order.uniqueCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.black,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('· Show to cashier',
                        style: AppTextStyles.caption
                            .copyWith(fontStyle: FontStyle.italic)),
                  ),
                ]),
              ),
            ),
          // Footer total
          Container(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
            decoration: const BoxDecoration(
              color: AppColors.offWhite,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Order', style: AppTextStyles.bodySmall),
                Row(children: [
                  Text(Helpers.formatPrice(order.totalAmount),
                      style: AppTextStyles.priceMain),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.midGray, size: 16),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                color: AppColors.offWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 46, color: AppColors.midGray),
            ),
            const SizedBox(height: 18),
            Text('Cart is Empty',
                style:
                    AppTextStyles.displaySmall.copyWith(fontSize: 20)),
            const SizedBox(height: 6),
            Text('Pick your favorite menu!',
                style: AppTextStyles.bodySmall),
          ]),
    );
  }
}