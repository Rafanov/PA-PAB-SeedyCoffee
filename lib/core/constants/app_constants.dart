class AppConstants {
  AppConstants._();

  static const String appName    = 'SeedyCoffee';
  static const String appTagline = 'Premium Coffee Experience';
  static const String appVersion = '3.0.0';

  // Routes
  static const String routeSplash = '/';
  static const String routeMain     = '/main';
  static const String routeCheckout = '/checkout';
  static const String routeLogin  = '/login';
  static const String routeAdmin  = '/admin';
  static const String routeKasir  = '/kasir';

  // SharedPreferences keys (fallback mode)
  static const String keyCurrentUser   = 'current_user';
  static const String keyUsers         = 'users_db';
  static const String keyMenus         = 'menus_db';
  static const String keyBanners       = 'banners_db';
  static const String keyOrders        = 'orders_db';
  static const String keyNotifications = 'notifications_db';
  static const String keyCart          = 'cart';

  static const List<String> categories = [
    'All', 'Hot Coffee', 'Cold Coffee', 'Milk Coffee', 'Non Coffee', 'Snack',
  ];
}
