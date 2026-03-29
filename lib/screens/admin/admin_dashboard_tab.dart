import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/ai_service.dart';

enum _Period { today, month, year, all }

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});
  @override
  State<AdminDashboardTab> createState() => _State();
}

class _State extends State<AdminDashboardTab> {
  AiInsight? _insight;
  bool _loadingAi = false;
  _Period _period = _Period.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInsight();
    });
  }



  Future<void> _loadInsight() async {
    if (!mounted) return;
    setState(() => _loadingAi = true);
    final p = context.read<AppProvider>();
    final analytics = AnalyticsService.instance;
    final orders = _filteredOrders(p.allOrders);
    final data = {
      'period':        _period.name,
      'total_orders':  orders.length,
      'paid_orders':   orders.where((o) => o.isPaid).length,
      'total_revenue': orders.where((o) => o.isPaid)
          .fold(0, (s, o) => s + o.totalAmount),
      'weekly_revenue': analytics.getWeeklyRevenue(p.allOrders)
          .map((w) => {'day': w['label'], 'revenue': w['revenue']})
          .toList(),
      'top_menus': analytics.getTopMenus(p.allOrders, p.menus.toList())
          .map((t) => {'name': (t['menu'] as MenuModel).name, 'sold': t['qty']})
          .toList(),
    };
    final insight = await AiService.instance.generateInsight(data);
    if (!mounted) return;
    setState(() { _insight = insight; _loadingAi = false; });
  }

  // ── Filter orders by selected period ─────────────────────────
  List<OrderModel> _filteredOrders(List<OrderModel> all) {
    final now = DateTime.now();
    return switch (_period) {
      _Period.today => all.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).toList(),
      _Period.month => all.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month).toList(),
      _Period.year  => all.where((o) =>
          o.createdAt.year == now.year).toList(),
      _Period.all   => all,
    };
  }

  String get _periodLabel => switch (_period) {
    _Period.today => 'Today',
    _Period.month => 'This Month',
    _Period.year  => 'This Year',
    _Period.all   => 'All Time',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final analytics = AnalyticsService.instance;
    final filtered  = _filteredOrders(p.allOrders);
    final paid      = filtered.where((o) => o.isPaid).toList();
    final revenue   = paid.fold(0, (s, o) => s + o.totalAmount);
    final weekly    = analytics.getWeeklyRevenue(p.allOrders);
    final topMenus  = analytics.getTopMenus(p.allOrders, p.menus.toList());
    final summary   = analytics.getAllTimeSummary(p.allOrders);

    return ListView(padding: const EdgeInsets.all(16), children: [

      // ── Period Filter ─────────────────────────────────────────
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Overview', style: AppTextStyles.displaySmall.copyWith(fontSize: 17)),
        Row(children: [
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async { await context.read<AppProvider>().reloadAllOrders(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: AppColors.brown100,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.brown500))),
        ]),
      ]),
      const SizedBox(height: 10),

      // Period chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _Period.values.map((period) {
          final active = _period == period;
          final label = switch (period) {
            _Period.today => 'Today',
            _Period.month => 'This Month',
            _Period.year  => 'This Year',
            _Period.all   => 'All Time',
          };
          return GestureDetector(
            onTap: () => setState(() => _period = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: active ? null : Border.all(
                    color: AppColors.brown150, width: 1.5),
                boxShadow: active ? [BoxShadow(
                    color: AppColors.brown500.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3))] : null),
              child: Text(label, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary))));
        }).toList()),
      ),
      const SizedBox(height: 14),

      // ── Stats Grid ────────────────────────────────────────────
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _StatCard(
            label: 'Revenue ($_periodLabel)',
            value: Helpers.formatPrice(revenue),
            icon: Icons.attach_money_rounded,
            color: AppColors.success, bg: AppColors.successBg),
          _StatCard(
            label: 'Orders',
            value: '${filtered.length}',
            icon: Icons.receipt_long_outlined,
            color: AppColors.brown500, bg: AppColors.brown100),
          _StatCard(
            label: 'Paid',
            value: '${paid.length}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success, bg: AppColors.successBg),
          _StatCard(
            label: 'Pending',
            value: '${filtered.where((o) => !o.isPaid).length}',
            icon: Icons.access_time_rounded,
            color: AppColors.warning, bg: AppColors.warningBg),
        ]),
      const SizedBox(height: 20),

      // ── Weekly Revenue Chart ──────────────────────────────────
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: AppColors.brown500.withOpacity(0.08), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly Revenue', style: AppTextStyles.labelLarge),
            Text('Last 7 days', style: AppTextStyles.caption),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: weekly.every((w) => w['revenue'] == 0)
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('📊', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text('No paid orders yet',
                        style: AppTextStyles.bodySmall),
                  ]))
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: weekly
                        .map((w) => (w['revenue'] as int).toDouble())
                        .reduce((a, b) => a > b ? a : b) * 1.3,
                    barTouchData: BarTouchData(enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (_, __, rod, ___) =>
                          BarTooltipItem(Helpers.formatPrice(rod.toY.toInt()),
                            const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.w700)))),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 28,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(weekly[v.toInt()]['label'] as String,
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 10))))),
                      leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.brown100, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barGroups: weekly.asMap().entries.map((e) =>
                      BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(
                          toY: (e.value['revenue'] as int).toDouble(),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.brown500, AppColors.brown300]),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)))])).toList()))),
        ])),
      const SizedBox(height: 16),

      // ── Top Menus ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: AppColors.brown500.withOpacity(0.08), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🏆 Top Selling Menu', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          topMenus.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No sales data yet',
                      style: AppTextStyles.bodySmall)))
              : Column(children: topMenus.asMap().entries.map((e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: e.key == 0 ? const Color(0xFFFFD700)
                              : e.key == 1 ? const Color(0xFFC0C0C0)
                              : e.key == 2 ? const Color(0xFFCD7F32)
                              : AppColors.brown100,
                          shape: BoxShape.circle),
                        child: Center(child: Text('${e.key + 1}',
                            style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: e.key < 3
                                  ? Colors.white : AppColors.brown500)))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                          (e.value['menu'] as MenuModel).name,
                          style: AppTextStyles.labelMedium,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${e.value['qty']} sold',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.brown500,
                              fontWeight: FontWeight.w700)),
                    ]))).toList()),
        ])),
      const SizedBox(height: 16),

      // ── All-Time Summary ──────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('All-Time Summary',
              style: AppTextStyles.headerTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 14),
          Row(children: [
            _MiniStat('Revenue', Helpers.formatPrice(summary['totalRevenue'])),
            _vd(),
            _MiniStat('Orders', '${summary['totalOrders']}'),
            _vd(),
            _MiniStat('Avg. Order', Helpers.formatPrice(summary['avgOrderValue'])),
          ]),
        ])),
      const SizedBox(height: 20),

      // ── AI Insight ────────────────────────────────────────────
      _AiInsightCard(
        insight: _insight,
        isLoading: _loadingAi,
        onRefresh: _loadInsight),
      const SizedBox(height: 24),
    ]);
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: AppColors.brown500.withOpacity(0.07), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: bg,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 17)),
      const Spacer(),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(value,
            style: AppTextStyles.priceLarge.copyWith(
                fontSize: 17, color: color),
            maxLines: 1)),
      Text(label, style: AppTextStyles.caption,
          maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Mini Stat (All-Time row) ──────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    FittedBox(fit: BoxFit.scaleDown, child: Text(value,
        style: const TextStyle(color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.w800), maxLines: 1)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(
        color: Colors.white.withOpacity(0.7), fontSize: 10),
        maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));
}

Widget _vd() => Container(width: 1, height: 32,
    color: Colors.white.withOpacity(0.25));

// ── AI Insight Card ───────────────────────────────────────────────────────────
class _AiInsightCard extends StatelessWidget {
  final AiInsight? insight;
  final bool isLoading;
  final VoidCallback onRefresh;
  const _AiInsightCard({required this.insight,
      required this.isLoading, required this.onRefresh});

  Color get _sentimentColor => switch (insight?.sentiment ?? 'neutral') {
    'positive' => AppColors.success,
    'negative' => AppColors.error,
    _          => AppColors.brown500,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: AppColors.brown500.withOpacity(0.08), blurRadius: 16)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.brown500),
          const SizedBox(width: 8),
          Text('AI Insight', style: AppTextStyles.labelLarge),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
            child: const Text('Gemini', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.successText))),
        ]),
        GestureDetector(onTap: isLoading ? null : onRefresh,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.brown100,
                borderRadius: BorderRadius.circular(10)),
            child: isLoading
                ? const Padding(padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppColors.brown500))
                : const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.brown500))),
      ]),
      const SizedBox(height: 14),

      if (isLoading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(
              color: AppColors.brown500, strokeWidth: 2)))
      else if (insight != null) ...[
        // Summary
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.cream,
              borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 8, height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                  color: _sentimentColor, shape: BoxShape.circle)),
            Expanded(child: Text(insight!.summary,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5))),
          ])),
        const SizedBox(height: 12),

        // Highlights
        Text('Highlights', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        ...insight!.highlights.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•', style: TextStyle(
                color: AppColors.brown500, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Expanded(child: Text(h,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4))),
          ]))),
        const SizedBox(height: 12),

        // Recommendations
        Text('Recommendations', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        ...insight!.recommendations.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.brown50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brown150)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: AppColors.brown400),
              const SizedBox(width: 8),
              Expanded(child: Text(r,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.4))),
            ])))),
        const SizedBox(height: 10),

        // Prediction
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brown100,
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Text('🔮', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(insight!.prediction,
                style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic, height: 1.4))),
          ])),
      ],
    ]),
  );
}
