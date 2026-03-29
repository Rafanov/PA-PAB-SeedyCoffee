import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/banner_model.dart';
import 'static_database.dart';

class BannerService {
  BannerService._();
  static final BannerService instance = BannerService._();

  Future<List<BannerModel>> loadBanners() async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tablePromoBanners)
            .select()
            .eq('is_active', true)
            .order('sort_order');
        return (res as List).map((e) => BannerModel.fromSupabase(e)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyBanners);
    if (raw != null) {
      return (jsonDecode(raw) as List).map((e) => BannerModel.fromJson(e)).toList();
    }
    final seed = StaticDatabase.seedBanners;
    await _save(seed);
    return seed;
  }

  Future<(BannerModel?, String?)> addBanner(BannerModel banner) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tablePromoBanners)
            .insert(banner.toSupabase())
            .select().single();
        return (BannerModel.fromSupabase(res), null);
      } catch (e) { return (null, e.toString()); }
    }
    return (banner, null);
  }

  Future<String?> deleteBanner(String id) async {
    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client
            .from(SupabaseConfig.tablePromoBanners)
            .update({'is_active': false}).eq('id', id);
        return null;
      } catch (e) { return e.toString(); }
    }
    return null;
  }

  Future<void> _save(List<BannerModel> banners) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBanners,
        jsonEncode(banners.map((b) => b.toJson()).toList()));
  }
}
