// lib/core/services/logout_handler.dart

import 'package:flutter/material.dart';
import 'session_service.dart';
import '../../data/local/hive/hive_service.dart';

/// Menangani proses logout secara terpusat.
///
/// Dipanggil dari mana saja (tombol logout di AppBar, session expired, dll).
/// Urutan:
///   1. Hapus sesi login dari Hive
///   2. Bersihkan data offline yang sensitif (opsional, lihat parameter)
///   3. Redirect ke halaman Login
class LogoutHandler {
  LogoutHandler._();
  static final LogoutHandler instance = LogoutHandler._();

  /// [clearOfflineData] — jika true, semua data offline (soal, progress,
  /// bookmark, sync queue) ikut dihapus. Default false agar data offline
  /// tetap tersedia jika pengguna login kembali dengan akun yang sama.
  Future<void> logout(
    BuildContext context, {
    bool clearOfflineData = false,
  }) async {
    // 1. Hapus sesi
    await SessionService.instance.clearSession();

    // 2. Opsional: bersihkan data offline
    if (clearOfflineData) {
      await HiveService.instance.clearAllDataBoxes();
    }

    // 3. Redirect ke Login — pastikan context masih valid
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // hapus semua route sebelumnya dari stack
      );
    }
  }

  /// Versi tanpa context — untuk logout yang dipicu sistem (bukan tombol UI),
  /// misalnya saat SyncManager mendeteksi akun dinonaktifkan oleh admin.
  /// Navigasi dilakukan di luar, pemanggil yang bertanggung jawab redirect.
  Future<void> logoutSilent({bool clearOfflineData = false}) async {
    await SessionService.instance.clearSession();

    if (clearOfflineData) {
      await HiveService.instance.clearAllDataBoxes();
    }
  }
}