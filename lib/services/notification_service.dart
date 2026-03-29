import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _retentionDays = 7;

  Future<List<NotificationModel>> loadForUser(String userId) async {
    if (EnvConfig.useSupabase) {
      try {
        // Load last 7 days only — older are kept in DB but not loaded
        final cutoff = DateTime.now()
            .subtract(const Duration(days: _retentionDays))
            .toIso8601String();
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableNotifications)
            .select()
            .eq('user_id', userId)
            .gte('created_at', cutoff)
            .order('created_at', ascending: false);
        return (res as List).map((e) => NotificationModel.fromSupabase(e)).toList();
      } catch (_) {}
    }
    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('${AppConstants.keyNotifications}_$userId');
    if (raw == null) return [];
    try {
      final all = (jsonDecode(raw) as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      // Keep only last 7 days locally too
      final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
      return all.where((n) => n.createdAt.isAfter(cutoff)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<NotificationModel?> add(NotificationModel notif) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableNotifications)
            .insert(notif.toSupabase())
            .select()
            .single();
        return NotificationModel.fromSupabase(res);
      } catch (_) {}
    }
    // Local fallback — persist to SharedPreferences
    await _addLocal(notif);
    return notif;
  }

  Future<void> _addLocal(NotificationModel notif) async {
    final prefs    = await SharedPreferences.getInstance();
    final key      = '${AppConstants.keyNotifications}_${notif.userId}';
    final raw      = prefs.getString(key);
    final existing = raw != null
        ? (jsonDecode(raw) as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList()
        : <NotificationModel>[];
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    final updated = [notif, ...existing.where((n) => n.createdAt.isAfter(cutoff))];
    await prefs.setString(key,
        jsonEncode(updated.map((n) => n.toJson()).toList()));
  }

  Future<void> broadcastPromo(
      List<String> userIds, String title, String message) async {
    for (final uid in userIds) {
      await add(NotificationModel(
        id: Helpers.generateId('n-'), userId: uid,
        type: NotificationType.promo,
        title: title, message: message,
        isRead: false, createdAt: DateTime.now()));
    }
  }

  Future<void> markAllRead(String userId) async {
    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client
            .from(SupabaseConfig.tableNotifications)
            .update({'is_read': true})
            .eq('user_id', userId)
            .eq('is_read', false);
        return;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final key   = '${AppConstants.keyNotifications}_$userId';
    final raw   = prefs.getString(key);
    if (raw == null) return;
    final notifs = (jsonDecode(raw) as List)
        .map((e) => NotificationModel.fromJson(e))
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await prefs.setString(key,
        jsonEncode(notifs.map((n) => n.toJson()).toList()));
  }

  NotificationModel buildOrderNotif({
    required String userId, required String orderId,
    required String code, required bool isPaid}) =>
    NotificationModel(
      id: Helpers.generateId('n-'), userId: userId,
      type: NotificationType.order,
      title: isPaid ? '✅ Payment Confirmed!' : '⏰ Complete Your Payment',
      message: isPaid
          ? 'Order $orderId has been paid. Your barista is on it! ☕'
          : 'Order $orderId is waiting. Show code $code to cashier.',
      isRead: false, createdAt: DateTime.now());

  NotificationModel buildWelcomeNotif(String userId) => NotificationModel(
    id: Helpers.generateId('n-'), userId: userId,
    type: NotificationType.system,
    title: 'Welcome to SeedyCoffee! ☕',
    message: 'Enjoy premium coffee experience from your fingertips.',
    isRead: false, createdAt: DateTime.now());
}
