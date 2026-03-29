import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    if (!EnvConfig.useSupabase) return;
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static bool get isReady => EnvConfig.useSupabase;

  // ── Tables ──────────────────────────────────────────────────────
  static const String tableProfiles      = 'profiles';
  static const String tableMenuItems     = 'menu_items';
  static const String tableCategories    = 'categories';
  static const String tableOrders        = 'orders';
  static const String tableOrderItems    = 'order_items';
  static const String tablePayments      = 'payments';
  static const String tablePromoBanners  = 'promo_banners';
  static const String tableNotifications = 'notifications';

  // ── Storage Buckets ─────────────────────────────────────────────
  static const String bucketMenuImages = 'menu-images';
  static const String bucketBanners    = 'banners';
}
