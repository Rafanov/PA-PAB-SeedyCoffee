import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';
import '../../widgets/brew_text_field.dart';
import 'order_detail_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (!p.isLoggedIn) return const _GuestView();

    final user   = p.currentUser!;
    final orders = p.userOrders;
    final paid   = orders.where((o) => o.isPaid).toList();
    final spend  = paid.fold(0, (s, o) => s + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 14, 20, 24),
          child: Column(children: [
            Stack(alignment: Alignment.bottomRight, children: [
              GestureDetector(
                onTap: () => _showEditProfile(context, p),
                child: Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.45), width: 3)),
                  clipBehavior: Clip.hardEdge,
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Image.network(user.avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded, color: Colors.white, size: 44))
                      : const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                ),
              ),
              Container(width: 26, height: 26,
                decoration: BoxDecoration(color: AppColors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14)),
            ]),
            const SizedBox(height: 12),
            Text(user.fullName,
                style: AppTextStyles.headerTitle.copyWith(fontSize: 21)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20)),
              child: Text(user.email ?? user.username,
                  style: AppTextStyles.headerSubtitle
                      .copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _Stat('Orders', '${orders.length}'),
                _vd(),
                _Stat('Paid', '${paid.length}'),
                _vd(),
                _Stat('Spent', spend > 0 ? Helpers.formatPrice(spend) : 'Rp 0'),
              ])),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _section('Account Info', Icons.person_outline_rounded, [
              _row(Icons.badge_outlined,   'Full Name', user.fullName),
              _row(Icons.email_outlined,   'Email', user.email ?? '-'),
              _row(Icons.phone_outlined,   'Phone',
                  user.phone?.isNotEmpty == true ? user.phone! : 'Not set'),
              _row(Icons.calendar_today_outlined, 'Member Since',
                  Helpers.formatDateShort(user.createdAt), isLast: true),
            ]),
            const SizedBox(height: 14),
            // Order History card
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _OrderHistoryScreen())),
              child: Container(
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.07), blurRadius: 14)]),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 20, color: AppColors.black)),
                  title: Text('Riwayat Pesanan',
                      style: AppTextStyles.labelMedium),
                  subtitle: Text('${orders.length} pesanan',
                      style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.midGray),
                ))),
            const SizedBox(height: 20),
            BrewButton(label: 'Edit Profile',
                style: BrewButtonStyle.outline,
                onPressed: () => _showEditProfile(context, p)),
            const SizedBox(height: 12),
            BrewButton(label: 'Sign Out',
                style: BrewButtonStyle.ghost,
                onPressed: () => showDialog(context: context,
                    builder: (_) => _LogoutDialog(p: p))),
            const SizedBox(height: 36),
          ]))),
      ]),
    );
  }

  static void _showEditProfile(BuildContext ctx, AppProvider p) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(p: p));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _Stat(String label, String value) =>
  Expanded(child: Column(children: [
    Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(
        color: Colors.white.withOpacity(0.7), fontSize: 10)),
  ]));

Widget _vd() => Container(width: 1, height: 32,
    color: Colors.white.withOpacity(0.25));

Widget _section(String title, IconData icon, List<Widget> rows) =>
  Container(
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.07), blurRadius: 14)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.midGray),
          const SizedBox(width: 6),
          Text(title.toUpperCase(), style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.midGray, letterSpacing: 1)),
        ])),
      const Divider(height: 1, color: AppColors.divider),
      ...rows,
    ]));

Widget _row(IconData icon, String label, String value,
    {bool isLast = false, Color? valueColor}) =>
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(border: isLast ? null
        : const Border(bottom: BorderSide(color: AppColors.divider))),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.midGray)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        const SizedBox(height: 1),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary)),
      ])),
    ]));

// ── Edit Profile Sheet ────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AppProvider p;
  const _EditProfileSheet({required this.p});
  @override
  State<_EditProfileSheet> createState() => _EditState();
}

class _EditState extends State<_EditProfileSheet> {
  late final _nameCtrl  = TextEditingController(
      text: widget.p.currentUser?.fullName);
  late final _phoneCtrl = TextEditingController(
      text: widget.p.currentUser?.phone ?? '');
  bool _saving = false;
  bool _uploadingAvatar = false;
  Uint8List? _avatarBytes;

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _pickAvatar() async {
    setState(() => _uploadingAvatar = true);
    final bytes = await StorageService.instance.pickAndCrop(
        context, aspectRatio: 1.0, title: 'Crop Profile Photo');
    if (bytes == null) { setState(() => _uploadingAvatar = false); return; }
    setState(() => _avatarBytes = bytes);
    final url = await StorageService.instance
        .uploadAvatarFromBytes(bytes, widget.p.currentUser!.id);
    setState(() => _uploadingAvatar = false);
    if (url == null) {
      if (mounted) BrewSnackbar.show(context, 'Avatar upload failed', isError: true);
      return;
    }
    await widget.p.updateAvatar(url);
    if (mounted) BrewSnackbar.show(context, 'Profile photo updated!');
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      BrewSnackbar.show(context, 'Name is required', isError: true);
      return;
    }
    setState(() => _saving = true);
    final err = await widget.p.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim());
    setState(() => _saving = false);
    if (err != null) {
      if (mounted) BrewSnackbar.show(context, err, isError: true);
    } else {
      if (mounted) { BrewSnackbar.show(context, 'Profile saved!'); Navigator.pop(context); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.p.currentUser!;
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.silverGray,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Edit Profile', style: AppTextStyles.displaySmall),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _uploadingAvatar ? null : _pickAvatar,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(width: 80, height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.offWhite, shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: _uploadingAvatar
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.black, strokeWidth: 2))
                  : _avatarBytes != null
                      ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                      : user.avatarUrl?.isNotEmpty == true
                          ? Image.network(user.avatarUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded, color: AppColors.midGray, size: 40))
                          : const Icon(Icons.person_rounded,
                              color: AppColors.midGray, size: 40)),
            Container(width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.photo_camera_outlined,
                  color: Colors.white, size: 14)),
          ])),
        const SizedBox(height: 6),
        Text('Tap to change', style: AppTextStyles.caption),
        const SizedBox(height: 20),
        BrewTextField(label: 'Full Name', hint: 'Your full name',
            controller: _nameCtrl,
            prefixIcon: const Icon(Icons.person_outline,
                color: AppColors.textMuted, size: 20),
            inputFormatters: [
              TextInputFormatter.withFunction((oldVal, newVal) {
                final cleaned = newVal.text.replaceAll(
                  RegExp(r'[^\x20-\x7E]'), '');
                if (cleaned == newVal.text) return newVal;
                return newVal.copyWith(
                  text: cleaned,
                  selection: TextSelection.collapsed(offset: cleaned.length));
              }),
              LengthLimitingTextInputFormatter(50),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Name too short';
              return null;
            }),
        const SizedBox(height: 14),
        BrewTextField(label: 'Phone (WhatsApp)', hint: '08xxxxxxxxxx',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined,
                color: AppColors.textMuted, size: 20),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]')),
              LengthLimitingTextInputFormatter(15),
            ]),
        const SizedBox(height: 22),
        BrewButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
      ]));
  }
}

// ── Logout Dialog ─────────────────────────────────────────────────────────────
class _LogoutDialog extends StatelessWidget {
  final AppProvider p;
  const _LogoutDialog({required this.p});
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 60, height: 60,
          decoration: const BoxDecoration(
              color: AppColors.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 28)),
        const SizedBox(height: 14),
        Text('Sign Out?', style: AppTextStyles.displaySmall),
        const SizedBox(height: 7),
        Text('You will need to login again.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.silverGray),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Cancel'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () { Navigator.pop(context); p.logout(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)))),
        ]),
      ])));
}

// ── Guest View ────────────────────────────────────────────────────────────────
class _GuestView extends StatelessWidget {
  const _GuestView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: Column(children: [
      Container(width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 16, 20, 36),
        child: Column(children: [
          Container(width: 84, height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3)),
            child: const Icon(Icons.person_outline_rounded,
                color: Colors.white, size: 42)),
          const SizedBox(height: 14),
          const Text('Not Logged In',
              style: TextStyle(fontFamily: 'Playfair Display',
                  color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Sign in to enjoy all SeedyCoffee features',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.center),
        ])),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          BrewButton(label: 'Login Now',
              onPressed: () => Navigator.pushNamed(
                  context, AppConstants.routeLogin)),
          const SizedBox(height: 10),
          BrewButton(label: 'Create Account',
              style: BrewButtonStyle.outline,
              onPressed: () => Navigator.pushNamed(
                  context, AppConstants.routeLogin)),
        ]))),
    ]));
}

// ── Order History Screen ──────────────────────────────────────────────────────
class _OrderHistoryScreen extends StatelessWidget {
  const _OrderHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final orders = p.userOrders;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white, elevation: 0),
      body: orders.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: AppColors.lightGray),
              const SizedBox(height: 12),
              Text('Belum ada pesanan',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 17)),
              const SizedBox(height: 6),
              Text('Pesanan kamu akan muncul di sini',
                  style: AppTextStyles.bodySmall),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final o = orders[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(
                          order: o, showCode: !o.isPaid))),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: o.isPaid
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.silverGray),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10)]),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: o.isPaid ? AppColors.successBg : AppColors.offWhite,
                          borderRadius: BorderRadius.circular(11)),
                        child: Icon(
                          o.isPaid ? Icons.check_circle_outline_rounded
                              : Icons.access_time_rounded,
                          color: o.isPaid ? AppColors.success : AppColors.midGray,
                          size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(o.orderCode,
                            style: AppTextStyles.labelMedium.copyWith(
                                fontFamily: 'monospace', letterSpacing: 1)),
                        Text(Helpers.formatDate(o.createdAt),
                            style: AppTextStyles.caption),
                        Text(o.items.map((i) => i.menuName).join(', '),
                            style: AppTextStyles.bodySmall,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        Text(Helpers.formatPrice(o.totalAmount),
                            style: AppTextStyles.priceMain.copyWith(fontSize: 13)),
                        Container(margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: o.isPaid ? AppColors.successBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(o.isPaid ? 'Lunas' : 'Pending',
                              style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: o.isPaid
                                      ? AppColors.successText : AppColors.warning))),
                      ]),
                    ])));
              },
            ),
    );
  }
}