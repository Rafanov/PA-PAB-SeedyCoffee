import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/app_provider.dart';
import 'models/user_model.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/main_screen.dart';
import 'screens/user/checkout_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/kasir/kasir_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (EnvConfig.useSupabase) {
    await SupabaseConfig.initialize();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SeedyCoffeeApp());
}

class SeedyCoffeeApp extends StatelessWidget {
  const SeedyCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppConstants.routeSplash,
        routes: {
          AppConstants.routeSplash: (_) => SplashScreen(),
          AppConstants.routeMain:   (_) => MainScreen(),
          AppConstants.routeLogin:  (_) => LoginScreen(),
          AppConstants.routeAdmin:  (_) => AdminScreen(),
          AppConstants.routeKasir:    (_) => KasirScreen(),
          AppConstants.routeCheckout: (_) => CheckoutScreen(),
        },
      ),
    );
  }
}
