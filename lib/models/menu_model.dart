// matches public.menu_items + public.categories
class CategoryModel {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({required this.id, required this.name,
    this.sortOrder = 0, this.isActive = true});

  factory CategoryModel.fromSupabase(Map<String, dynamic> j) => CategoryModel(
    id: j['id'], name: j['name'],
    sortOrder: j['sort_order'] ?? 0, isActive: j['is_active'] ?? true);

  Map<String, dynamic> toJson() =>
    {'id': id, 'name': name, 'sort_order': sortOrder, 'is_active': isActive};
}

class MenuModel {
  // ── Menu label constants (admin can assign one) ──────────────
  static const List<String> labels = [
    'Recommended',
    'High Sales', 
    'New Menu',
    'Limited',
    'Chef Special',
  ];


  final String id;
  final String categoryId;
  final String categoryName;  // joined from categories
  final String name;
  final String? description;
  final int price;
  final int? originalPrice;
  final String? imageUrl;
  final bool isAvailable;
  final String? badge;  // menu label: Recommended, High Sales, etc.
  // customizations stored as JSONB: {"sizes":["S","M","L"],"sugars":[...],"ices":[...]}
  final List<String>? sizeOptions;
  final List<String>? sugarOptions;
  final List<String>? iceOptions;

  const MenuModel({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.isAvailable = true,
    this.badge,
    this.sizeOptions,
    this.sugarOptions,
    this.iceOptions,
  });

  // Legacy getter
  String get emoji => '☕';
  String get category => categoryName;

  MenuModel copyWith({
    String? name, String? categoryId, String? categoryName,
    String? description, int? price, int? originalPrice,
    String? imageUrl, bool? isAvailable, String? badge,
    List<String>? sizeOptions, List<String>? sugarOptions, List<String>? iceOptions,
  }) => MenuModel(
    id: id, categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    name: name ?? this.name, description: description ?? this.description,
    price: price ?? this.price, originalPrice: originalPrice ?? this.originalPrice,
    imageUrl: imageUrl ?? this.imageUrl, isAvailable: isAvailable ?? this.isAvailable,
    sizeOptions: sizeOptions ?? this.sizeOptions,
    sugarOptions: sugarOptions ?? this.sugarOptions,
    iceOptions: iceOptions ?? this.iceOptions);

  factory MenuModel.fromSupabase(Map<String, dynamic> j) {
    final custom = j['customizations'] as Map<String, dynamic>? ?? {};
    List<String>? parseList(String key) {
      final v = custom[key];
      if (v == null) return null;
      return (v as List).map((e) => e.toString()).toList();
    }
    return MenuModel(
      id: j['id'], categoryId: j['category_id'] ?? '',
      categoryName: (j['categories'] as Map<String, dynamic>?)?['name'] ?? j['category_name'] ?? '',
      name: j['name'], description: j['description'],
      price: (j['price'] as num).toInt(),
      originalPrice: j['original_price'] != null ? (j['original_price'] as num).toInt() : null,
      imageUrl: j['image_url'], isAvailable: j['is_available'] ?? true,
      badge: j['badge'],
      sizeOptions: parseList('sizes'),
      sugarOptions: parseList('sugars'),
      iceOptions: parseList('ices'));
  }

  Map<String, dynamic> toSupabase() => {
    'category_id': categoryId, 'name': name,
    'description': description, 'price': price,
    'original_price': originalPrice, 'image_url': imageUrl,
    'is_available': isAvailable,
 'badge': badge,
    'customizations': {
      if (sizeOptions != null)  'sizes':  sizeOptions,
      if (sugarOptions != null) 'sugars': sugarOptions,
      if (iceOptions != null)   'ices':   iceOptions,
    }};

  Map<String, dynamic> toJson() => {...toSupabase(), 'id': id, 'category_name': categoryName};
  factory MenuModel.fromJson(Map<String, dynamic> j) => MenuModel.fromSupabase(j);
}
