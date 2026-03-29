import '../models/order_model.dart';
import '../models/menu_model.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Map<String, dynamic> getDailyStats(List<OrderModel> orders) {
    final today = DateTime.now();
    final todayOrders = orders.where((o) =>
        o.createdAt.year == today.year &&
        o.createdAt.month == today.month &&
        o.createdAt.day == today.day).toList();
    final paid = todayOrders.where((o) => o.isPaid).toList();
    return {
      'totalOrders':   todayOrders.length,
      'paidOrders':    paid.length,
      'pendingOrders': todayOrders.where((o) => !o.isPaid).length,
      'revenue':       paid.fold(0, (s, o) => s + o.totalAmount),
    };
  }

  List<Map<String, dynamic>> getWeeklyRevenue(List<OrderModel> orders) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayOrders = orders.where((o) =>
          o.isPaid &&
          o.createdAt.year == day.year &&
          o.createdAt.month == day.month &&
          o.createdAt.day == day.day).toList();
      return {
        'date':    day,
        'label':   _dayLabel(day),
        'revenue': dayOrders.fold(0, (s, o) => s + o.totalAmount),
        'count':   dayOrders.length,
      };
    });
  }

  List<Map<String, dynamic>> getTopMenus(
      List<OrderModel> orders, List<MenuModel> menus, {int limit = 5}) {
    // Fix: use menuItemId instead of menuId
    final counts = <String, int>{};
    for (final o in orders.where((o) => o.isPaid)) {
      for (final item in o.items) {
        counts[item.menuItemId] = (counts[item.menuItemId] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      // Fix: MenuModel uses categoryId/categoryName, not 'category'
      final menu = menus.firstWhere(
        (m) => m.id == e.key,
        orElse: () => MenuModel(
          id: e.key,
          categoryId: '',
          categoryName: 'Unknown',
          name: 'Unknown Menu',
          price: 0,
        ),
      );
      return {'menu': menu, 'qty': e.value};
    }).toList();
  }

  Map<String, int> getCategoryRevenue(
      List<OrderModel> orders, List<MenuModel> menus) {
    final result = <String, int>{};
    for (final o in orders.where((o) => o.isPaid)) {
      for (final item in o.items) {
        // Fix: use menuItemId
        final menu = menus.firstWhere(
          (m) => m.id == item.menuItemId,
          orElse: () => MenuModel(
            id: '', categoryId: '',
            categoryName: 'Other',
            name: '', price: 0,
          ),
        );
        final cat = menu.categoryName.isEmpty ? 'Other' : menu.categoryName;
        result[cat] = (result[cat] ?? 0) + item.subtotal;
      }
    }
    return result;
  }

  Map<int, int> getPeakHours(List<OrderModel> orders) {
    final result = <int, int>{};
    for (final o in orders.where((o) => o.isPaid)) {
      final h = o.createdAt.hour;
      result[h] = (result[h] ?? 0) + 1;
    }
    return result;
  }

  Map<String, dynamic> getAllTimeSummary(List<OrderModel> orders) {
    final paid = orders.where((o) => o.isPaid).toList();
    final totalRev = paid.fold(0, (s, o) => s + o.totalAmount);
    return {
      'totalOrders':   orders.length,
      'paidOrders':    paid.length,
      'totalRevenue':  totalRev,
      'avgOrderValue': paid.isEmpty ? 0 : totalRev ~/ paid.length,
    };
  }

  String _dayLabel(DateTime d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[d.weekday - 1];
  }
}
