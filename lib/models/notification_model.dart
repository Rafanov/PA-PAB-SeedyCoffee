enum NotificationType { order, promo, system }

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id, required this.userId, required this.type,
    required this.title, required this.message,
    required this.isRead, required this.createdAt,
  });

  // Legacy getter
  String get icon => switch (type) {
    NotificationType.order  => '🧾',
    NotificationType.promo  => '📢',
    NotificationType.system => '☕',
  };

  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    if (d.inDays < 7)     return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id, userId: userId, type: type, title: title,
    message: message, isRead: isRead ?? this.isRead, createdAt: createdAt);

  factory NotificationModel.fromSupabase(Map<String, dynamic> j) => NotificationModel(
    id: j['id'], userId: j['user_id'],
    type: NotificationType.values.firstWhere(
      (t) => t.name == (j['type'] ?? 'system'), orElse: () => NotificationType.system),
    title: j['title'], message: j['message'],
    isRead: j['is_read'] ?? false,
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()));

  Map<String, dynamic> toSupabase() => {
    'user_id': userId, 'type': type.name,
    'title': title, 'message': message, 'is_read': isRead};

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'type': type.name,
    'title': title, 'message': message, 'is_read': isRead,
    'created_at': createdAt.toIso8601String()};

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
    NotificationModel.fromSupabase({...j,
      'is_read': j['is_read'] ?? j['isRead'] ?? false,
      'user_id': j['user_id'] ?? j['userId'],
      'created_at': j['created_at'] ?? j['createdAt'] ?? DateTime.now().toIso8601String()});
}
