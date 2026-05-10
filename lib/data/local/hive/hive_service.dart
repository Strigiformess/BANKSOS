// lib/data/local/hive/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../models/category_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/bookmark_model.dart';
import '../../models/sync_queue_model.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  // ─── Getters untuk tiap box ──────────────────────────────────────────────

  Box get sessionBox => Hive.box(HiveBoxes.session);
  Box<QuestionModel> get questionsBox =>
      Hive.box<QuestionModel>(HiveBoxes.questions);
  Box<CategoryModel> get categoriesBox =>
      Hive.box<CategoryModel>(HiveBoxes.categories);
  Box<UserProgressModel> get userProgressBox =>
      Hive.box<UserProgressModel>(HiveBoxes.userProgress);
  Box<BookmarkModel> get bookmarksBox =>
      Hive.box<BookmarkModel>(HiveBoxes.bookmarks);
  Box<SyncQueueModel> get syncQueueBox =>
      Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);

  // ─── Inisialisasi ────────────────────────────────────────────────────────

  /// Dipanggil sekali di main.dart sebelum runApp().
  /// Mendaftarkan semua adapter lalu membuka semua box.
  static Future<void> init() async {
    await Hive.initFlutter();

    _registerAdapters();
    await _openAllBoxes();
  }

  // ─── Register adapter ────────────────────────────────────────────────────

  static void _registerAdapters() {
    // Daftarkan adapter hanya jika belum terdaftar
    // (mencegah error jika init() dipanggil lebih dari sekali, misal di test)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QuestionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserProgressModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BookmarkModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(SyncQueueModelAdapter());
    }
  }

  // ─── Buka semua box ──────────────────────────────────────────────────────

  static Future<void> _openAllBoxes() async {
    await Future.wait([
      // Box session pakai tipe dynamic (Map) karena menyimpan data sesi mentah
      Hive.openBox(HiveBoxes.session),

      Hive.openBox<QuestionModel>(HiveBoxes.questions),
      Hive.openBox<CategoryModel>(HiveBoxes.categories),
      Hive.openBox<UserProgressModel>(HiveBoxes.userProgress),
      Hive.openBox<BookmarkModel>(HiveBoxes.bookmarks),
      Hive.openBox<SyncQueueModel>(HiveBoxes.syncQueue),
    ]);
  }

  // ─── Tutup semua box ─────────────────────────────────────────────────────

  /// Opsional — dipanggil saat app ditutup atau di tear-down test.
  Future<void> closeAll() async {
    await Hive.close();
  }

  // ─── Helper: clear box tertentu ──────────────────────────────────────────

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAllDataBoxes() async {
    await Future.wait([
      questionsBox.clear(),
      categoriesBox.clear(),
      userProgressBox.clear(),
      bookmarksBox.clear(),
      syncQueueBox.clear(),
    ]);
    // Session TIDAK ikut di-clear di sini —
    // gunakan SessionService.clearSession() untuk logout.
  }
}