// matches public.promo_banners
class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final String? shareText;
  final DateTime? expiresAt;
  final DateTime createdAt;

  // Local-only: for static fallback gradient
  final int gradientIndex;
  final String? imagePath; // local asset path

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.shareText,
    this.expiresAt,
    required this.createdAt,
    this.gradientIndex = 0,
    this.imagePath,
  });

  bool get hasImage => imageUrl.isNotEmpty || imagePath != null;

  factory BannerModel.fromSupabase(Map<String, dynamic> j) => BannerModel(
    id: j['id'], title: j['title'],
    imageUrl: j['image_url'] ?? '',
    isActive: j['is_active'] ?? true,
    sortOrder: j['sort_order'] ?? 0,
    shareText: j['share_text'], 
    expiresAt: j['expires_at'] != null ? DateTime.parse(j['expires_at']) : null,
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()));

  // Static fallback
  factory BannerModel.local({required String id, required String title,
    String imageUrl = '', String? imagePath, int gradientIndex = 0, String shareText = ''}) =>
    BannerModel(id: id, title: title, imageUrl: imageUrl,
      imagePath: imagePath, gradientIndex: gradientIndex,
      shareText: shareText, createdAt: DateTime.now());

  Map<String, dynamic> toSupabase() => {
    'title': title, 'image_url': imageUrl,
    'is_active': isActive, 'sort_order': sortOrder,
    'share_text': shareText,
    'expires_at': expiresAt?.toIso8601String()};

  Map<String, dynamic> toJson() => {...toSupabase(), 'id': id,
    'created_at': createdAt.toIso8601String(),
    'gradient_index': gradientIndex, 'image_path': imagePath};

  factory BannerModel.fromJson(Map<String, dynamic> j) => BannerModel(
    id: j['id'], title: j['title'] ?? '',
    imageUrl: j['image_url'] ?? j['imageUrl'] ?? '',
    isActive: j['is_active'] ?? j['isActive'] ?? true,
    sortOrder: j['sort_order'] ?? j['sortOrder'] ?? 0,
    shareText: j['share_text'] ?? j['shareText'],
    createdAt: DateTime.parse(j['created_at'] ?? j['createdAt'] ?? DateTime.now().toIso8601String()),
    gradientIndex: j['gradient_index'] ?? j['gradientIndex'] ?? 0,
    imagePath: j['image_path'] ?? j['imagePath']);
}
