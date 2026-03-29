import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../models/user_model.dart';
import '../models/menu_model.dart';
import '../models/banner_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../models/cart_item_model.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/banner_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  UserModel?              _currentUser;
  List<UserModel>         _users         = [];
  List<MenuModel>         _menus         = [];
  List<CategoryModel>     _categories    = [];
  List<BannerModel>       _banners       = [];
  List<OrderModel>        _orders        = [];
  List<NotificationModel> _notifications = [];
  List<CartItemModel>     _cart          = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel?          get currentUser   => _currentUser;
  List<UserModel>     get users         => List.unmodifiable(_users);
  List<MenuModel>     get menus         => List.unmodifiable(_menus);
  List<CategoryModel> get categories    => List.unmodifiable(_categories);
  List<BannerModel>   get banners       => List.unmodifiable(_banners);
  List<CartItemModel> get cart          => List.unmodifiable(_cart);
  List<OrderModel>    get allOrders     => List.unmodifiable(_orders);

  // Force reload all orders (used by admin dashboard)
  Future<void> reloadAllOrders() async {
    try {
      _orders = await OrderService.instance.loadOrders(userId: null);
      notifyListeners();
    } catch (e) {
      debugPrint('reloadAllOrders error: \$e');
    }
  }
  bool get isLoading     => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn    => _currentUser != null;
  int  get cartItemCount => _cart.fold(0, (s, i) => s + i.quantity);
  int  get cartTotal     => _cart.fold(0, (s, i) => s + i.subtotal);
  int  get unreadNotifCount => userNotifications.where((n) => !n.isRead).length;

  // All users with phone — for WA promo broadcast
  int get promoRecipientCount =>
    _users.where((u) => u.role == UserRole.customer &&
        u.phone != null && u.phone!.isNotEmpty).length;

  List<OrderModel> get userOrders {
    if (_currentUser == null) return [];
    return _orders
        .where((o) => o.userId == _currentUser!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<NotificationModel> get userNotifications {
    if (_currentUser == null) return [];
    return _notifications
        .where((n) => n.userId == _currentUser!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<MenuModel> filteredMenus(String category, String query) =>
      MenuService.instance.filter(_menus, category, query);

  // ── Init ──────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();
    try {
      // Load public data + session in parallel
      final results = await Future.wait([
        MenuService.instance.loadCategories(),
        MenuService.instance.loadMenus(),
        BannerService.instance.loadBanners(),
        AuthService.instance.loadUsers(),
        AuthService.instance.restoreSession(),
        _loadCart(),
      ]);
      _categories  = results[0] as List<CategoryModel>;
      _menus       = results[1] as List<MenuModel>;
      _banners     = results[2] as List<BannerModel>;
      _users       = results[3] as List<UserModel>;
      _currentUser = results[4] as UserModel?;
      _cart        = results[5] as List<CartItemModel>;

      if (_currentUser != null) {
        final isStaff = _currentUser!.role == UserRole.admin ||
            _currentUser!.role == UserRole.cashier;
        // Load orders + notifications in parallel
        final userResults = await Future.wait([
          OrderService.instance.loadOrders(
              userId: isStaff ? null : _currentUser!.id),
          NotificationService.instance.loadForUser(_currentUser!.id),
        ]);
        _orders        = userResults[0] as List<OrderModel>;
        _notifications = userResults[1] as List<NotificationModel>;
      }
    } catch (e) { debugPrint('AppProvider init error: \$e'); }
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    final (user, error) = await AuthService.instance.signIn(email, password);
    if (error != null) return error;
    _currentUser = user;
    await _loadUserData();
    notifyListeners();
    return null;
  }

  // Returns null on success (OTP sent), error string on failure
  Future<String?> register(String email, String password,
      String fullName, String phone) async {
    return await AuthService.instance.signUp(
      email: email, password: password,
      fullName: fullName, phone: phone);
  }

  // Verify OTP — returns null on success, error on failure
  Future<String?> verifyOtp(String email, String token) async {
    final (user, error) = await AuthService.instance.verifyOtp(email, token);
    if (error != null) return error;
    _currentUser = user;
    // Add welcome notification
    if (user != null) {
      final notif = await NotificationService.instance.add(
        NotificationService.instance.buildWelcomeNotif(user.id));
      if (notif != null) _notifications = [notif, ..._notifications];
    }
    await _loadUserData();
    notifyListeners();
    return null;
  }

  Future<String?> resendOtp(String email) async =>
      AuthService.instance.resendOtp(email);

  Future<void> sendPasswordReset(String email) async =>
      AuthService.instance.sendPasswordReset(email);

  Future<void> logout() async {
    await AuthService.instance.signOut();
    _currentUser = null;
    _cart = [];
    _orders = [];
    _notifications = [];
    notifyListeners();
  }

  Future<String?> updateProfile({String? fullName, String? phone}) async {
    if (_currentUser == null) return 'Not logged in';
    final (updated, error) = await AuthService.instance.updateProfile(
      _currentUser!, newFullName: fullName, newPhone: phone);
    if (error != null) return error;
    _currentUser = updated;
    _users = _users.map((u) => u.id == updated!.id ? updated : u).toList();
    // Also persist locally so it survives app restart
    await AuthService.instance.persistSessionPublic(updated!);
    notifyListeners();
    return null;
  }

  Future<String?> updateAvatar(String avatarUrl) async {
    if (_currentUser == null) return 'Not logged in';
    final (updated, error) = await AuthService.instance.updateAvatar(
      _currentUser!, avatarUrl);
    if (error != null) return error;
    _currentUser = updated;
    notifyListeners();
    return null;
  }

  // ── Cart ──────────────────────────────────────────────────────
  void addToCart(CartItemModel item) {
    final existing = _cart
        .where((c) => c.menuItemId == item.menuItemId)
        .fold(0, (s, c) => s + c.quantity);
    if (existing + item.quantity > 10) return;
    _cart = [..._cart, item];
    _saveCart();
    notifyListeners();
  }

  bool canAddToCart(String menuItemId, int qty) {
    final existing = _cart
        .where((c) => c.menuItemId == menuItemId)
        .fold(0, (s, c) => s + c.quantity);
    return existing + qty <= 10;
  }

  void removeFromCart(int index) {
    final list = [..._cart];
    list.removeAt(index);
    _cart = list;
    _saveCart();
    notifyListeners();
  }

  void updateCartQty(int index, int qty) {
    if (qty <= 0) { removeFromCart(index); return; }
    final list = [..._cart];
    list[index] = list[index].copyWith(quantity: qty);
    _cart = list;
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    _saveCart();
    notifyListeners();
  }

  // ── Orders ────────────────────────────────────────────────────
  Future<OrderModel> checkout() async {
    final (order, error) = await OrderService.instance.createOrder(
      _currentUser!.id, _cart, cartTotal);
    if (error != null || order == null) throw Exception(error ?? 'Checkout failed');
    _orders = [order, ..._orders];
    clearCart();
    final notif = await NotificationService.instance.add(
      NotificationService.instance.buildOrderNotif(
        userId: _currentUser!.id, orderId: order.id,
        code: order.orderCode, isPaid: false));
    if (notif != null) _notifications = [notif, ..._notifications];
    notifyListeners();
    return order;
  }

  Future<OrderModel?> confirmPayment(String code) async {
    if (_currentUser == null) return null;
    final (updated, _) = await OrderService.instance
        .confirmPayment(code, _currentUser!.id);
    if (updated == null) return null;
    _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList();
    // Notify the order's owner
    final notif = await NotificationService.instance.add(
      NotificationService.instance.buildOrderNotif(
        userId: updated.userId, orderId: updated.id,
        code: updated.orderCode, isPaid: true));
    if (notif != null) _notifications = [notif, ..._notifications];
    notifyListeners();
    return updated;
  }

  Future<OrderModel?> findOrderByCode(String code) =>
      OrderService.instance.findByCode(code);

  // ── Notifications ─────────────────────────────────────────────
  Future<void> markAllNotifsRead() async {
    if (_currentUser == null) return;
    await NotificationService.instance.markAllRead(_currentUser!.id);
    _notifications = _notifications.map((n) =>
      n.userId == _currentUser!.id ? n.copyWith(isRead: true) : n).toList();
    notifyListeners();
  }

  Future<void> sendPromoNotification(String message) async {
    final recipients = _users.where((u) =>
      u.role == UserRole.customer && u.phone != null && u.phone!.isNotEmpty).toList();
    await NotificationService.instance.broadcastPromo(
      recipients.map((u) => u.id).toList(),
      'Promo from SeedyCoffee! 📢', message);
    // Refresh local notifications if current user is a customer
    if (_currentUser?.role == UserRole.customer) {
      _notifications = await NotificationService.instance
          .loadForUser(_currentUser!.id);
    }
    notifyListeners();
  }

  // ── Admin: Menus ──────────────────────────────────────────────
  Future<String?> addMenu(MenuModel menu) async {
    final (created, error) = await MenuService.instance.addMenu(menu);
    if (error != null) return error;
    _menus = [..._menus, created!];
    notifyListeners();
    return null;
  }

  Future<String?> updateMenu(MenuModel menu) async {
    final (updated, error) = await MenuService.instance.updateMenu(menu);
    if (error != null) return error;
    _menus = _menus.map((m) => m.id == menu.id ? updated! : m).toList();
    notifyListeners();
    return null;
  }

  Future<String?> deleteMenu(String id) async {
    final error = await MenuService.instance.deleteMenu(id);
    if (error != null) return error;
    _menus = _menus.where((m) => m.id != id).toList();
    notifyListeners();
    return null;
  }

  // ── Admin: Banners ────────────────────────────────────────────
  Future<String?> addBanner(BannerModel banner) async {
    final (created, error) = await BannerService.instance.addBanner(banner);
    if (error != null) return error;
    _banners = [..._banners, created!];
    notifyListeners();
    return null;
  }

  Future<String?> deleteBanner(String id) async {
    final error = await BannerService.instance.deleteBanner(id);
    if (error != null) return error;
    _banners = _banners.where((b) => b.id != id).toList();
    notifyListeners();
    return null;
  }

  // ── Categories ────────────────────────────────────────────────
  List<String> get categoryNames =>
    ['All', ..._categories.map((c) => c.name)];

  // ── Private ───────────────────────────────────────────────────
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    // Admin and cashier load ALL orders; customer loads own orders only
    final isStaff = _currentUser!.role == UserRole.admin ||
        _currentUser!.role == UserRole.cashier;
    _orders = await OrderService.instance.loadOrders(
        userId: isStaff ? null : _currentUser!.id);
    _notifications = await NotificationService.instance
        .loadForUser(_currentUser!.id);
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCart,
        jsonEncode(_cart.map((c) => c.toJson()).toList()));
  }

  Future<List<CartItemModel>> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyCart);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CartItemModel.fromJson(e)).toList();
    } catch (_) { return []; }
  }
}
