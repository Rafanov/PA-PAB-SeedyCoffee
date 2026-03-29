import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'static_database.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  Future<List<OrderModel>> loadOrders({String? userId}) async {
    if (EnvConfig.useSupabase) {
      try {
        // Fix: build query with filter BEFORE select to avoid chaining issue
        List<Map<String, dynamic>> res;
        if (userId != null) {
          res = await SupabaseConfig.client
              .from(SupabaseConfig.tableOrders)
              .select('*, order_items(*, menu_items(name, image_url))')
              .eq('user_id', userId)
              .order('created_at', ascending: false);
        } else {
          res = await SupabaseConfig.client
              .from(SupabaseConfig.tableOrders)
              .select('*, order_items(*, menu_items(name, image_url))')
              .order('created_at', ascending: false);
        }
        return res.map((e) => OrderModel.fromSupabase(e)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyOrders);
    if (raw != null) {
      return (jsonDecode(raw) as List).map((e) => OrderModel.fromJson(e)).toList();
    }
    return StaticDatabase.seedOrders;
  }

  Future<(OrderModel?, String?)> createOrder(
      String userId, List<CartItemModel> cart, int total) async {
    final code = Helpers.generateUniqueCode();
    if (EnvConfig.useSupabase) {
      try {
        final orderRes = await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .insert({
              'user_id': userId,
              'order_code': code,
              'status': 'pending',
              'total_amount': total,
            })
            .select()
            .single();

        final orderId = orderRes['id'] as String;

        for (final item in cart) {
          await SupabaseConfig.client
              .from(SupabaseConfig.tableOrderItems)
              .insert({
                'order_id': orderId,
                'menu_item_id': item.menuItemId,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'notes': item.fullNotes.isEmpty ? null : item.fullNotes,
              });
        }

        final fullRes = await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .select('*, order_items(*, menu_items(name, image_url))')
            .eq('id', orderId)
            .single();

        return (OrderModel.fromSupabase(fullRes), null);
      } catch (e) { return (null, e.toString()); }
    }

    // Local fallback
    final order = OrderModel(
      id: Helpers.generateId('ord-'),
      userId: userId,
      orderCode: code,
      status: OrderStatus.pending,
      totalAmount: total,
      createdAt: DateTime.now(),
      items: cart.map((c) => OrderItemModel(
        menuItemId: c.menuItemId,
        menuName: c.menuName,
        menuImageUrl: c.menuImageUrl,
        quantity: c.quantity,
        unitPrice: c.unitPrice,
        notes: c.fullNotes.isEmpty ? null : c.fullNotes,
      )).toList(),
    );
    final orders = await loadOrders(userId: userId);
    await _save([...orders, order]);
    return (order, null);
  }

  Future<(OrderModel?, String?)> confirmPayment(
      String code, String cashierId) async {
    if (EnvConfig.useSupabase) {
      try {
        final orderRes = await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .select()
            .eq('order_code', code.trim().toUpperCase())
            .eq('status', 'pending')
            .single();

        final orderId = orderRes['id'] as String;

        await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .update({
              'status': 'confirmed',
              'confirmed_by': cashierId,
              'confirmed_at': DateTime.now().toIso8601String(),
            }).eq('id', orderId);

        await SupabaseConfig.client
            .from(SupabaseConfig.tablePayments)
            .insert({
              'order_id': orderId,
              'method': 'cash',
              'amount_paid': orderRes['total_amount'],
              'status': 'completed',
              'processed_by': cashierId,
            });

        final fullRes = await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .select('*, order_items(*, menu_items(name, image_url))')
            .eq('id', orderId)
            .single();

        return (OrderModel.fromSupabase(fullRes), null);
      } catch (e) { return (null, e.toString()); }
    }

    // Local fallback
    final orders = await loadOrders();
    final idx = orders.indexWhere(
        (o) => o.orderCode == code.trim().toUpperCase());
    if (idx == -1) return (null, 'Order not found');
    final updated = orders[idx].copyWith(
      status: OrderStatus.confirmed,
      confirmedBy: cashierId,
      confirmedAt: DateTime.now());
    orders[idx] = updated;
    await _save(orders);
    return (updated, null);
  }

  Future<OrderModel?> findByCode(String code) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableOrders)
            .select('*, order_items(*, menu_items(name, image_url))')
            .eq('order_code', code.trim().toUpperCase())
            .single();
        return OrderModel.fromSupabase(res);
      } catch (_) { return null; }
    }
    final orders = await loadOrders();
    try {
      return orders.firstWhere(
          (o) => o.orderCode == code.trim().toUpperCase());
    } catch (_) { return null; }
  }

  Future<void> _save(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyOrders,
        jsonEncode(orders.map((o) => o.toJson()).toList()));
  }
}
