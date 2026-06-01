// lib/routes/app_routes.dart
// PIC: Jibril (MJ)
// Sprint 0: Init project Flutter dan setup struktur folder
// Sprint 5 UPDATE — tambah route admin panel

/// Konstanta nama route untuk seluruh aplikasi BANKSOS.
/// Gunakan nama ini di Navigator.pushNamed / pushReplacementNamed.
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash             = '/splash';
  static const String login              = '/login';
  static const String register           = '/register';

  // Dashboard
  static const String dashboardMahasiswa = '/dashboard-mahasiswa';
  static const String dashboardReviewer  = '/dashboard-reviewer';
  static const String dashboardAdmin     = '/dashboard-admin';
  
  // Menu Umum
  static const String bankSoal           = '/bank-soal';
  static const String kerjakanSoal       = '/kerjakan-soal';
  static const String offlineSoal        = '/offline-soal';
  static const String submitSoal         = '/submit-soal';
  static const String questionDetail     = '/question-detail';
  static const String kontribusi         = '/kontribusi';
  static const String reviewQueue        = '/review-queue';
  static const String bookmarks          = '/bookmarks';
  static const String riwayat            = '/riwayat';
  static const String profile            = '/profile';
  static const String shell              = '/shell';
  static const String statistik          = '/statistik';


  // Sprint 5 — Panel Admin
  static const String adminKelolaUser    = '/admin/kelola-user';
  static const String adminKelolasoal   = '/admin/kelola-soal';
}