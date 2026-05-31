// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'routes/app_routes.dart';

// Diagnostics
import 'core/diagnostics/master_backend_suite.dart';

// Auth
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';

// Dashboard
import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';
import 'features/dashboard/screens/dashboard_reviewer_screen.dart';
import 'features/dashboard/screens/dashboard_admin_screen.dart';

// Bank Soal
import 'features/question/screens/bank_soal_screen.dart';
import 'features/question/screens/offline_questions_screen.dart';
import 'features/question/screens/question_detail_screen.dart';

// Bookmarks & Riwayat
import 'features/bookmarks/screens/bookmarks_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';

// Kontribusi & Review
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

// Admin
import 'features/admin/screens/admin_kelola_user_screen.dart';
import 'features/admin/screens/admin_kelola_soal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Muat Environment
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Hive
  await HiveService.init();

  // 3. Inisialisasi MongoDB
  try {
    await MongoDBService.instance.init();
  } catch (e) {
    debugPrint('⚠️ MongoDB init failed (offline mode): $e');
  }

  // 4. Inisialisasi Koneksi Internet
  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    debugPrint('⚠️ Connectivity service init failed: $e');
  }

  // 5. Jalankan Master Suite Test
  await MasterBackendSuite.runMasterSuite();

  // 6. Jalankan Background Sync (Pengganti SyncManager)
  SyncService.instance.flushQueue(); 
  ConnectivityService.instance.onConnectivityChanged.listen((status) {
    if (!status.toString().contains('none')) {
      SyncService.instance.flushQueue();
    }
  });
  // ─── Auto download semua soal sekali saat pertama kali app dijalankan
  try {
    await _downloadAllQuestionsIfNeeded();
  } catch (e) {
    debugPrint('⚠️ Auto-download questions failed: $e');
  }

  // Sprint 5/6: Mulai SyncManager — proses antrian offline saat app buka
  SyncManager.instance.startListening();

  runApp(
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
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
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.splash:             (_) => const SplashScreen(),
        AppRoutes.dashboardMahasiswa: (_) => const DashboardMahasiswaScreen(),
        AppRoutes.dashboardReviewer:  (_) => const DashboardReviewerScreen(),
        AppRoutes.dashboardAdmin:     (_) => const DashboardAdminScreen(),
        AppRoutes.bankSoal:           (_) => const BankSoalScreen(),
        AppRoutes.offlineSoal:        (_) => const OfflineQuestionsScreen(),
        AppRoutes.profile:            (_) => const ProfileScreen(),
        AppRoutes.bookmarks:          (_) => const BookmarksScreen(),
        AppRoutes.riwayat:            (_) => const RiwayatScreen(),
        AppRoutes.kontribusi:         (_) => const KontribusiScreen(),
        AppRoutes.reviewQueue:        (_) => const ReviewQueueScreen(),
        AppRoutes.submitSoal:         (_) => const SubmitSoalScreen(),
        AppRoutes.adminKelolaUser:    (_) => const AdminKelolaUserScreen(),
        AppRoutes.adminKelolasoal:    (_) => const AdminKelolasoalScreen(),
      },
    );
  }
}