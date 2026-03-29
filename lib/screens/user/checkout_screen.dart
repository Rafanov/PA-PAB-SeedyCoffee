import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/order_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _State();
}

class _State extends State<CheckoutScreen> {
  bool _loading = false;
  OrderModel? _order;

  Future<void> _checkout(AppProvider p) async {
    // Confirm dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi Pesanan',
            style: AppTextStyles.displaySmall),
        content: Text(
            'Total: ${Helpers.formatPrice(p.cartTotal)}\n\n'
            'Lanjut ke pembayaran?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cek Dulu')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Bayar Sekarang',
                style: TextStyle(color: Colors.white))),
        ]));
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final order = await p.checkout();
      setState(() { _order = order; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      BrewSnackbar.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    if (_order != null) return _successView(_order!);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Order summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Ringkasan Pesanan',
                style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            ...p.cart.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                // Menu image
                if (item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.menuImageUrl!,
                        width: 42, height: 42, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.coffee_rounded,
                                size: 28, color: AppColors.lightGray)))
                else
                  const Icon(Icons.coffee_rounded,
                      size: 28, color: AppColors.lightGray),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${item.quantity}x ${item.menuName}',
                      style: AppTextStyles.bodyMedium),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(item.notes!,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.midGray)),
                ])),
                Text(Helpers.formatPrice(item.subtotal),
                    style: AppTextStyles.priceMain
                        .copyWith(fontSize: 13)),
              ]))),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Total', style: AppTextStyles.labelLarge),
              Text(Helpers.formatPrice(p.cartTotal),
                  style: AppTextStyles.priceLarge),
            ]),
          ])),
        const SizedBox(height: 16),
        // Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.silverGray)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: AppColors.midGray),
            const SizedBox(width: 10),
            Expanded(child: Text(
                'Setelah checkout, tunjukkan kode unik ke kasir untuk pembayaran.',
                style: AppTextStyles.bodySmall)),
          ])),
        const SizedBox(height: 24),
        BrewButton(
          label: 'Konfirmasi & Checkout',
          isLoading: _loading,
          onPressed: () => _checkout(p)),
        const SizedBox(height: 12),
        BrewButton(
          label: 'Kembali ke Cart',
          style: BrewButtonStyle.ghost,
          onPressed: () => Navigator.pop(context)),
      ]));
  }

  Widget _successView(OrderModel order) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle_rounded,
            size: 64, color: AppColors.success),
        const SizedBox(height: 16),
        Text('Pesanan Berhasil!',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Tunjukkan kode ini ke kasir',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        // QR Code
        Center(child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08), blurRadius: 16)]),
          child: Column(children: [
            QrImageView(data: order.orderCode, size: 180),
            const SizedBox(height: 12),
            Text(order.orderCode,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8)),
            const SizedBox(height: 4),
            Text(Helpers.formatPrice(order.totalAmount),
                style: AppTextStyles.priceLarge),
          ]))),
        const SizedBox(height: 24),
        BrewButton(
          label: 'Lihat Riwayat Pesanan',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, AppConstants.routeMain, (_) => false)),
      ])));
}
