import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

class _State extends State<KasirScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Column(children: [
          // ── Header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 14, 20, 0),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
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
              const SizedBox(height: 14),
              TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 2.5,
                labelStyle: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white, fontSize: 11),
                unselectedLabelStyle:
                    AppTextStyles.labelSmall.copyWith(fontSize: 11),
                tabs: const [
                  Tab(icon: Icon(Icons.tag_rounded, size: 16),
                      text: 'Kode Bayar'),
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 16),
                      text: 'QR Scan'),
                  Tab(icon: Icon(Icons.receipt_long_outlined, size: 16),
                      text: 'History'),
                ],
              ),
            ]),
          ),

          Expanded(child: TabBarView(controller: _tab, children: [
            _KodeTab(),
            _QrScanTab(),
            _HistoryTab(),
          ])),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — Kode Pembayaran (manual input)
// ══════════════════════════════════════════════════════════════════
class _KodeTab extends StatefulWidget {
  @override
  State<_KodeTab> createState() => _KodeTabState();
}

class _KodeTabState extends State<_KodeTab> {
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
    setState(() => _order = _order!.copyWith(status: OrderStatus.confirmed));
    p.confirmPayment(_order!.orderCode);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08), blurRadius: 16)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Masukkan Kode Pesanan',
                style: AppTextStyles.displaySmall.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            Text('Ketik kode unik dari customer',
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
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
                TextInputFormatter.withFunction((old, newVal) =>
                    newVal.copyWith(text: newVal.text.toUpperCase())),
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
              onChanged: (v) { if (v.length >= 4) _search(p); },
            ),
            const SizedBox(height: 14),
            BrewButton(
              label: _loading ? 'Searching...' : 'Cari Pesanan',
              isLoading: _loading,
              onPressed: () => _search(p)),
          ])),
        const SizedBox(height: 16),

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
              Expanded(child: Text('Kode tidak ditemukan. Coba lagi.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error))),
            ])),

        if (_order != null)
          _OrderResult(order: _order!, onConfirm: () => _confirm(p)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2 — QR Scanner (kamera belakang scan QR dari layar customer)
// ══════════════════════════════════════════════════════════════════
class _QrScanTab extends StatefulWidget {
  @override
  State<_QrScanTab> createState() => _QrScanTabState();
}

class _QrScanTabState extends State<_QrScanTab> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back, // kamera belakang untuk scan layar customer
  );

  OrderModel? _order;
  bool _searching = false;
  bool _scanned = false; // lock sementara setelah scan berhasil

  @override
  void dispose() { _scanner.dispose(); super.dispose(); }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _searching) return; // cegah scan ganda
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() { _scanned = true; _searching = true; _order = null; });
    HapticFeedback.mediumImpact();

    final p = context.read<AppProvider>();
    final result = await p.findOrderByCode(code.trim().toUpperCase());

    if (!mounted) return;
    setState(() { _order = result; _searching = false; });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kode "$code" tidak ditemukan'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating));
      // Reset scan lock setelah 2 detik biar bisa scan lagi
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _scanned = false);
    }
  }

  Future<void> _confirm(AppProvider p) async {
    if (_order == null) return;
    setState(() => _order = _order!.copyWith(status: OrderStatus.confirmed));
    p.confirmPayment(_order!.orderCode);
  }

  void _reset() {
    setState(() { _order = null; _scanned = false; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── Viewfinder scanner ────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.3), blurRadius: 20)]),
          clipBehavior: Clip.hardEdge,
          child: Column(children: [
            // Camera view
            SizedBox(
              height: 280,
              child: Stack(children: [
                // Scanner
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                ),
                // Overlay frame
                Center(child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _scanned
                          ? AppColors.success : Colors.white,
                      width: 3),
                    borderRadius: BorderRadius.circular(16)),
                )),
                // Status overlay saat searching
                if (_searching)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Mencari pesanan...',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]))),
                // Success overlay
                if (_scanned && _order != null)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 56),
                      const SizedBox(height: 8),
                      Text('QR Terdeteksi!', style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                    ]))),
              ]),
            ),
            // Bottom info bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  _scanned ? Icons.check_circle_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: _scanned ? AppColors.success : Colors.white60,
                  size: 16),
                const SizedBox(width: 8),
                Text(
                  _scanned
                      ? 'Scan berhasil'
                      : 'Arahkan ke QR code customer',
                  style: TextStyle(
                      color: _scanned ? AppColors.success : Colors.white60,
                      fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Tombol scan ulang
        if (_scanned)
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.brown500, size: 18),
            label: Text('Scan QR Lain',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brown500, fontWeight: FontWeight.w700))),

        const SizedBox(height: 8),

        // Hasil pesanan
        if (_order != null)
          _OrderResult(order: _order!, onConfirm: () => _confirm(p)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3 — History Pembelian
// ══════════════════════════════════════════════════════════════════
class _HistoryTab extends StatefulWidget {
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _filter = 'All';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<OrderModel> _filtered(List<OrderModel> all) {
    var list = List<OrderModel>.from(all);
    if (_filter == 'Paid')    list = list.where((o) => o.isPaid).toList();
    if (_filter == 'Pending') list = list.where((o) => !o.isPaid).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) =>
        o.orderCode.toLowerCase().contains(q) ||
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
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Cari kode atau menu...',
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
                          ? Colors.white : AppColors.textSecondary))))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(8)),
              child: Text('${orders.length} pesanan',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.black, fontWeight: FontWeight.w700))),
          ]),
        ]),
      ),

      Expanded(
        child: orders.isEmpty
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📋', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Belum ada pesanan',
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 17)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _HistoryCard(order: orders[i]),
              ),
      ),
    ]);
  }
}

// ── History Card ──────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final OrderModel order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: order.isPaid
            ? AppColors.success.withOpacity(0.3) : AppColors.silverGray),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(
          color: order.isPaid ? AppColors.successBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(11)),
        child: Icon(
          order.isPaid
              ? Icons.check_circle_outline_rounded
              : Icons.access_time_rounded,
          color: order.isPaid ? AppColors.success : AppColors.warning,
          size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(order.orderCode, style: AppTextStyles.labelMedium.copyWith(
            fontFamily: 'monospace', letterSpacing: 1)),
        Text(Helpers.formatDate(order.createdAt),
            style: AppTextStyles.caption),
        Text(order.items.map((i) => '${i.quantity}× ${i.menuName}').join(', '),
            style: AppTextStyles.bodySmall,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(Helpers.formatPrice(order.totalAmount),
            style: AppTextStyles.priceMain.copyWith(fontSize: 13)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: order.isPaid ? AppColors.successBg : AppColors.warningBg,
            borderRadius: BorderRadius.circular(6)),
          child: Text(order.isPaid ? 'Lunas' : 'Pending',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: order.isPaid
                      ? AppColors.successText : AppColors.warning))),
      ]),
    ]));
}

// ── Order Result ──────────────────────────────────────────────────
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
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.orderCode, style: AppTextStyles.labelLarge.copyWith(
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: order.isPaid
                      ? AppColors.successText : AppColors.warning))),
      ]),
      const Divider(height: 22),

      ...order.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Expanded(child: Row(children: [
            const Icon(Icons.coffee_rounded,
                color: AppColors.lightGray, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.quantity}× ${item.menuName}',
                style: AppTextStyles.labelMedium)),
          ])),
          Text(Helpers.formatPrice(item.subtotal),
              style: AppTextStyles.priceMain.copyWith(fontSize: 13)),
        ]))),

      const Divider(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('TOTAL', style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
        Text(Helpers.formatPrice(order.totalAmount),
            style: AppTextStyles.priceLarge),
      ]),
      const SizedBox(height: 16),

      if (!order.isPaid)
        BrewButton(
          label: 'Konfirmasi Pembayaran — ${Helpers.formatPrice(order.totalAmount)}',
          onPressed: onConfirm)
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pembayaran Terkonfirmasi!',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.successText)),
              Text('Pesanan siap diproses',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.success)),
            ]),
          ])),
    ]),
  );
}