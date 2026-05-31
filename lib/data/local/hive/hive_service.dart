// lib/data/local/hive/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

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

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openAllBoxes();
  }

  // ─── Register adapter ────────────────────────────────────────────────────

  static void registerAdapters() {
    _registerAdapters();
  }

  static void _registerAdapters() {
    // Daftarkan satu per satu dengan tipe eksplisit supaya Dart
    // mengenali .typeId dari TypeAdapter, bukan Object.
    _register(UserModelAdapter());
    _register(DifficultyLevelAdapter());
    _register(QuestionStatusAdapter());
    _register(QuestionModelAdapter());
    _register(CategoryModelAdapter());
    _register(UserProgressModelAdapter());
    _register(BookmarkModelAdapter());
    _register(SyncQueueModelAdapter());

    _register(SyncTypeAdapter()); 
  }

  static void _register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // ─── Buka semua box dengan error handling ────────────────────────────────

  static Future<void> _openAllBoxes() async {
    // Daftar semua box yang perlu dibuka
    final boxNames = [
      HiveBoxes.session,
      HiveBoxes.questions,
      HiveBoxes.categories,
      HiveBoxes.userProgress,
      HiveBoxes.bookmarks,
      HiveBoxes.syncQueue,
    ];

    // Buka satu per satu supaya kita bisa handle error per box
    for (final boxName in boxNames) {
      await _openBoxSafely(boxName);
    }
  }

  /// Membuka box dengan error handling. Jika corrupt, hapus dan buat baru.
  static Future<void> _openBoxSafely(String boxName) async {
    try {
      // Coba buka box
      if (boxName == HiveBoxes.questions) {
        await Hive.openBox<QuestionModel>(boxName);
      } else if (boxName == HiveBoxes.categories) {
        await Hive.openBox<CategoryModel>(boxName);
      } else if (boxName == HiveBoxes.userProgress) {
        await Hive.openBox<UserProgressModel>(boxName);
      } else if (boxName == HiveBoxes.bookmarks) {
        await Hive.openBox<BookmarkModel>(boxName);
      } else if (boxName == HiveBoxes.syncQueue) {
        await Hive.openBox<SyncQueueModel>(boxName);
      } else {
        await Hive.openBox(boxName);
      }

      if (kDebugMode) {
        print('✅ Hive Box "$boxName" opened successfully');
      }
    } catch (e) {
      // Jika error (biasanya corrupt data atau lock file), hapus dan buat ulang
      if (kDebugMode) {
        print('⚠️ Error opening box "$boxName": $e');
        print('🔧 Attempting to recover by deleting and recreating box...');
      }

      try {
        // Hapus box yang corrupt (termasuk lock file)
        await _deleteBoxFiles(boxName);
        
        // Tunggu sebentar supaya file system settle
        await Future.delayed(const Duration(milliseconds: 300));

        // Buka ulang (fresh)
        if (boxName == HiveBoxes.questions) {
          await Hive.openBox<QuestionModel>(boxName);
        } else if (boxName == HiveBoxes.categories) {
          await Hive.openBox<CategoryModel>(boxName);
        } else if (boxName == HiveBoxes.userProgress) {
          await Hive.openBox<UserProgressModel>(boxName);
        } else if (boxName == HiveBoxes.bookmarks) {
          await Hive.openBox<BookmarkModel>(boxName);
        } else if (boxName == HiveBoxes.syncQueue) {
          await Hive.openBox<SyncQueueModel>(boxName);
        } else {
          await Hive.openBox(boxName);
        }

        if (kDebugMode) {
          print('✅ Box "$boxName" recovered successfully');
        }
      } catch (recoveryError) {
        if (kDebugMode) {
          print('❌ Failed to recover box "$boxName": $recoveryError');
        }
        rethrow; // Jika recovery gagal, throw error
      }
    }
  }

  /// Helper untuk menghapus file box dan lock file
  static Future<void> _deleteBoxFiles(String boxName) async {
    try {
      // Coba hapus dengan cara normal
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e) {
      // Jika gagal (lock file issue), ignore dulu
      if (kDebugMode) {
        print('⚠️ Could not delete box normally: $e');
      }
    }
  }

  // ─── Tutup semua box ─────────────────────────────────────────────────────

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
  }

  /// Helper untuk force clear data (kecuali questions box)
  /// JANGAN hapus questions_box karena berisi data yang sudah didownload!
  Future<void> nukeNonPersistentData() async {
    try {
      await Future.wait([
        Hive.deleteBoxFromDisk(HiveBoxes.categories),
        Hive.deleteBoxFromDisk(HiveBoxes.userProgress),
        Hive.deleteBoxFromDisk(HiveBoxes.bookmarks),
        Hive.deleteBoxFromDisk(HiveBoxes.syncQueue),
        Hive.deleteBoxFromDisk(HiveBoxes.session),
      ]);
      if (kDebugMode) print('🗑️ Non-persistent Hive data cleared (questions_box preserved)');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing Hive data: $e');
      rethrow;
    }
  }
}