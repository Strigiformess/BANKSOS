// lib/main.dart
// Sprint 5 UPDATE — tambah route admin: kelola user & kelola soal

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// Bank Soal
import 'features/question/screens/bank_soal_screen.dart';

// Sprint 4
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

// Sprint 5 — Panel Admin (Revaldi: RBAC guard)
import 'features/admin/screens/admin_kelola_user_screen.dart';
import 'features/admin/screens/admin_kelola_soal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await HiveService.init();
  await MongoDBService.instance.init();
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
        AppRoutes.questionDetail:     (_) => const _PlaceholderScreen(title: 'Question Detail'),
        AppRoutes.bookmarks:          (_) => const _PlaceholderScreen(title: 'Bookmark'),
        AppRoutes.riwayat:            (_) => const _PlaceholderScreen(title: 'Riwayat'),

        // Sprint 4
        AppRoutes.kontribusi:         (_) => const KontribusiScreen(),
        AppRoutes.reviewQueue:        (_) => const ReviewQueueScreen(),
        AppRoutes.submitSoal:         (_) => const SubmitSoalScreen(),

        // Sprint 5 — Panel Admin (guard di controller level, Revaldi)
        AppRoutes.adminKelolaUser:    (_) => const AdminKelolaUserScreen(),
        AppRoutes.adminKelolasoal:   (_) => const AdminKelolasoalScreen(),
      },
    );
  }
}

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