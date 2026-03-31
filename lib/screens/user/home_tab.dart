import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/app_provider.dart';
import '../../widgets/menu_card.dart';
import 'menu_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _State();
}

class _State extends State<HomeTab> {
  final _search = TextEditingController();
  final _banner = PageController();
  String _cat = 'All', _q = '';
  int _bIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _q = _search.text));
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final n = context.read<AppProvider>().banners.length;
      if (n < 2) return;
      final next = (_bIdx + 1) % n;
      _banner.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      setState(() => _bIdx = next);
    });
  }

  @override
  void dispose() { _search.dispose(); _banner.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final _raw = p.filteredMenus(_cat, _q);
    final menus = [
      ..._raw.where((m) => m.isAvailable),
      ..._raw.where((m) => !m.isAvailable),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header(p)),
        if (_q.isEmpty && p.banners.isNotEmpty) SliverToBoxAdapter(child: _bannerSlider(p)),
        SliverToBoxAdapter(child: _categories(p)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16,18,16,10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Menu', style: AppTextStyles.displaySmall),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(10)),
              child: Text('${menus.length} items', style: AppTextStyles.caption.copyWith(
                  color: AppColors.black, fontWeight: FontWeight.w700))),
          ]),
        )),
        menus.isEmpty
            ? SliverFillRemaining(child: _empty())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16,0,16,32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => MenuCard(menu: menus[i], onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MenuDetailScreen(menu: menus[i])))),
                    childCount: menus.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68),
                )),
      ]),
    );
  }

  Widget _header(AppProvider p) => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 18),
    child: Column(children: [
      Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3))),
          clipBehavior: Clip.hardEdge,
          child: p.currentUser?.avatarUrl != null && p.currentUser!.avatarUrl!.isNotEmpty
              ? Image.network(p.currentUser!.avatarUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 24))
              : const Icon(Icons.person_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Helpers.greeting, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11, fontWeight: FontWeight.w500)),
          Text(p.currentUser?.name ?? 'Hello, Guest! 👋', style: AppTextStyles.headerTitle.copyWith(fontSize: 18),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Stack(clipBehavior: Clip.none, children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22)),
          if (p.unreadNotifCount > 0) Positioned(top: 0, right: 0,
            child: Container(width: 16, height: 16,
              decoration: const BoxDecoration(color: Color(0xFFE84545), shape: BoxShape.circle),
              child: Center(child: Text('${p.unreadNotifCount > 9 ? '9+' : p.unreadNotifCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))))),
        ]),
      ]),
      const SizedBox(height: 14),
      Container(height: 46,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,4))]),
        child: TextField(controller: _search, style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search your favorite menu...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
            suffixIcon: _q.isNotEmpty ? IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
              onPressed: () { _search.clear(); setState(() => _q = ''); }) : null,
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13), filled: false))),
    ]),
  );

  Widget _bannerSlider(AppProvider p) => Padding(
    padding: const EdgeInsets.fromLTRB(16,16,16,0),
    child: Column(children: [
      SizedBox(height: 148, child: PageView.builder(
        controller: _banner,
        onPageChanged: (i) => setState(() => _bIdx = i),
        itemCount: p.banners.length,
        itemBuilder: (_, i) {
          final b = p.banners[i];
          return Container(margin: const EdgeInsets.symmetric(horizontal: 2),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.brown900.withOpacity(0.25), blurRadius: 20, offset: const Offset(0,6))]),
            child: _buildBannerContent(b));
        },
      )),
      if (p.banners.length > 1) ...[
        const SizedBox(height: 10),
        SmoothPageIndicator(controller: _banner, count: p.banners.length,
          effect: const WormEffect(
            dotColor: AppColors.silverGray,
            activeDotColor: AppColors.black,
            dotHeight: 6,
            dotWidth: 6,
          )),
      ],
    ]),
  );

  Widget _buildBannerContent(dynamic b) {
    if (b.imagePath != null && b.imagePath!.isNotEmpty) return Image.asset(b.imagePath!, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _gradientBanner(b));
    if (b.imageUrl.isNotEmpty) return Image.network(b.imageUrl, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _gradientBanner(b));
    return _gradientBanner(b);
  }

  Widget _gradientBanner(dynamic b) => Container(
    decoration: BoxDecoration(gradient: AppColors.bannerGradients[b.gradientIndex % 3]),
    child: Stack(children: [
      Positioned(right: -10, top: -10, child: const Icon(Icons.local_cafe_rounded, size: 90, color: Color(0x15FFFFFF))),
      Padding(padding: const EdgeInsets.fromLTRB(20,0,85,0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
          const SizedBox(height: 6),
          if (b.shareText != null && b.shareText!.isNotEmpty)
            Text(b.shareText!, style: const TextStyle(fontFamily: 'Playfair Display', color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w700, height: 1.3), maxLines: 2),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text('See Promo', style: TextStyle(color: AppColors.graphite, fontSize: 11, fontWeight: FontWeight.w800))),
        ])),
    ]),
  );

  Widget _categories(AppProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,18,16,10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Categories', style: AppTextStyles.displaySmall),
        GestureDetector(onTap: () => setState(() { _cat = 'All'; _q = ''; _search.clear(); }),
          child: Text('See All', style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.black, fontWeight: FontWeight.w700))),
      ])),
    SizedBox(height: 38, child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: p.categoryNames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = p.categoryNames[i];
        final active = cat == _cat;
        return GestureDetector(onTap: () => setState(() => _cat = cat),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: active ? AppColors.buttonGradient : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: active ? null : Border.all(color: AppColors.silverGray, width: 1.5),
              boxShadow: active ? [BoxShadow(color: AppColors.black.withOpacity(0.30), blurRadius: 10, offset: const Offset(0,3))] : null),
            child: Text(cat, style: TextStyle(fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppColors.textSecondary))));
      },
    )),
  ]);

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.search_rounded, size: 52, color: AppColors.lightGray),
    const SizedBox(height: 12),
    Text('No menu found', style: AppTextStyles.displaySmall.copyWith(fontSize: 17)),
    const SizedBox(height: 6),
    Text('Try a different keyword or category', style: AppTextStyles.bodySmall),
    const SizedBox(height: 16),
    TextButton(onPressed: () => setState(() { _cat = 'All'; _q = ''; _search.clear(); }),
      child: Text('Reset Filter', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700))),
  ]));
}