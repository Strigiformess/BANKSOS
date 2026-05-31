// lib/core/services/session_service.dart

import 'package:bcrypt/bcrypt.dart';
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

  static const String _keyUserId        = 'userId';
  static const String _keyEmail         = 'email';
  static const String _keyNama          = 'nama';
  static const String _keyRole          = 'role';
  static const String _keyStatus        = 'status';
  static const String _keyLoginAt       = 'loginAt';
  static const String _keyOfflineToken  = 'offlineToken';
  static const String _keyTokenExpiry   = 'offlineTokenExpiry';
  static const String _keyPasswordHash  = 'passwordHash';

  Box get _box => Hive.box(HiveBoxes.session);

  // ─── Simpan sesi ─────────────────────────────────────────────────────────

  /// Dipanggil setelah login berhasil dari MongoDB.
  Future<void> saveSession({
    required String userId,
    required String email,
    required String nama,
    required String role,
    required String status,
    String? offlineToken,
    DateTime? offlineTokenExpiry,
    String? passwordHash,
  }) async {
    final data = {
      _keyUserId  : userId,
      _keyEmail   : email,
      _keyNama    : nama,
      _keyRole    : role,
      _keyStatus  : status,
      _keyLoginAt : DateTime.now().toIso8601String(),
    };

    if (offlineToken != null) {
      data[_keyOfflineToken] = offlineToken;
    }
    if (offlineTokenExpiry != null) {
      data[_keyTokenExpiry] = offlineTokenExpiry.toIso8601String();
    }
    if (passwordHash != null) {
      data[_keyPasswordHash] = passwordHash;
    }

    await _box.putAll(data);
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
  String? get offlineToken => _box.get(_keyOfflineToken) as String?;

  DateTime? get offlineTokenExpiry {
    final value = _box.get(_keyTokenExpiry) as String?;
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  String? get passwordHash => _box.get(_keyPasswordHash) as String?;

  bool get isOfflineTokenValid {
    final expiry = offlineTokenExpiry;
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  bool verifyOfflinePassword(String password) {
    final hash = passwordHash;
    if (hash == null || hash.isEmpty) return false;
    return BCrypt.checkpw(password, hash);
  }

  Map<String, String?> getSessionData() {
    return {
      'userId'         : userId,
      'email'          : email,
      'nama'           : nama,
      'role'           : role,
      'status'         : status,
      'loginAt'        : loginAt,
      'offlineToken'   : offlineToken,
      'tokenExpiry'    : offlineTokenExpiry?.toIso8601String(),
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
      _keyOfflineToken,
      _keyTokenExpiry,
      _keyPasswordHash,
    ]);
  }
}