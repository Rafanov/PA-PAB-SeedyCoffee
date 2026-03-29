import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_provider.dart';
import 'home_tab.dart';
import 'cart_tab.dart';
import 'notification_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _State();
}

class _State extends State<MainScreen> {
  int _idx = 0;
  static const _tabs = [HomeTab(), CartTab(), NotificationTab(), ProfileTab()];

  void _onTap(int i, AppProvider p) {
    if (i > 0 && !p.isLoggedIn) {
      Navigator.pushNamed(context, AppConstants.routeLogin);
      return;
    }
    if (i == 2 && p.unreadNotifCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => p.markAllNotifsRead());
    }
    HapticFeedback.lightImpact();
    setState(() => _idx = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
      backgroundColor: AppColors.brown50,
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: _NavBar(
        idx: _idx,
        cart: p.cartItemCount,
        notif: p.unreadNotifCount,
        onTap: (i) => _onTap(i, p),
      ),
    ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int idx, cart, notif;
  final ValueChanged<int> onTap;
  const _NavBar({required this.idx, required this.cart,
      required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
          color: AppColors.brown900.withOpacity(0.12),
          blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: [
          _T(icon: Icons.coffee_rounded,             label: 'Menu',    i: 0, idx: idx, badge: 0,     onTap: onTap),
          _T(icon: Icons.shopping_bag_outlined,      label: 'Cart',    i: 1, idx: idx, badge: cart,  onTap: onTap),
          _T(icon: Icons.notifications_none_rounded, label: 'Notif',   i: 2, idx: idx, badge: notif, onTap: onTap),
          _T(icon: Icons.person_outline_rounded,     label: 'Profile', i: 3, idx: idx, badge: 0,     onTap: onTap),
        ]),
      ),
    ),
  );
}

class _T extends StatelessWidget {
  final IconData icon;
  final String label;
  final int i, idx, badge;
  final ValueChanged<int> onTap;
  const _T({required this.icon, required this.label, required this.i,
      required this.idx, required this.badge, required this.onTap});

  bool get active => i == idx;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.offWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 24,
                color: active ? AppColors.black : AppColors.textMuted),
            if (badge > 0)
              Positioned(top: -3, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE84545),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w800)))),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.black : AppColors.textMuted,
          )),
        ]),
      ),
    ),
  );
}
