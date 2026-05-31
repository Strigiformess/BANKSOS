// lib/main.dart
// Updated Sprint 4 — integrasi layar Kontribusi, Submit Soal, dan Review Queue

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/models/question_model.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'features/auth/data/question_remote.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_manager.dart';
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
import 'features/question/screens/offline_questions_screen.dart';

// Sprint 4 Screens
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // ─── Clean corrupted boxes BEFORE init ─────────────────────────────────────
  // Jika questions_box corrupt, hapus terlebih dahulu
  await _preCleanCorruptedBoxes();

  // ─── Hive initialization dengan error handling ────────────────────────────
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('❌ Fatal error initializing Hive: $e');
    // Attempt emergency recovery (tanpa menghapus questions_box)
    try {
      debugPrint('🆘 Attempting emergency recovery...');
      await HiveService.instance.nukeNonPersistentData();
      await HiveService.init();
      debugPrint('✅ Emergency recovery successful');
    } catch (recoveryError) {
      debugPrint('❌ Emergency recovery failed: $recoveryError');
      // Tetap jalankan app (Hive akan fail di runtime, but at least error visible)
    }
  }

  // ─── MongoDB initialization ────────────────────────────────────────────────
  try {
    await MongoDBService.instance.init();
  } catch (e) {
    debugPrint('⚠️ MongoDB init failed (offline mode): $e');
    // Tidak fatal, app bisa jalan di mode offline
  }

  // ─── Connectivity service ────────────────────────────────────────────────────
  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    debugPrint('⚠️ Connectivity service init failed: $e');
  }

  // ─── Sinkronisasi offline data saat online tersedia
  try {
    await SyncManager.instance.init();
  } catch (e) {
    debugPrint('⚠️ SyncManager init failed: $e');
  }

  // ─── Auto download semua soal sekali saat pertama kali app dijalankan
  try {
    await _downloadAllQuestionsIfNeeded();
  } catch (e) {
    debugPrint('⚠️ Auto-download questions failed: $e');
  }

  runApp(
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
}

Future<void> _downloadAllQuestionsIfNeeded() async {
  final hive = HiveService.instance.questionsBox;
  final isOnline = await ConnectivityService.instance.isOnline;

  if (!isOnline) {
    debugPrint('⚠️ Auto-download skipped: no internet connection');
    return;
  }

  if (hive.isNotEmpty) {
    debugPrint('✅ questions_box already contains ${hive.length} items; auto-download skipped');
    return;
  }

  try {
    debugPrint('⬇️ Starting auto-download of all published questions...');
    final rawList = await QuestionRemote().getPublishedQuestions();
    if (rawList.isEmpty) {
      debugPrint('⚠️ No published questions returned from remote.');
      return;
    }

    final questions = <String, QuestionModel>{};
    for (final raw in rawList) {
      final question = QuestionModel.fromMap(raw);
      questions[question.id] = question;
    }

    await hive.putAll(questions);
    debugPrint('✅ Auto-download complete: saved ${questions.length} questions to Hive');
  } catch (e) {
    debugPrint('⚠️ Auto-download failed: $e');
  }
}

/// Pre-clean questions_box jika ada error saat baca data
/// Ini cleanup SEBELUM init Hive, jadi nggak perlu register adapter dulu
Future<void> _preCleanCorruptedBoxes() async {
  try {
    await Hive.initFlutter();
    HiveService.registerAdapters();
    
    // Coba cek apakah questions_box bisa dibuka dengan adapter yang sudah terdaftar
    try {
      final box = await Hive.openBox<QuestionModel>('questions_box');
      await box.close();
      debugPrint('✅ questions_box check OK');
    } catch (e) {
      // Jika error saat membuka box, hapus dan biarkan HiveService.init membuat ulang
      debugPrint('⚠️ questions_box corrupt or unreadable, deleting...');
      try {
        await Hive.deleteBoxFromDisk('questions_box');
        debugPrint('✅ Corrupted questions_box deleted, will recreate on init');
      } catch (deleteError) {
        debugPrint('⚠️ Could not delete questions_box: $deleteError (will retry on init)');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Pre-clean check failed: $e (will retry on init)');
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
        AppRoutes.offlineSoal:        (_) => const OfflineQuestionsScreen(),
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