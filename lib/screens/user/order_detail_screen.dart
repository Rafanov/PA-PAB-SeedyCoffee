import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/order_model.dart';
import '../../widgets/brew_snackbar.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  final bool showCode;
  const OrderDetailScreen({super.key, required this.order, required this.showCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Order Details', style: AppTextStyles.headerTitle
              .copyWith(fontSize: 18)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // ── Status Card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: order.isPaid ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: order.isPaid
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: order.isPaid
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.warning.withOpacity(0.15),
                      shape: BoxShape.circle),
                    child: Icon(
                      order.isPaid
                          ? Icons.check_circle_outline_rounded
                          : Icons.access_time_rounded,
                      color: order.isPaid ? AppColors.success : AppColors.warning,
                      size: 26)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(order.isPaid ? 'Payment Confirmed! 🎉' : 'Awaiting Payment',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: order.isPaid ? AppColors.successText : AppColors.warning)),
                    const SizedBox(height: 2),
                    Text(order.isPaid
                        ? 'Your barista is preparing your order ☕'
                        : 'Show the QR or code below to the cashier',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: order.isPaid ? AppColors.success : AppColors.warning)),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),

              // ── QR Code ──────────────────────────────────────
              if (!order.isPaid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                        color: AppColors.black.withOpacity(0.10),
                        blurRadius: 18)],
                  ),
                  child: Column(children: [
                    Text('PAYMENT CODE', style: AppTextStyles.labelSmall
                        .copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 14),
                    QrImageView(
                      data: order.orderCode,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.black),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: order.orderCode));
                        BrewSnackbar.show(context, 'Code copied! 📋');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.midGray, width: 2),
                        ),
                        child: Text(order.orderCode, style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black, letterSpacing: 6))),
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.touch_app_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Tap to copy code', style: AppTextStyles.caption),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              // ── Receipt ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: AppColors.black.withOpacity(0.08),
                      blurRadius: 16)],
                ),
                child: Column(children: [
                  const Text('☕', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(AppConstants.appName, style: AppTextStyles.brandTitle
                      .copyWith(fontSize: 20)),
                  Text('Premium Coffee Experience',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Text(order.id, style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w700)),
                  Text(Helpers.formatDate(order.createdAt),
                      style: AppTextStyles.caption),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider()),

                  // Items
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Expanded(child: Row(children: [
                          // Menu image thumbnail
                          if (item.menuImageUrl != null) ...[
                            ClipRRect(borderRadius: BorderRadius.circular(6),
                              child: Image.network(item.menuImageUrl!,
                                width: 28, height: 28, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.coffee_rounded,
                                    size: 20, color: AppColors.midGray))),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Icon(Icons.coffee_rounded,
                                size: 20, color: AppColors.midGray),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: Text(
                            '${item.quantity}× ${item.menuName}',
                            style: AppTextStyles.labelMedium)),
                        ])),
                        Text(Helpers.formatPrice(item.subtotal),
                            style: AppTextStyles.priceMain.copyWith(fontSize: 13)),
                      ]),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(left: 36, top: 2),
                          child: Text(item.notes!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontStyle: FontStyle.italic))),
                    ]),
                  )),

                  const Divider(height: 16),
                  _r2('Payment', '💵 Cash'),
                  const SizedBox(height: 6),
                  _r2('Status', order.isPaid ? '✅ Paid' : '⏳ Unpaid'),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider()),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text('TOTAL', style: AppTextStyles.labelLarge
                        .copyWith(fontSize: 15)),
                    Text(Helpers.formatPrice(order.totalAmount),
                        style: AppTextStyles.priceLarge),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text('Thank you for visiting! ☕',
                      style: AppTextStyles.caption),
                  Text('See you again at SeedyCoffee 🤎',
                      style: AppTextStyles.caption),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _r2(String a, String b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a, style: AppTextStyles.bodySmall),
      Text(b, style: AppTextStyles.bodySmall
          .copyWith(fontWeight: FontWeight.w700)),
    ],
  );
}
