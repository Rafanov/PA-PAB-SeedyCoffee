import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/menu_model.dart';
import 'static_database.dart';

class MenuService {
  MenuService._();
  static final MenuService instance = MenuService._();

  // ── Realtime stock subscription ──────────────────────────────

  // ── Load categories ──────────────────────────────────────────
  Future<List<CategoryModel>> loadCategories() async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableCategories)
            .select()
            .eq('is_active', true)
            .order('sort_order');
        return (res as List).map((e) => CategoryModel.fromSupabase(e)).toList();
      } catch (_) {}
    }
    return StaticDatabase.seedCategories;
  }

  // ── Load menus ───────────────────────────────────────────────
  Future<List<MenuModel>> loadMenus() async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableMenuItems)
            .select('*, categories(name)')
            .eq('is_deleted', false)
            .order('created_at');
        return (res as List).map((e) => MenuModel.fromSupabase(e)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyMenus);
    if (raw != null) {
      return (jsonDecode(raw) as List).map((e) => MenuModel.fromJson(e)).toList();
    }
    final seed = StaticDatabase.seedMenus;
    await _saveLocal(seed);
    return seed;
  }

  // ── Add menu ─────────────────────────────────────────────────
  Future<(MenuModel?, String?)> addMenu(MenuModel menu) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableMenuItems)
            .insert(menu.toSupabase())
            .select('*, categories(name)')
            .single();
        return (MenuModel.fromSupabase(res), null);
      } catch (e) { return (null, e.toString()); }
    }
    return (menu, null);
  }

  // ── Update menu ──────────────────────────────────────────────
  Future<(MenuModel?, String?)> updateMenu(MenuModel menu) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableMenuItems)
            .update({...menu.toSupabase(), 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', menu.id)
            .select('*, categories(name)')
            .single();
        return (MenuModel.fromSupabase(res), null);
      } catch (e) { return (null, e.toString()); }
    }
    return (menu, null);
  }

  // ── Delete menu (soft delete) ────────────────────────────────
  Future<String?> deleteMenu(String id) async {
    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client
            .from(SupabaseConfig.tableMenuItems)
            .update({'is_deleted': true, 'is_available': false})
            .eq('id', id);
        return null;
      } catch (e) { return e.toString(); }
    }
    return null;
  }

  // ── Filter ───────────────────────────────────────────────────
  List<MenuModel> filter(List<MenuModel> menus, String category, String query) {
    return menus.where((m) {
      final catOk = category == 'All' || m.categoryName == category;
      final qOk   = query.isEmpty ||
          m.name.toLowerCase().contains(query.toLowerCase());
      return catOk && qOk;
    }).toList();
  }

  Future<void> _saveLocal(List<MenuModel> menus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMenus,
        jsonEncode(menus.map((m) => m.toJson()).toList()));
  }
}