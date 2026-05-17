// lib/main.dart
// Updated Sprint 3 — tambah route Bookmarks & Riwayat

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'routes/app_routes.dart';

// Auth
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';

// Dashboard
import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';
import 'features/dashboard/screens/dashboard_reviewer_screen.dart';
import 'features/dashboard/screens/dashboard_admin_screen.dart';

// Features Sprint 1–2
import 'features/question/screens/bank_soal_screen.dart';

// Features Sprint 3 (Seruni)
import 'features/bookmarks/screens/bookmarks_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await HiveService.init();
  MongoDBService.instance.init();

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
      home: const LoginScreen(),
      routes: {
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.splash:             (_) => const SplashScreen(),
        AppRoutes.dashboardMahasiswa: (_) => const DashboardMahasiswaScreen(),
        AppRoutes.dashboardReviewer:  (_) => const DashboardReviewerScreen(),
        AppRoutes.dashboardAdmin:     (_) => const DashboardAdminScreen(),
        AppRoutes.bankSoal:           (_) => const BankSoalScreen(),

        // ── Sprint 3: sudah bukan placeholder ───────────────────────────
        AppRoutes.bookmarks:          (_) => const BookmarksScreen(),
        AppRoutes.riwayat:            (_) => const RiwayatScreen(),

        // ── Sprint 4: masih placeholder ─────────────────────────────────
        AppRoutes.kontribusi:         (_) => const _PlaceholderScreen(title: 'Kontribusiku'),
        AppRoutes.reviewQueue:        (_) => const _PlaceholderScreen(title: 'Review Queue'),
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
          '$title\n(Coming Soon — Sprint 4)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
        ),
      ),
    );
  }
}