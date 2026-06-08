import 'package:hive/hive.dart';

part 'user_model.g.dart';

enum UserRole { mahasiswa, reviewer, admin }

enum UserStatus { active, inactive }

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String namaLengkap;

  @HiveField(2)
  final String? nim;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final UserRole role;

  @HiveField(5)
  final UserStatus status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.namaLengkap,
    this.nim,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: _parseObjectId(map['_id']),
      namaLengkap: map['nama_lengkap'] ?? '',
      nim: map['nim'],
      email: map['email'] ?? '',
      role: _roleFromString(map['role']),
      status: map['status'] == 'inactive' ? UserStatus.inactive : UserStatus.active,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'nama_lengkap': namaLengkap,
      'nim': nim,
      'email': email,
      'role': role.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? namaLengkap,
    String? nim,
    String? email,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nim: nim ?? this.nim,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _parseObjectId(dynamic value) {
    if (value == null) return '';
    if (value is Map && value.containsKey('\$oid')) {
      final o = value['\$oid'];
      if (o is String && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(o)) return o;
    }
    final raw = value.toString();
    final m = RegExp(r'''ObjectId\(["\']?([0-9a-fA-F]{24})["\']?\)''',
            caseSensitive: false)
        .firstMatch(raw);
    if (m != null) return m.group(1)!;
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(raw)) return raw;
    final any = RegExp(r'([0-9a-fA-F]{24})').firstMatch(raw);
    return any != null ? any.group(1)! : raw;
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'reviewer':
        return UserRole.reviewer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.mahasiswa;
    }
  }

}