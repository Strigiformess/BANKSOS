// lib/routes/app_routes.dart
// Sprint 5 UPDATE — tambah route admin panel

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
  static const String submitSoal         = '/submit-soal';
  static const String questionDetail     = '/question-detail';
  static const String kontribusi         = '/kontribusi';
  static const String reviewQueue        = '/review-queue';
  static const String bookmarks          = '/bookmarks';
  static const String riwayat            = '/riwayat';
  static const String adminUserManagement      = '/admin-user-management';
  static const String adminQuestionManagement  = '/admin-question-management';

  // Sprint 5 — Panel Admin
  static const String adminKelolaUser    = '/admin/kelola-user';
  static const String adminKelolasoal   = '/admin/kelola-soal';
}