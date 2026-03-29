// matches public.orders + public.order_items + public.payments
class OrderItemModel {
  final String id;
  final String menuItemId;
  final String menuName;
  final String? menuImageUrl;
  final int quantity;
  final int unitPrice;
  final String? notes; // includes customizations as text

  const OrderItemModel({
    this.id = '',
    required this.menuItemId,
    required this.menuName,
    this.menuImageUrl,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  // Legacy getters
  int get qty => quantity;
  int get price => unitPrice;
  int get subtotal => unitPrice * quantity;
  String get menuEmoji => '☕';
  String get description => notes ?? '';
  String get customizationSummary => '';

  factory OrderItemModel.fromSupabase(Map<String, dynamic> j) => OrderItemModel(
    id: j['id'] ?? '',
    menuItemId: j['menu_item_id'],
    menuName: (j['menu_items'] as Map<String, dynamic>?)?['name'] ?? j['menu_name'] ?? '',
    menuImageUrl: (j['menu_items'] as Map<String, dynamic>?)?['image_url'],
    quantity: j['quantity'],
    unitPrice: (j['unit_price'] as num).toInt(),
    notes: j['notes']);

  Map<String, dynamic> toSupabase(String orderId) => {
    'order_id': orderId, 'menu_item_id': menuItemId,
    'quantity': quantity, 'unit_price': unitPrice, 'notes': notes};

  Map<String, dynamic> toJson() => {
    'id': id, 'menu_item_id': menuItemId, 'menu_name': menuName,
    'menu_image_url': menuImageUrl, 'quantity': quantity,
    'unit_price': unitPrice, 'notes': notes};

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id: j['id'] ?? '', menuItemId: j['menu_item_id'] ?? j['menuItemId'] ?? '',
    menuName: j['menu_name'] ?? j['menuName'] ?? '',
    menuImageUrl: j['menu_image_url'] ?? j['menuImageUrl'],
    quantity: j['quantity'] ?? j['qty'] ?? 1,
    unitPrice: (j['unit_price'] ?? j['unitPrice'] ?? j['price'] ?? 0 as num).toInt(),
    notes: j['notes'] ?? j['description']);
}

enum OrderStatus { pending, confirmed, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String orderCode;
  final OrderStatus status;
  final int totalAmount;
  final String? notes;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderCode,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.confirmedBy,
    this.confirmedAt,
    required this.createdAt,
    this.items = const [],
  });

  // Legacy getters
  bool get isPaid    => status == OrderStatus.confirmed;
  String get uniqueCode => orderCode;
  int get total => totalAmount;

  String get statusLabel => switch (status) {
    OrderStatus.confirmed  => '✅ Paid',
    OrderStatus.pending    => '⏳ Unpaid',
    OrderStatus.cancelled  => '❌ Cancelled',
  };

  OrderModel copyWith({OrderStatus? status, String? confirmedBy, DateTime? confirmedAt}) =>
    OrderModel(id: id, userId: userId, orderCode: orderCode,
      status: status ?? this.status, totalAmount: totalAmount, notes: notes,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt, items: items);

  factory OrderModel.fromSupabase(Map<String, dynamic> j) => OrderModel(
    id: j['id'], userId: j['user_id'], orderCode: j['order_code'],
    status: OrderStatus.values.firstWhere(
      (s) => s.name == j['status'], orElse: () => OrderStatus.pending),
    totalAmount: (j['total_amount'] as num).toInt(),
    notes: j['notes'], confirmedBy: j['confirmed_by'],
    confirmedAt: j['confirmed_at'] != null ? DateTime.parse(j['confirmed_at']) : null,
    createdAt: DateTime.parse(j['created_at']),
    items: (j['order_items'] as List? ?? [])
        .map((i) => OrderItemModel.fromSupabase(i)).toList());

  Map<String, dynamic> toSupabase() => {
    'user_id': userId, 'order_code': orderCode,
    'status': status.name, 'total_amount': totalAmount, 'notes': notes};

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'order_code': orderCode,
    'status': status.name, 'total_amount': totalAmount, 'notes': notes,
    'confirmed_by': confirmedBy, 'confirmed_at': confirmedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList()};

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? j['order_items'] as List? ?? [])
        .map((i) => OrderItemModel.fromJson(i)).toList();
    return OrderModel(
      id: j['id'], userId: j['user_id'],
      orderCode: j['order_code'] ?? j['orderCode'] ?? j['uniqueCode'] ?? '',
      status: OrderStatus.values.firstWhere(
        (s) => s.name == j['status'], orElse: () => OrderStatus.pending),
      totalAmount: (j['total_amount'] ?? j['totalAmount'] ?? j['total'] ?? 0 as num).toInt(),
      notes: j['notes'],
      confirmedBy: j['confirmed_by'],
      confirmedAt: j['confirmed_at'] != null ? DateTime.parse(j['confirmed_at']) : null,
      createdAt: DateTime.parse(j['created_at'] ?? j['createdAt'] ?? DateTime.now().toIso8601String()),
      items: items);
  }
}
