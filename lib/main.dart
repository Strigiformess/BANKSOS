// lib/main.dart
// Updated Sprint 4 — integrasi layar Kontribusi, Submit Soal, dan Review Queue

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'core/services/connectivity_service.dart';
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
import 'features/question/screens/question_detail_screen.dart';

// Sprint 4 Screens
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await HiveService.init();

  // 3. Init MongoDB
  MongoDBService.instance.init();

  // cek koneksi internet dan log statusnya
  await ConnectivityService.instance.init();

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
        
        // Update rute Sprint 4 ke screen yang sebenarnya
        AppRoutes.kontribusi:         (_) => const KontribusiScreen(),
        AppRoutes.reviewQueue:        (_) => const ReviewQueueScreen(),
        
        // Tambahkan rute untuk Submit Soal
        AppRoutes.submitSoal:         (_) => const SubmitSoalScreen(),
      },
    );
  }
}

// ─── Placeholder Sprint 4+ ─────────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Coming Soon — Menunggu Sprint Berikutnya)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
        ),
      ),
    );
  }
}