import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});
  @override
  State<AdminOrdersTab> createState() => _State();
}

class _State extends State<AdminOrdersTab> {
  String _filter = 'All';   // All / Paid / Pending
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<OrderModel> _filtered(List<OrderModel> all) {
    // Copy first so we can sort (allOrders is unmodifiable)
    var list = List<OrderModel>.from(all);
    if (_filter == 'Paid')    list = list.where((o) => o.isPaid).toList();
    if (_filter == 'Pending') list = list.where((o) => !o.isPaid).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) =>
        o.orderCode.toLowerCase().contains(q) ||
        o.userId.toLowerCase().contains(q) ||
        o.items.any((i) => i.menuName.toLowerCase().contains(q))
      ).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final orders = _filtered(p.allOrders);

    return Column(children: [
      // ── Search + Filter ──────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search order code, user, or menu...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      })
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          Row(children: [
            for (final f in ['All', 'Paid', 'Pending'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filter == f
                          ? AppColors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filter == f
                            ? AppColors.black : AppColors.silverGray,
                        width: 1.5)),
                    child: Text(f, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _filter == f
                          ? Colors.white : AppColors.textSecondary))),
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(8)),
              child: Text('${orders.length} orders',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.black, fontWeight: FontWeight.w700))),
          ]),
        ]),
      ),

      // ── Order List ───────────────────────────────────────────
      Expanded(
        child: orders.isEmpty
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📋', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No orders found', style: AppTextStyles.displaySmall
                    .copyWith(fontSize: 17)),
                const SizedBox(height: 6),
                Text('Orders from all users will appear here',
                    style: AppTextStyles.bodySmall),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderCard(
                  order: orders[i],
                  users: p.users.toList(),
                ),
              ),
      ),
    ]);
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final List<UserModel> users;
  const _OrderCard({required this.order, required this.users});
  @override
  State<_OrderCard> createState() => _CardState();
}

class _CardState extends State<_OrderCard> {
  bool _expanded = false;

  String get _userName {
    try {
      final user = widget.users.firstWhere(
          (u) => u.id == widget.order.userId);
      return user.fullName.isNotEmpty ? user.fullName : (user.email ?? 'Unknown');
    } catch (_) {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: o.isPaid
              ? AppColors.success.withOpacity(0.3)
              : AppColors.silverGray,
          width: 1.5),
        boxShadow: [BoxShadow(
            color: AppColors.black.withOpacity(0.07), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: o.isPaid ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(11)),
              child: Icon(
                o.isPaid
                    ? Icons.check_circle_outline_rounded
                    : Icons.access_time_rounded,
                color: o.isPaid ? AppColors.success : AppColors.warning,
                size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(o.orderCode,
                    style: AppTextStyles.labelMedium.copyWith(
                        fontFamily: 'monospace', letterSpacing: 1),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: o.isPaid
                        ? AppColors.successBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(o.isPaid ? 'Paid ✅' : 'Pending ⏳',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: o.isPaid
                            ? AppColors.successText : AppColors.warning))),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(_userName,
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(Helpers.formatDate(o.createdAt),
                    style: AppTextStyles.caption),
              ]),
            ])),
          ]),
        ),

        // ── Item summary chips ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Wrap(spacing: 6, runSpacing: 5,
            children: o.items.map((it) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.silverGray)),
              child: Text('${it.quantity}× ${it.menuName}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w600)))).toList()),
        ),

        // ── Total + expand button ────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: _expanded
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(
                      bottom: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text(Helpers.formatPrice(o.totalAmount),
                  style: AppTextStyles.priceMain),
              Row(children: [
                Text(_expanded ? 'Hide detail' : 'View receipt',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700)),
                Icon(_expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColors.black),
              ]),
            ])),
        ),

        // ── Expanded receipt ─────────────────────────────────────
        if (_expanded)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              // Receipt header
              Center(child: Column(children: [
                const Text('☕', style: TextStyle(fontSize: 22)),
                Text('SeedyCoffee',
                    style: AppTextStyles.labelLarge),
                Text(o.orderCode, style: AppTextStyles.caption
                    .copyWith(fontFamily: 'monospace', letterSpacing: 1)),
                Text(Helpers.formatDate(o.createdAt),
                    style: AppTextStyles.caption),
              ])),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              // Customer
              _receiptRow('Customer', _userName),
              _receiptRow('Status',
                  o.isPaid ? '✅ Paid' : '⏳ Pending'),
              if (o.confirmedAt != null)
                _receiptRow('Paid at',
                    Helpers.formatDate(o.confirmedAt!)),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              // Items
              ...o.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Expanded(child: Row(children: [
                      if (item.menuImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(item.menuImageUrl!,
                              width: 26, height: 26,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.coffee_rounded,
                                      size: 18,
                                      color: AppColors.lightGray)))
                      else
                        const Icon(Icons.coffee_rounded,
                            size: 18, color: AppColors.lightGray),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                          '${item.quantity}× ${item.menuName}',
                          style: AppTextStyles.labelMedium)),
                    ])),
                    Text(Helpers.formatPrice(item.subtotal),
                        style: AppTextStyles.priceMain
                            .copyWith(fontSize: 13)),
                  ]),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 34, top: 3),
                      child: Text('📝 ${item.notes!}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic))),
                ])),
              ),
              const Divider(color: AppColors.divider),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text('TOTAL', style: AppTextStyles.labelLarge),
                Text(Helpers.formatPrice(o.totalAmount),
                    style: AppTextStyles.priceLarge),
              ]),
            ]),
          ),
      ]),
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
      Text(label, style: AppTextStyles.bodySmall),
      Text(value, style: AppTextStyles.bodySmall
          .copyWith(fontWeight: FontWeight.w700)),
    ]));
}
