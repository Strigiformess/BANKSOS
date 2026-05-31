// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'data/remote/question_remote.dart';
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

// Bank Soal
import 'features/question/screens/bank_soal_screen.dart';
import 'features/question/screens/offline_questions_screen.dart';

// Bookmarks & Riwayat
import 'features/bookmarks/screens/bookmarks_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';

// Kontribusi & Review
import 'features/kontribusi/screens/kontribusi_screen.dart';
import 'features/kontribusi/screens/submit_soal_screen.dart';
import 'features/review/screens/review_queue_screen.dart';


// Tambahkan import di bagian atas
import 'features/admin/screens/admin_user_management_screen.dart';
import 'features/admin/screens/admin_question_management_screen.dart';
import 'features/bookmarks/screens/bookmarks_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/statistics/screens/statistics_screen.dart';

// Admin
import 'features/admin/screens/admin_kelola_user_screen.dart';
import 'features/admin/screens/admin_kelola_soal_screen.dart';
import 'data/models/question_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Muat Environment
  await dotenv.load(fileName: '.env');

  // 2. Bersihkan Hive Corrupt & Inisialisasi
  await _preCleanCorruptedBoxes();
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('⚠️ Hive Init error, attempting recovery: $e');
    await HiveService.instance.nukeNonPersistentData();
    await HiveService.init();
  }

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

  // 5. Auto Download Soal sekali saat buka app
  try {
    await _downloadAllQuestionsIfNeeded();
  } catch (e) {
    debugPrint('⚠️ Auto-download questions failed: $e');
  }

  // 6. Pengganti SyncManager (Otomatis Sync saat internet menyala)
  SyncService.instance.flushQueue(); 
  ConnectivityService.instance.onConnectivityChanged.listen((status) {
    if (!status.toString().contains('none')) {
      SyncService.instance.flushQueue();
    }
  });

  // (Opsional) Uncomment baris di bawah jika ingin menjalankan test diagnostic
  // await MasterBackendSuite.runMasterSuite();

  runApp(
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
}

/// Pre-clean questions_box jika ada error saat baca data (Mencegah Crash Hive)
Future<void> _preCleanCorruptedBoxes() async {
  try {
    await Hive.initFlutter();
    HiveService.registerAdapters();
    
    try {
      final box = await Hive.openBox<QuestionModel>('questions_box');
      await box.close();
    } catch (e) {
      debugPrint('⚠️ questions_box corrupt or unreadable, deleting...');
      try {
        await Hive.deleteBoxFromDisk('questions_box');
      } catch (_) {}
    }
  } catch (_) {}
}

/// Download semua soal jika local masih kosong
Future<void> _downloadAllQuestionsIfNeeded() async {
  if (!Hive.isBoxOpen('questions_box')) return;
  
  final hive = HiveService.instance.questionsBox;
  final isOnline = await ConnectivityService.instance.isOnline;
  
  // Lewati jika tidak ada internet atau sudah ada datanya
  if (!isOnline || hive.isNotEmpty) return;

  try {
    final rawList = await QuestionRemote().getPublishedQuestions();
    if (rawList.isEmpty) return;

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
        AppRoutes.profile:            (_) => const ProfileScreen(),
        AppRoutes.statistik:          (_) => const StatisticsScreen(),
        
        AppRoutes.offlineSoal:        (_) => const OfflineQuestionsScreen(),
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