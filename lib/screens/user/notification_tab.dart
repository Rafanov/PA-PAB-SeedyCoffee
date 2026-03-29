import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/notification_model.dart';
import '../../providers/app_provider.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final notifs = p.userNotifications;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 18),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notifications', style: AppTextStyles.headerTitle),
              const SizedBox(height: 2),
              Text(p.unreadNotifCount > 0 ? '${p.unreadNotifCount} unread' : 'All caught up ✓',
                  style: AppTextStyles.headerSubtitle),
            ])),
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)),
          ]),
        )),

        notifs.isEmpty
          ? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 88, height: 88,
                decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_off_outlined, size: 42, color: AppColors.midGray)),
              const SizedBox(height: 16),
              Text('No Notifications Yet', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Promos & order updates\nwill appear here', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ])))
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final n = notifs[i];
                  final showDate = i == 0 || !_sameDay(notifs[i-1].createdAt, n.createdAt);
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (showDate) _dateSep(n.createdAt),
                    _Card(notif: n),
                    const SizedBox(height: 8),
                  ]);
                },
                childCount: notifs.length,
              ))),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateSep(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    String label;
    if (d == today) label = 'Today';
    else if (d == today.subtract(const Duration(days: 1))) label = 'Yesterday';
    else {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      label = '${dt.day} ${months[dt.month-1]} ${dt.year}';
    }
    return Padding(padding: const EdgeInsets.only(bottom: 10, top: 2), child: Row(children: [
      Expanded(child: Divider(color: AppColors.brown150, thickness: 1)),
      const SizedBox(width: 10),
      Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: AppColors.brown150, thickness: 1)),
    ]));
  }
}

class _Card extends StatelessWidget {
  final NotificationModel notif;
  const _Card({required this.notif});

  Color get _bg => switch(notif.type) {
    NotificationType.order  => const Color(0xFFFFF3E0),
    NotificationType.promo  => const Color(0xFFFCE4EC),
    NotificationType.system => const Color(0xFFE8F5E9),
  };
  IconData get _icon => switch(notif.type) {
    NotificationType.order  => Icons.receipt_long_outlined,
    NotificationType.promo  => Icons.local_offer_outlined,
    NotificationType.system => Icons.info_outline_rounded,
  };
  Color get _iconColor => switch(notif.type) {
    NotificationType.order  => const Color(0xFFE65100),
    NotificationType.promo  => const Color(0xFFC2185B),
    NotificationType.system => const Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    decoration: BoxDecoration(
      color: notif.isRead ? Colors.white : AppColors.offWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: notif.isRead ? AppColors.offWhite : AppColors.brown200,
          width: notif.isRead ? 1.0 : 1.5),
      boxShadow: [BoxShadow(color: AppColors.black.withOpacity(notif.isRead ? 0.05 : 0.10),
          blurRadius: notif.isRead ? 8 : 14, offset: const Offset(0,2))]),
    child: Padding(padding: const EdgeInsets.all(13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(13)),
        child: Center(child: notif.icon.length <= 2
            ? Text(notif.icon, style: const TextStyle(fontSize: 20))
            : Icon(_icon, color: _iconColor, size: 20))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(notif.title, style: AppTextStyles.labelMedium.copyWith(
              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800))),
          if (!notif.isRead) Container(width: 7, height: 7,
            margin: const EdgeInsets.only(top: 3, left: 8),
            decoration: const BoxDecoration(color: AppColors.brown400, shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 3),
        Text(notif.message, style: AppTextStyles.bodySmall.copyWith(height: 1.45)),
        const SizedBox(height: 5),
        Text(notif.timeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.midGray)),
      ])),
    ])),
  );
}
