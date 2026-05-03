// lib/core/services/session_service.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_boxes.dart';

/// Menyimpan dan membaca data sesi login pengguna dari Hive.
///
/// Data yang disimpan:
///   - userId   : String  — _id dari MongoDB
///   - email    : String
///   - nama     : String
///   - role     : String  — 'mahasiswa' | 'reviewer' | 'admin'
///   - status   : String  — 'active' | 'inactive'
///   - loginAt  : String  — ISO 8601 timestamp waktu login
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  // ─── Key konstanta ───────────────────────────────────────────────────────

  static const String _keyUserId  = 'userId';
  static const String _keyEmail   = 'email';
  static const String _keyNama    = 'nama';
  static const String _keyRole    = 'role';
  static const String _keyStatus  = 'status';
  static const String _keyLoginAt = 'loginAt';

  Box get _box => Hive.box(HiveBoxes.session);

  // ─── Simpan sesi ─────────────────────────────────────────────────────────

  /// Dipanggil setelah login berhasil dari MongoDB.
  Future<void> saveSession({
    required String userId,
    required String email,
    required String nama,
    required String role,
    required String status,
  }) async {
    await _box.putAll({
      _keyUserId  : userId,
      _keyEmail   : email,
      _keyNama    : nama,
      _keyRole    : role,
      _keyStatus  : status,
      _keyLoginAt : DateTime.now().toIso8601String(),
    });
  }

  // ─── Baca sesi ───────────────────────────────────────────────────────────

  /// Mengembalikan true jika ada sesi login yang tersimpan.
  bool get isLoggedIn => _box.containsKey(_keyUserId);

  String? get userId  => _box.get(_keyUserId)  as String?;
  String? get email   => _box.get(_keyEmail)   as String?;
  String? get nama    => _box.get(_keyNama)    as String?;
  String? get role    => _box.get(_keyRole)    as String?;
  String? get status  => _box.get(_keyStatus)  as String?;
  String? get loginAt => _box.get(_keyLoginAt) as String?;

  /// Mengembalikan seluruh data sesi sebagai Map.
  /// Berguna untuk di-pass ke controller atau provider.
  Map<String, String?> getSessionData() {
    return {
      'userId'  : userId,
      'email'   : email,
      'nama'    : nama,
      'role'    : role,
      'status'  : status,
      'loginAt' : loginAt,
    };
  }

  // ─── Helper role ─────────────────────────────────────────────────────────

  bool get isMahasiswa => role == 'mahasiswa';
  bool get isReviewer  => role == 'reviewer';
  bool get isAdmin     => role == 'admin';
  bool get isActive    => status == 'active';

  // ─── Hapus sesi (logout) ─────────────────────────────────────────────────

  /// Menghapus seluruh data sesi dari Hive.
  /// Dipanggil saat pengguna menekan tombol logout.
  Future<void> clearSession() async {
    await _box.deleteAll([
      _keyUserId,
      _keyEmail,
      _keyNama,
      _keyRole,
      _keyStatus,
      _keyLoginAt,
    ]);
  }
}