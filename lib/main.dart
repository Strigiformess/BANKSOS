// lib/main.dart
// Updated Sprint 4 — Integrasi menyeluruh dengan penanganan Error, Routing, & SyncQueue

import 'package:banksos/core/diagnostics/master_backend_suite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'routes/app_routes.dart';

// Auth
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';

// Dashboard
import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';
import 'features/dashboard/screens/dashboard_reviewer_screen.dart';
import 'features/dashboard/screens/dashboard_admin_screen.dart';
import 'features/question/screens/bank_soal_screen.dart';

// Sprint 4 Screens
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

// Tambahkan import di bagian atas
import 'features/admin/screens/admin_user_management_screen.dart';
import 'features/admin/screens/admin_question_management_screen.dart';
import 'features/bookmarks/screens/bookmarks_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Muat Environment
    await dotenv.load(fileName: '.env');
    
    // 2. Init Penyimpanan Lokal (Hive)
    await HiveService.init();

    // 3. Init Database & Koneksi Internet
    MongoDBService.instance.init();
    await ConnectivityService.instance.init();

    // 4. INIT SINKRONISASI LATAR BELAKANG (SPRINT 3)
    // Jalankan satu kali saat aplikasi baru dibuka
    SyncService.instance.flushQueue(); 
    
    // Jalankan otomatis setiap kali HP kembali mendapatkan sinyal internet
    ConnectivityService.instance.onConnectivityChanged.listen((status) {
      // Jika statusnya bukan 'none' (artinya ada internet), tembakkan antrean!
      if (status != ConnectivityResult.none) {
        SyncService.instance.flushQueue();
      }
    });

    await MasterBackendSuite.runMasterSuite();

    // 5. JIKA SEMUA SUKSES, baru jalankan aplikasi utama
    runApp(
      const ProviderScope(
        child: BanksosApp(),
      ),
    );
    
  } catch (e) {
    debugPrint("❌ FATAL ERROR SAAT STARTUP: $e");
    
    // 6. JIKA GAGAL, tahan aplikasi di layar error
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                "Aplikasi gagal dimuat karena kesalahan sistem:\n\n$e\n\nPastikan file .env sudah didaftarkan di pubspec.yaml dan tipe data Adapter tidak ada yang bentrok.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BanksosApp extends StatelessWidget {
  const BanksosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BANKSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // ikuti preferensi sistem Android
      home: const LoginScreen(),
      routes: {
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.splash:             (_) => const SplashScreen(),
        AppRoutes.dashboardMahasiswa: (_) => const DashboardMahasiswaScreen(),
        AppRoutes.dashboardReviewer:  (_) => const DashboardReviewerScreen(),
        AppRoutes.dashboardAdmin:     (_) => const DashboardAdminScreen(),
        AppRoutes.bankSoal:           (_) => const BankSoalScreen(),
        AppRoutes.questionDetail:     (_) => const _PlaceholderScreen(title: 'Question Detail'),
        AppRoutes.bookmarks:          (_) => const _PlaceholderScreen(title: 'Bookmark'),
        AppRoutes.riwayat:            (_) => const _PlaceholderScreen(title: 'Riwayat'),
        
        // Sprint 4
        AppRoutes.kontribusi:         (_) => const KontribusiScreen(),
        AppRoutes.reviewQueue:        (_) => const ReviewQueueScreen(),
        AppRoutes.submitSoal:         (_) => const SubmitSoalScreen(),

        // Sprint 5 - Admin routes
        AppRoutes.adminUserManagement:     (_) => const AdminUserManagementScreen(),
        AppRoutes.adminQuestionManagement: (_) => const AdminQuestionManagementScreen(),
      },
    );
  }
}

// ─── Placeholder ───────────────────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Sedang Dalam Pengembangan)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}