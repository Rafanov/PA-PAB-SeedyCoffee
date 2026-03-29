import 'dart:convert';

enum UserRole { customer, admin, cashier }

class UserModel {
  final String id;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? email;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.email,
    required this.createdAt,
  });

  // Legacy getters — supaya screens yang pakai .name/.username tidak perlu diubah
  String get name     => fullName;
  String get username => email?.split('@').first ?? fullName.toLowerCase().replaceAll(' ', '_');
  String get avatarEmoji => '👤';

  String get roleLabel => switch (role) {
    UserRole.admin    => 'Admin',
    UserRole.cashier  => 'Cashier',
    UserRole.customer => 'Customer',
  };

  UserModel copyWith({String? fullName, String? phone, String? avatarUrl, String? email}) =>
    UserModel(id: id, fullName: fullName ?? this.fullName, role: role,
      phone: phone ?? this.phone, avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email, createdAt: createdAt);

  factory UserModel.fromSupabase(Map<String, dynamic> j) => UserModel(
    id: j['id'], fullName: j['full_name'] ?? '',
    role: UserRole.values.firstWhere((r) => r.name == (j['role'] ?? 'customer'),
      orElse: () => UserRole.customer),
    phone: j['phone'], avatarUrl: j['avatar_url'], email: j['email'],
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()));

  Map<String, dynamic> toSupabase() => {
    'id': id, 'full_name': fullName, 'role': role.name,
    'phone': phone, 'avatar_url': avatarUrl};

  Map<String, dynamic> toJson() => {
    'id': id, 'full_name': fullName, 'role': role.name,
    'phone': phone, 'avatar_url': avatarUrl, 'email': email,
    'created_at': createdAt.toIso8601String()};

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel.fromSupabase(j);
  String toJsonString() => jsonEncode(toJson());
  static UserModel fromJsonString(String s) => UserModel.fromJson(jsonDecode(s));
}
