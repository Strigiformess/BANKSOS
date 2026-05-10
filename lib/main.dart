// lib/main.dart
// Updated Sprint 1 — ganti placeholder dengan screen asli

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

// Dashboard
import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';

// Bank Soal (Sprint 2 — uncomment setelah Sprint 2 selesai)
// import 'features/questions/screens/bank_soal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env
  await dotenv.load(fileName: '.env');

  // 2. Init Hive (Ini WAJIB await karena penyimpanan lokal harus siap sebelum UI dirender)
  await HiveService.init();

  // 3. Init MongoDB
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
      themeMode: ThemeMode.system, // ikuti preferensi sistem Android
      home: const SplashRouter(),
      routes: {
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.dashboardMahasiswa: (_) => const DashboardMahasiswaScreen(),
        // Sprint 2 ↓ uncomment saat bank soal selesai
        // AppRoutes.bankSoal:           (_) => const BankSoalScreen(),
        // Placeholder untuk route lain (Sprint 3+)
        AppRoutes.dashboardReviewer:  (_) => const _PlaceholderScreen(title: 'Dashboard Reviewer'),
        AppRoutes.dashboardAdmin:     (_) => const _PlaceholderScreen(title: 'Dashboard Admin'),
        AppRoutes.bookmarks:          (_) => const _PlaceholderScreen(title: 'Bookmark'),
        AppRoutes.riwayat:            (_) => const _PlaceholderScreen(title: 'Riwayat'),
        AppRoutes.kontribusi:         (_) => const _PlaceholderScreen(title: 'Kontribusi'),
        AppRoutes.reviewQueue:        (_) => const _PlaceholderScreen(title: 'Review Queue'),
      },
    );
  }
}

// ─── Splash Router ─────────────────────────────────────────────────────────────
/// Cek sesi Hive → redirect ke halaman yang sesuai tanpa loading screen panjang.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    if (!mounted) return;
    final session = SessionService.instance;

    if (!session.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    switch (session.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardAdmin);
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardReviewer);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardMahasiswa);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen sementara redirect diproses
    return const Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BANKSOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bank Soal Kolaboratif POLBAN',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder untuk route Sprint 3+ ────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
        ),
      ),
    );
  }
}
