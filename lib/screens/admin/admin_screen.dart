import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/app_provider.dart';
import 'admin_menu_tab.dart';
import 'admin_banner_tab.dart';
import 'admin_promo_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_orders_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _State();
}

class _State extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab = TabController(length: 5, vsync: this);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
      backgroundColor: AppColors.brown50,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 0),
          child: Column(children: [
            Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
                clipBehavior: Clip.hardEdge,
                child: Image.asset('assets/images/LogoSeedy.jpg', fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Admin Panel', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
                Text(p.currentUser?.name ?? 'Admin', style: AppTextStyles.headerTitle.copyWith(fontSize: 19)),
              ])),
              GestureDetector(
                onTap: () { p.logout(); Navigator.pushReplacementNamed(context, AppConstants.routeMain); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.3))),
                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 11),
              unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 16), text: 'Menu'),
                Tab(icon: Icon(Icons.image_outlined, size: 16), text: 'Banners'),
                Tab(icon: Icon(Icons.send_outlined, size: 16), text: 'Promo WA'),
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 16), text: 'Dashboard'),
                Tab(icon: Icon(Icons.receipt_long_outlined, size: 16), text: 'Orders'),
              ],
            ),
          ]),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          const AdminMenuTab(), const AdminBannerTab(), const AdminPromoTab(), AdminDashboardTab(), const AdminOrdersTab(),
        ])),
      ]),
    ),
    );
  }
}
