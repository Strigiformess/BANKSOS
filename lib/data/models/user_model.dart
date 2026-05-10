import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// Role pengguna sesuai RBAC BANKSOS.
enum UserRole { mahasiswa, reviewer, admin }

/// Status akun pengguna.
enum UserStatus { active, inactive }

/// Model pengguna BANKSOS.
/// Berkorespondensi dengan collection "users" di MongoDB
/// dan HiveBox "users_box" untuk menyimpan sesi login lokal.
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  /// ID unik dari MongoDB (_id).
  @HiveField(0)
  final String id;

  /// Nama lengkap pengguna.
  @HiveField(1)
  final String namaLengkap;

  /// Nomor Induk Mahasiswa. Hanya diisi untuk role mahasiswa.
  @HiveField(2)
  final String? nim;

  /// Email institusi pengguna. Bersifat unik di seluruh sistem.
  @HiveField(3)
  final String email;

  /// Role pengguna: mahasiswa | reviewer | admin.
  @HiveField(4)
  final UserRole role;

  /// Status akun: active | inactive.
  @HiveField(5)
  final UserStatus status;

  /// Tanggal dan waktu akun dibuat.
  @HiveField(6)
  final DateTime createdAt;

  /// Tanggal dan waktu data terakhir diperbarui.
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
      id: map['_id']?.toString() ?? '',
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
