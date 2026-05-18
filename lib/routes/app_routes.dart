// lib/routes/app_routes.dart

/// Konstanta nama route untuk seluruh aplikasi BANKSOS.
/// Gunakan nama ini di Navigator.pushNamed / pushReplacementNamed.
class AppRoutes {
  AppRoutes._();

  static const String login              = '/login';
  static const String register           = '/register';
  static const String splash             = '/splash';
  static const String dashboardMahasiswa = '/dashboard-mahasiswa';
  static const String dashboardReviewer  = '/dashboard-reviewer';
  static const String dashboardAdmin     = '/dashboard-admin';
  static const String bankSoal           = '/bank-soal';
  static const String kerjakanSoal       = '/kerjakan-soal';
  static const String kontribusi         = '/kontribusi';
  static const String reviewQueue        = '/review-queue';
  static const String bookmarks          = '/bookmarks';
  static const String riwayat            = '/riwayat';
}