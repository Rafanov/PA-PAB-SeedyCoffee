import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/order_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import 'package:provider/provider.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});
  @override
  State<KasirScreen> createState() => _State();
}

class _State extends State<KasirScreen> {
  final _ctrl = TextEditingController();
  OrderModel? _order;
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(AppProvider p) async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length < 4) return;
    setState(() { _loading = true; _searched = false; _order = null; });
    final result = await p.findOrderByCode(code);
    setState(() { _order = result; _searched = true; _loading = false; });
  }

  Future<void> _confirm(AppProvider p) async {
    if (_order == null) return;
    // Optimistic update - show confirmed immediately
    setState(() => _order = _order!.copyWith(
        status: OrderStatus.confirmed));
    // Sync with DB in background
    p.confirmPayment(_order!.orderCode);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: CustomScrollView(slivers: [
          // ── Header ──────────────────────────────────────────
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 14, 20, 20),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13)),
                clipBehavior: Clip.hardEdge,
                child: Image.asset('assets/images/LogoSeedy.jpg',
                    fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cashier Panel', style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11, fontWeight: FontWeight.w500)),
                Text(p.currentUser?.fullName ?? 'Cashier',
                    style: AppTextStyles.headerTitle.copyWith(fontSize: 19)),
              ])),
              GestureDetector(
                onTap: () {
                  p.logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppConstants.routeMain, (_) => false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3))),
                  child: const Text('Logout', style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700)))),
            ]),
          )),

          // ── Body ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Input card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16)]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Scan Payment Code',
                      style: AppTextStyles.displaySmall
                          .copyWith(fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('Enter the order code from customer',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  Text('ORDER CODE', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Z0-9a-z]')),
                      TextInputFormatter.withFunction((old, newVal) =>
                          newVal.copyWith(text: newVal.text.toUpperCase())),
                      TextInputFormatter.withFunction((old, newVal) =>
                          newVal.copyWith(
                              text: newVal.text.toUpperCase())),
                    ],
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black, letterSpacing: 8),
                    decoration: const InputDecoration(
                      hintText: '······',
                      hintStyle: TextStyle(
                          fontFamily: 'monospace', fontSize: 26,
                          color: AppColors.silverGray, letterSpacing: 8),
                      counterText: ''),
                    onSubmitted: (_) => _search(p),
                    onChanged: (v) {
                      if (v.length >= 4) _search(p);
                    },
                  ),
                  const SizedBox(height: 14),
                  BrewButton(
                    label: _loading ? 'Searching...' : 'Search Order',
                    isLoading: _loading,
                    onPressed: () => _search(p)),
                ])),
              const SizedBox(height: 16),

              // Not found
              if (_searched && _order == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.search_off_rounded,
                        color: AppColors.error, size: 26),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                        'Code not found. Please check again.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.error))),
                  ])),

              // Order result
              if (_order != null)
                _OrderResult(
                    order: _order!,
                    onConfirm: () => _confirm(p)),
            ])),
          ),
        ]),
      ),
    );
  }
}

// ── Order Result Widget ───────────────────────────────────────────────────────
class _OrderResult extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onConfirm;
  const _OrderResult({required this.order, required this.onConfirm});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.08), blurRadius: 16)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Order header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.orderCode,
              style: AppTextStyles.labelLarge.copyWith(
                  fontFamily: 'monospace', letterSpacing: 2)),
          Text(Helpers.formatDate(order.createdAt),
              style: AppTextStyles.caption),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: order.isPaid ? AppColors.successBg : AppColors.warningBg,
            borderRadius: BorderRadius.circular(20)),
          child: Text(order.isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: order.isPaid
                    ? AppColors.successText : AppColors.warning))),
      ]),
      const Divider(height: 22),

      // Items
      ...order.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Expanded(child: Row(children: [
              const Icon(Icons.coffee_rounded,
                  color: AppColors.lightGray, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  '${item.quantity}× ${item.menuName}',
                  style: AppTextStyles.labelMedium)),
            ])),
            Text(Helpers.formatPrice(item.subtotal),
                style: AppTextStyles.priceMain.copyWith(fontSize: 13)),
          ]),
          if (item.notes != null && item.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 3),
              child: Text('Note: ${item.notes!}',
                  style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.midGray))),
        ]))),

      const Divider(height: 16),

      // Total
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('TOTAL BILL',
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
        Text(Helpers.formatPrice(order.totalAmount),
            style: AppTextStyles.priceLarge),
      ]),
      const SizedBox(height: 16),

      // Action
      if (!order.isPaid)
        BrewButton(
          label: 'Confirm Payment — ${Helpers.formatPrice(order.totalAmount)}',
          onPressed: onConfirm)
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Payment Confirmed!',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.successText)),
              Text('Receipt ready to print for kitchen',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.success)),
            ]),
          ])),
    ]),
  );
}
