// lib/core/guards/rbac_guard.dart
// Sprint 4 — Revaldi (RP): Guard RBAC Controller Level
//
// Guard ini memvalidasi akses role di CONTROLLER LEVEL, bukan hanya di UI.
// Konsisten dengan task Sprint 4 Kamis:
//   "Guard RBAC halaman review queue & manajemen koleksi:
//    hanya role reviewer yang bisa akses, validasi di controller level (bukan hanya UI)"
//
// Cara pakai:
//   // Di dalam controller atau repository:
//   RbacGuard.requireReviewer(_session);
//   RbacGuard.requireAdmin(_session);
//   RbacGuard.requireRole(_session, 'reviewer');
//
//   // Di widget (untuk redirect):
//   RbacGuard.redirectIfUnauthorized(context, requiredRole: 'reviewer');

import 'package:flutter/material.dart';

import '../../core/services/session_service.dart';
import '../../routes/app_routes.dart';

// ─── Exception ────────────────────────────────────────────────────────────────

/// Exception yang dilempar saat akses ditolak oleh guard.
class RbacException implements Exception {
  const RbacException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ─── Guard class ──────────────────────────────────────────────────────────────

/// Utilitas validasi RBAC di controller/repository level.
///
/// Semua method bersifat sinkron dan throw [RbacException] jika akses ditolak.
/// Controller yang memanggil method ini harus menangkap exception ini dan
/// mengembalikan error state yang sesuai kepada UI.
class RbacGuard {
  RbacGuard._();

  // ─── Validasi di controller level (throw jika ditolak) ───────────────────

  /// Pastikan user sudah login dan berperan sebagai reviewer.
  /// Melempar [RbacException] jika gagal.
  static void requireReviewer(SessionService session) {
    _requireLogin(session);
    if (session.role != 'reviewer') {
      throw const RbacException(
        'Akses ditolak. Halaman ini hanya untuk reviewer.',
      );
    }
  }

  /// Pastikan user sudah login dan berperan sebagai admin.
  /// Melempar [RbacException] jika gagal.
  static void requireAdmin(SessionService session) {
    _requireLogin(session);
    if (session.role != 'admin') {
      throw const RbacException(
        'Akses ditolak. Halaman ini hanya untuk admin.',
      );
    }
  }

  /// Pastikan user sudah login dan berperan sebagai mahasiswa.
  static void requireMahasiswa(SessionService session) {
    _requireLogin(session);
    if (session.role != 'mahasiswa') {
      throw const RbacException(
        'Akses ditolak. Halaman ini hanya untuk mahasiswa.',
      );
    }
  }

  /// Validasi role bebas — lempar jika role tidak cocok.
  ///
  /// [requiredRole] harus salah satu dari: 'mahasiswa', 'reviewer', 'admin'
  static void requireRole(SessionService session, String requiredRole) {
    _requireLogin(session);
    if (session.role != requiredRole) {
      throw RbacException(
        'Akses ditolak. Halaman ini hanya untuk $requiredRole.',
      );
    }
  }

  /// Cek apakah user punya salah satu dari beberapa role yang diizinkan.
  ///
  /// Contoh: [requireAnyRole] dengan ['reviewer', 'admin'] — reviewer dan admin bisa akses.
  static void requireAnyRole(
    SessionService session,
    List<String> allowedRoles,
  ) {
    _requireLogin(session);
    if (!allowedRoles.contains(session.role)) {
      final daftar = allowedRoles.join(' atau ');
      throw RbacException(
        'Akses ditolak. Halaman ini hanya untuk $daftar.',
      );
    }
  }

  // ─── Check tanpa throw (bool) ─────────────────────────────────────────────

  /// Kembalikan true jika user adalah reviewer yang sedang login.
  static bool isReviewer(SessionService session) =>
      session.isLoggedIn && session.role == 'reviewer';

  /// Kembalikan true jika user adalah admin yang sedang login.
  static bool isAdmin(SessionService session) =>
      session.isLoggedIn && session.role == 'admin';

  /// Kembalikan true jika user adalah mahasiswa yang sedang login.
  static bool isMahasiswa(SessionService session) =>
      session.isLoggedIn && session.role == 'mahasiswa';

  /// Kembalikan true jika user memiliki salah satu dari role yang diizinkan.
  static bool hasAnyRole(SessionService session, List<String> roles) =>
      session.isLoggedIn && roles.contains(session.role);

  // ─── Widget guard (redirect di UI) ───────────────────────────────────────

  /// Redirect ke halaman login jika tidak ada sesi,
  /// atau ke dashboard yang sesuai jika role tidak cocok.
  ///
  /// Dipanggil di `initState` widget yang dilindungi.
  ///
  /// Contoh pemakaian:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   WidgetsBinding.instance.addPostFrameCallback((_) {
  ///     RbacGuard.redirectIfUnauthorized(context, requiredRole: 'reviewer');
  ///   });
  /// }
  /// ```
  static void redirectIfUnauthorized(
    BuildContext context, {
    required String requiredRole,
  }) {
    final session = SessionService.instance;

    if (!session.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (session.role != requiredRole) {
      // Redirect ke dashboard sesuai role user yang sebenarnya
      final destination = _dashboardByRole(session.role);
      Navigator.pushReplacementNamed(context, destination);
    }
  }

  /// Versi redirect yang menerima beberapa role yang diizinkan.
  static void redirectIfNotAnyRole(
    BuildContext context, {
    required List<String> allowedRoles,
  }) {
    final session = SessionService.instance;

    if (!session.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (!allowedRoles.contains(session.role)) {
      final destination = _dashboardByRole(session.role);
      Navigator.pushReplacementNamed(context, destination);
    }
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  static void _requireLogin(SessionService session) {
    if (!session.isLoggedIn) {
      throw const RbacException(
        'Sesi tidak ditemukan. Silakan login ulang.',
      );
    }
  }

  static String _dashboardByRole(String? role) {
    switch (role) {
      case 'admin':
        return AppRoutes.dashboardAdmin;
      case 'reviewer':
        return AppRoutes.dashboardReviewer;
      default:
        return AppRoutes.dashboardMahasiswa;
    }
  }
}

// ─── Widget Wrapper ───────────────────────────────────────────────────────────

/// Widget yang membungkus halaman dengan proteksi RBAC.
///
/// Menampilkan halaman jika role cocok, atau redirect otomatis jika tidak.
/// Dipakai di route definition untuk efisiensi.
///
/// Contoh di `app_routes.dart`:
/// ```dart
/// AppRoutes.reviewQueue: (_) => RbacProtectedPage(
///   requiredRole: 'reviewer',
///   child: const ReviewQueueScreen(),
/// ),
/// ```
class RbacProtectedPage extends StatefulWidget {
  const RbacProtectedPage({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  /// Role yang diizinkan mengakses halaman ini.
  final String requiredRole;

  /// Halaman yang akan ditampilkan jika role cocok.
  final Widget child;

  @override
  State<RbacProtectedPage> createState() => _RbacProtectedPageState();
}

class _RbacProtectedPageState extends State<RbacProtectedPage> {
  @override
  void initState() {
    super.initState();
    // Lakukan redirect setelah frame pertama selesai render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        RbacGuard.redirectIfUnauthorized(
          context,
          requiredRole: widget.requiredRole,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;

    // Jika role tidak cocok, tampilkan halaman kosong sementara sebelum redirect
    if (!session.isLoggedIn || session.role != widget.requiredRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}