class CartItemModel {
  final String menuItemId;
  final String menuName;
  final String? menuImageUrl;
  final String? size;
  final String? sugar;
  final String? ice;
  final String notes;
  final int quantity;
  final int unitPrice;

  const CartItemModel({
    required this.menuItemId,
    required this.menuName,
    this.menuImageUrl,
    this.size, this.sugar, this.ice,
    this.notes = '',
    required this.quantity,
    required this.unitPrice,
  });

  // Legacy getters
  String get menuId    => menuItemId;
  String get menuEmoji => '☕';
  int get qty          => quantity;
  int get price        => unitPrice;
  int get subtotal     => unitPrice * quantity;
  String get description => notes;

  String get customizationText {
    final p = <String>[];
    if (size != null)  p.add(size!);
    if (sugar != null) p.add(sugar!);
    if (ice != null)   p.add(ice!);
    return p.join(' · ');
  }

  String get fullNotes {
    final parts = <String>[];
    if (customizationText.isNotEmpty) parts.add(customizationText);
    if (notes.isNotEmpty) parts.add(notes);
    return parts.join(' | ');
  }

  CartItemModel copyWith({int? quantity}) => CartItemModel(
    menuItemId: menuItemId, menuName: menuName, menuImageUrl: menuImageUrl,
    size: size, sugar: sugar, ice: ice, notes: notes,
    quantity: quantity ?? this.quantity, unitPrice: unitPrice);

  Map<String, dynamic> toJson() => {
    'menu_item_id': menuItemId, 'menu_name': menuName,
    'menu_image_url': menuImageUrl, 'size': size, 'sugar': sugar, 'ice': ice,
    'notes': notes, 'quantity': quantity, 'unit_price': unitPrice};

  factory CartItemModel.fromJson(Map<String, dynamic> j) => CartItemModel(
    menuItemId: j['menu_item_id'] ?? j['menuItemId'] ?? j['menuId'] ?? '',
    menuName: j['menu_name'] ?? j['menuName'] ?? '',
    menuImageUrl: j['menu_image_url'] ?? j['menuImageUrl'],
    size: j['size'], sugar: j['sugar'], ice: j['ice'],
    notes: j['notes'] ?? j['description'] ?? '',
    quantity: j['quantity'] ?? j['qty'] ?? 1,
    unitPrice: (j['unit_price'] ?? j['unitPrice'] ?? j['price'] ?? 0 as num).toInt());
}
