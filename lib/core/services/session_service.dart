import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_model.dart';
import '../constants/hive_boxes.dart';
import '../constants/app_constants.dart';

/// Service untuk mengelola sesi login pengguna.
///
/// Sesi disimpan di Hive sehingga pengguna tidak perlu login ulang
/// setiap kali membuka aplikasi.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  Box? _box;

  /// Inisialisasi box. Dipanggil dari HiveService.init().
  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxes.session);
  }

  /// Menyimpan data user ke sesi lokal setelah login berhasil.
  Future<void> saveSession(UserModel user) async {
    await _box?.put(AppConstants.sessionKey, user.toMap());
  }

  /// Mengambil data user dari sesi lokal.
  /// Mengembalikan null jika belum login atau sesi sudah dihapus.
  UserModel? getSession() {
    final data = _box?.get(AppConstants.sessionKey);
    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  /// Mengecek apakah ada sesi login yang aktif.
  bool get isLoggedIn => _box?.containsKey(AppConstants.sessionKey) ?? false;

  /// Menghapus sesi login (logout).
  Future<void> clearSession() async {
    await _box?.delete(AppConstants.sessionKey);
  }
}
