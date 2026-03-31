import 'package:flutter/material.dart';
import '../../core/config/env_config.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> with TickerProviderStateMixin {
  // Logo: fade in + scale up
  late final AnimationController _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  late final Animation<double> _logoFade =
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
  late final Animation<double> _logoScale = Tween(begin: 0.75, end: 1.0)
      .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

  // Tagline: fade in after logo
  late final AnimationController _tagCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _tagFade =
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut);

  // Progress bar
  late final AnimationController _barCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _run();
  }

  Future<void> _run() async {
    // DEBUG - print env values to console
// DEBUG - print env values to console
    debugPrint('=== ENV CONFIG ===');
    debugPrint('URL empty: ' + EnvConfig.supabaseUrl.isEmpty.toString());
    debugPrint('URL value: ' + EnvConfig.supabaseUrl);
    debugPrint('KEY empty: ' + EnvConfig.supabaseAnonKey.isEmpty.toString());
    debugPrint('KEY starts eyJ: ' +
        EnvConfig.supabaseAnonKey.startsWith('eyJ').toString());
    debugPrint('KEY length: ' + EnvConfig.supabaseAnonKey.length.toString());
    debugPrint('useSupabase: ' + EnvConfig.useSupabase.toString());
    debugPrint('================');
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    _barCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _tagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) _navigate();
  }

  void _navigate() {
    final p = context.read<AppProvider>();
    void nav() {
      if (!mounted) return;
      final role = p.currentUser?.role;
      if (role == UserRole.admin) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppConstants.routeAdmin, (_) => false);
      } else if (role == UserRole.cashier) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppConstants.routeKasir, (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, AppConstants.routeMain, (_) => false);
      }
    }

    p.isInitialized ? nav() : p.initialize().then((_) => nav());
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _tagCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(flex: 2),

          // ── Logo animation ─────────────────────────────────
          ScaleTransition(
            scale: _logoScale,
            child: FadeTransition(
              opacity: _logoFade,
              child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Image.asset(
                    'assets/images/LogoSeedy.jpg',
                    fit: BoxFit.contain,
                  )),
            ),
          ),

          const SizedBox(height: 28),

          // ── Tagline ────────────────────────────────────────
          FadeTransition(
              opacity: _tagFade,
              child: Column(children: [
                Text('AUTHENTIC COFFEE',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500)),
              ])),

          const Spacer(flex: 3),

          // ── Progress bar ───────────────────────────────────
          Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 40),
              child: Column(children: [
                AnimatedBuilder(
                    animation: _barCtrl,
                    builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                            value: _barCtrl.value,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 2))),
                const SizedBox(height: 16),
                Text('Loading...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        letterSpacing: 2)),
              ])),
        ])),
      ));
}
