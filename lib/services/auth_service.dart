import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'static_database.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Load all profiles ────────────────────────────────────────
  Future<List<UserModel>> loadUsers() async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from(SupabaseConfig.tableProfiles)
            .select();
        return (res as List).map((e) => UserModel.fromSupabase(e)).toList();
      } catch (e) {
        debugPrint('loadUsers error: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUsers);
    if (raw != null) {
      try {
        return (jsonDecode(raw) as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
      } catch (_) {}
    }
    return StaticDatabase.seedUsers;
  }

  // ── Sign Up + OTP ────────────────────────────────────────────
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (email.trim().isEmpty)    return 'Email is required';
    if (password.length < 6)     return 'Password min. 6 characters';
    if (fullName.trim().isEmpty) return 'Full name is required';

    if (EnvConfig.useSupabase) {
      try {
        // Check if email already confirmed in DB before attempting signUp
        try {
          final statusRes = await SupabaseConfig.client
              .rpc('check_email_status', params: {'p_email': email.trim()});
          if (statusRes != null) {
            final exists = statusRes['exists'] == true;
            final confirmed = statusRes['confirmed'] == true;
            if (exists && confirmed) {
              return 'Email sudah terdaftar dan terverifikasi. Silakan login.';
            }
            // If exists but not confirmed → allow re-register (will update profile)
          }
        } catch (_) {}

        final res = await SupabaseConfig.client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim(), 'phone': phone.trim()},
        );
        if (res.user == null) return 'Registration failed';
        try {
          // Upsert so re-registering with same email updates profile data
          await SupabaseConfig.client
              .from(SupabaseConfig.tableProfiles)
              .upsert({
            'id':        res.user!.id,
            'full_name': fullName.trim(),
            'email':     email.trim(),
            'role':      'customer',
            'phone':     phone.trim().isEmpty ? null : phone.trim(),
          }, onConflict: 'id');
        } catch (_) {}
        return null;
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already registered') || msg.contains('user already registered')) {
          return 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
        }
        if (msg.contains('invalid email')) {
          return 'Format email tidak valid.';
        }
        if (msg.contains('weak password') || msg.contains('password')) {
          return 'Password terlalu lemah. Min. 6 karakter.';
        }
        return 'Pendaftaran gagal: ' + e.message;
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (err.contains('socketexception') || err.contains('failed host lookup') ||
            err.contains('network') || err.contains('connection')) {
          return 'Tidak ada koneksi internet. Periksa WiFi atau data seluler.';
        }
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      }
    }
    return null;
  }

  // ── Verify OTP ───────────────────────────────────────────────
  Future<(UserModel?, String?)> verifyOtp(String email, String token) async {
    if (!EnvConfig.useSupabase) return (null, 'Supabase not configured');
    try {
      final res = await SupabaseConfig.client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );
      if (res.user == null) return (null, 'Invalid or expired OTP');
      final profile = await _fetchProfile(res.user!.id, res.user!.email);
      if (profile == null) return (null, 'Profile not found');
      await _persistSession(profile);
      return (profile, null);
    } on AuthException catch (e) {
      return (null, e.message);
    } catch (e) {
      return (null, e.toString());
    }
  }

  // ── Sign In ──────────────────────────────────────────────────
  Future<(UserModel?, String?)> signIn(
      String email, String password) async {
    if (EnvConfig.useSupabase) {
      try {
        final res = await SupabaseConfig.client.auth
            .signInWithPassword(email: email.trim(), password: password);
        if (res.user == null) return (null, 'Login failed');
        final profile = await _fetchProfile(res.user!.id, res.user!.email);
        if (profile == null) return (null, 'Profile not found. Contact admin.');
        await _persistSession(profile);
        return (profile, null);
      } on AuthException catch (e) {
        return (null, e.message);
      } catch (e) {
        return (null, e.toString());
      }
    }

    // Demo fallback
    const demoPwd = {
      'customer@breworder.com': 'Test123!',
      'admin@breworder.com':    'Test123!',
      'kasir@breworder.com':   'Test123!',
    };
    final users = await loadUsers();
    try {
      final user = users.firstWhere(
          (u) => u.email == email.trim() || u.username == email.trim());
      final expected = demoPwd[user.email ?? ''];
      if (expected != null && password != expected) {
        return (null, 'Email or password incorrect');
      }
      await _persistSession(user);
      return (user, null);
    } catch (_) {
      return (null, 'Email or password incorrect');
    }
  }

  // ── Resend OTP ───────────────────────────────────────────────
  Future<String?> resendOtp(String email) async {
    if (!EnvConfig.useSupabase) return 'Supabase not configured';
    try {
      await SupabaseConfig.client.auth
          .resend(type: OtpType.signup, email: email.trim());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Update Profile ───────────────────────────────────────────
  Future<(UserModel?, String?)> updateProfile(
      UserModel user,
      {String? newFullName, String? newPhone}) async {
    final updated = user.copyWith(
        fullName: newFullName, phone: newPhone);

    // ALWAYS persist locally first — survives regardless of Supabase
    await _persistSession(updated);

    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client
            .from(SupabaseConfig.tableProfiles)
            .update({
          'full_name': updated.fullName,
          'phone': updated.phone,
        }).eq('id', updated.id);
        debugPrint('Profile updated in Supabase: ${updated.fullName}');
      } catch (e) {
        debugPrint('Profile Supabase update failed (local saved): $e');
      }
    }
    return (updated, null);
  }

  // ── Update Avatar ────────────────────────────────────────────
  Future<(UserModel?, String?)> updateAvatar(
      UserModel user, String avatarUrl) async {
    final updated = user.copyWith(avatarUrl: avatarUrl);
    await _persistSession(updated);

    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client
            .from(SupabaseConfig.tableProfiles)
            .update({'avatar_url': avatarUrl}).eq('id', user.id);
      } catch (e) {
        debugPrint('Avatar Supabase update failed (local saved): $e');
      }
    }
    return (updated, null);
  }

  // ── Restore Session ──────────────────────────────────────────
  // Priority: local SharedPrefs (has latest edits) → Supabase DB
  Future<UserModel?> restoreSession() async {
    // 1. Try local first (has latest profile edits)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyCurrentUser);
    if (raw != null) {
      try {
        final local = UserModel.fromJsonString(raw);
        // Verify Supabase session still valid if using Supabase
        if (EnvConfig.useSupabase) {
          final session = SupabaseConfig.client.auth.currentSession;
          if (session == null) {
            // Session expired — clear local
            await prefs.remove(AppConstants.keyCurrentUser);
            return null;
          }
          // Merge: use local data but verify user id matches session
          if (session.user.id == local.id) {
            return local; // Return local copy (has latest edits)
          }
        }
        return local;
      } catch (_) {}
    }

    // 2. Fallback: fetch from Supabase
    if (EnvConfig.useSupabase) {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        final profile =
            await _fetchProfile(session.user.id, session.user.email);
        if (profile != null) await _persistSession(profile);
        return profile;
      }
    }
    return null;
  }

  // ── Password Reset ──────────────────────────────────────────
  Future<String?> sendPasswordReset(String email) async {
    if (!EnvConfig.useSupabase) return 'Supabase not configured';
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit') || e.statusCode == '429') {
        return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
      }
      return 'Gagal mengirim reset link: ' + e.message;
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('socketexception') || err.contains('failed host lookup')) {
        return 'Tidak ada koneksi internet.';
      }
      if (err.contains('rate_limit') || err.contains('429')) {
        return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
      }
      return 'Gagal mengirim reset link. Coba lagi nanti.';
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    if (EnvConfig.useSupabase) {
      try {
        await SupabaseConfig.client.auth.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyCurrentUser);
    await prefs.remove(AppConstants.keyCart);
  }

  // ── Public persist (for provider) ───────────────────────────
  Future<void> persistSessionPublic(UserModel user) =>
      _persistSession(user);

  // ── Private helpers ──────────────────────────────────────────
  Future<UserModel?> _fetchProfile(String uid, String? email) async {
    try {
      final res = await SupabaseConfig.client
          .from(SupabaseConfig.tableProfiles)
          .select()
          .eq('id', uid)
          .single();
      return UserModel.fromSupabase({...res, 'email': email});
    } catch (e) {
      debugPrint('_fetchProfile error: $e');
      return null;
    }
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentUser, user.toJsonString());
  }
}