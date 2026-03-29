import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/app_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';

class AdminPromoTab extends StatefulWidget {
  const AdminPromoTab({super.key});
  @override
  State<AdminPromoTab> createState() => _State();
}

class _State extends State<AdminPromoTab> {
  final _msg = TextEditingController();
  bool _sending = false;
  final List<Map<String, dynamic>> _history = [];

  static const _templates = [
    ('Flash Sale 🔥',
     'FLASH SALE! Diskon 30% untuk semua minuman hari ini.\nBerlaku s/d pukul 20.00.\n\nSegera pesan sekarang! ☕'),
    ('Weekend Special 🎉',
     'Weekend Special!\nBuy 2 Get 1 Free untuk semua minuman.\nHanya Sabtu & Minggu.'),
    ('New Menu ✨',
     'Menu baru sudah hadir!\n[Nama menu] — [Deskripsi singkat]\n\nCoba sekarang di SeedyCoffee!'),
    ('Custom ✏️', ''),
  ];
  int _tpl = 0;

  @override
  void initState() {
    super.initState();
    _msg.text = _templates[0].$2;
    _msg.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _msg.dispose(); super.dispose(); }

  Future<void> _send(AppProvider p) async {
    if (_msg.text.trim().isEmpty) {
      BrewSnackbar.show(context, 'Message cannot be empty!', isError: true);
      return;
    }
    setState(() => _sending = true);
    // Send WA (live or demo)
    final result = await WhatsappService.instance
        .sendPromo(_msg.text.trim(), p.users.toList());
    // Always send in-app notifications to all customer users with phones
    await p.sendPromoNotification(_msg.text.trim());
    HapticFeedback.mediumImpact();
    setState(() {
      _sending = false;
      _history.insert(0, {
        'msg':  _msg.text.trim(),
        'sent': '${result.sent}',
        'demo': result.isDemo,
      });
    });
    if (!mounted) return;
    BrewSnackbar.show(context,
        result.isDemo
            ? 'Sent to ${result.sent} users (in-app)'
            : '${result.sent} WhatsApp messages sent');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final wa = WhatsappService.instance;
    final preview = wa.previewMessage(_msg.text);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Template chips ────────────────────────────────────────
      Text('Message Template', style: AppTextStyles.labelMedium),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _templates.asMap().entries.map((e) =>
        GestureDetector(
          onTap: () => setState(() { _tpl = e.key; _msg.text = e.value.$2; }),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _tpl == e.key ? AppColors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _tpl == e.key ? AppColors.black : AppColors.silverGray,
                  width: 1.5)),
            child: Text(e.value.$1, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: _tpl == e.key ? Colors.white : AppColors.textSecondary)))
        )).toList()),
      const SizedBox(height: 16),

      // ── Message editor ────────────────────────────────────────
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 14)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Message', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(controller: _msg, maxLines: 5, style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
                hintText: 'Write your promo message...')),
          Align(alignment: Alignment.centerRight,
            child: Text('${_msg.text.length} chars',
                style: AppTextStyles.caption.copyWith(
                  color: _msg.text.length > 300
                      ? AppColors.error : AppColors.textMuted))),
        ])),
      const SizedBox(height: 14),

      // ── WA Preview bubble ─────────────────────────────────────
      if (preview.isNotEmpty) ...[
        Text('WhatsApp Preview', style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(width: 30, height: 30,
            decoration: const BoxDecoration(
                color: AppColors.silverGray, shape: BoxShape.circle),
            child: const Center(child: Text('☕', style: TextStyle(fontSize: 14)))),
          const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFDCF8C6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomRight: Radius.circular(16))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SeedyCoffee', style: AppTextStyles.labelSmall
                  .copyWith(color: const Color(0xFF075E54))),
              const SizedBox(height: 3),
              Text(preview, style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF1A1A1A), height: 1.5)),
              const SizedBox(height: 4),
              Align(alignment: Alignment.bottomRight,
                child: Text('Now ✓✓', style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF667781)))),
            ]))),
        ]),
        const SizedBox(height: 14),
      ],

      // ── Recipients info ───────────────────────────────────────
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.silverGray)),
        child: Row(children: [
          const Icon(Icons.people_outline_rounded, color: AppColors.midGray, size: 18),
          const SizedBox(width: 8),
          Text('${p.promoRecipientCount} customers with phone numbers',
              style: AppTextStyles.bodySmall),
          const SizedBox(width: 4),
          // Subtle mode indicator
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: wa.isLive ? AppColors.successBg : AppColors.offWhite,
              borderRadius: BorderRadius.circular(6)),
            child: Text(wa.isLive ? 'Live WA' : 'Demo',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: wa.isLive ? AppColors.successText : AppColors.midGray))),
        ])),
      const SizedBox(height: 14),

      BrewButton(
        label: '📤 Send Promo',
        isLoading: _sending,
        onPressed: () => _send(p)),

      // ── History ───────────────────────────────────────────────
      if (_history.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Send History', style: AppTextStyles.displaySmall.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        ..._history.map((h) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: AppColors.black.withOpacity(0.06), blurRadius: 8)]),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((h['msg'] as String).length > 60
                  ? '${(h['msg'] as String).substring(0, 60)}...'
                  : h['msg'] as String,
                  style: AppTextStyles.bodySmall, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${h['sent']} recipients · ${h['demo'] == true ? 'In-app' : 'WA'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.midGray)),
            ])),
          ])),
        ),
      ],
    ]);
  }
}
