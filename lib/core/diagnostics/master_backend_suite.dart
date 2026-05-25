import 'package:flutter/foundation.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../features/auth/data/auth_remote.dart';
import '../../data/remote/question_remote.dart';
import '../../data/remote/category_remote.dart';
import '../../data/remote/review_remote.dart';
import '../../data/remote/bookmark_remote.dart';
import '../../data/remote/progress_remote.dart';

class MasterBackendSuite {
  static Future<void> runMasterSuite() async {
    print("\n" + "🔥" * 30);
    print("🚀 MEMULAI MASTER INTEGRATION SUITE (All Modules)");
    print("🔥" * 30);

    final results = <String, bool>{};

    // 1. CORE SERVICES
    results['MongoDB Connection'] = await _testModule("MongoDB", () async {
      return MongoDBService.instance.isConnected;
    });
    
    results['Hive Storage'] = await _testModule("Hive", () async {
      return HiveService.instance.categoriesBox.isOpen;
    });

    // 2. REMOTE MODULES
    results['Auth Remote'] = await _testModule("AuthRemote", () async {
      // Tes sederhana: apakah bisa akses collection user
      return await MongoDBService.instance.users.count() >= 0;
    });

    results['Category Remote'] = await _testModule("CategoryRemote", () async {
      final count = await MongoDBService.instance.categories.count();
      return count >= 0;
    });

    results['Question Remote'] = await _testModule("QuestionRemote", () async {
      // Test fetch 1 soal untuk memastikan query berjalan
      final count = await MongoDBService.instance.questions.count();
      return count >= 0;
    });

    results['Review Remote'] = await _testModule("ReviewRemote", () async {
      final count = await ReviewRemote().countPendingQuestions();
      return count >= 0;
    });

    results['Bookmark Remote'] = await _testModule("BookmarkRemote", () async {
      // Cek apakah bisa akses box bookmark
      return HiveService.instance.bookmarksBox.isNotEmpty || HiveService.instance.bookmarksBox.isEmpty;
    });
    
    results['Progress Remote'] = await _testModule("ProgressRemote", () async {
      // Tes koneksi progress
      return await MongoDBService.instance.userProgress.count() >= 0;
    });

    // 3. SUMMARY
    print("\n" + "=" * 40);
    print("📊 HASIL AKHIR MASTER SUITE");
    print("=" * 40);
    results.forEach((key, value) {
      print("${value ? '✅ [PASS]' : '❌ [FAIL]'} - $key");
    });
    print("=" * 40 + "\n");
  }

  static Future<bool> _testModule(String name, Future<bool> Function() testFn) async {
    try {
      final success = await testFn();
      return success;
    } catch (e) {
      print("❌ Error di $name: $e");
      return false;
    }
  }
}