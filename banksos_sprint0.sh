#!/bin/bash

# =============================================================================
# BANKSOS - Sprint 0 Final Setup
# Jalankan di root folder project Flutter:
#   bash banksos_sprint0.sh
# =============================================================================

echo "🚀 BANKSOS Sprint 0 Final Setup..."

B="lib"

# =============================================================================
# 1. pubspec.yaml
# =============================================================================
cat > pubspec.yaml << 'YAML'
name: banksos
description: Bank Soal Latihan Mahasiswa - POLBAN
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Database
  mongo_dart: ^0.10.0

  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Environment variables
  flutter_dotenv: ^5.1.0

  # ID generator untuk data offline
  uuid: ^4.3.3

  # Cek koneksi internet
  connectivity_plus: ^6.0.3

  # State management
  flutter_riverpod: ^2.5.1

  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - .env
YAML

echo "✅ pubspec.yaml selesai"

# =============================================================================
# 2. core/constants/hive_boxes.dart (pastikan ada)
# =============================================================================
cat > $B/core/constants/hive_boxes.dart << 'DART'
/// Nama-nama HiveBox yang digunakan di seluruh aplikasi BANKSOS.
/// Selalu gunakan konstanta ini — jangan hardcode nama box di tempat lain.
class HiveBoxes {
  HiveBoxes._();

  /// Box untuk menyimpan sesi login pengguna yang sedang aktif.
  static const String session = 'session_box';

  /// Box untuk menyimpan soal yang sudah diunduh untuk akses offline.
  static const String questions = 'questions_box';

  /// Box untuk menyimpan daftar kategori mata kuliah.
  static const String categories = 'categories_box';

  /// Box untuk menyimpan riwayat pengerjaan soal.
  static const String progress = 'progress_box';

  /// Box untuk menyimpan daftar soal yang di-bookmark.
  static const String bookmarks = 'bookmarks_box';

  /// Box untuk antrian sinkronisasi data offline ke server.
  static const String syncQueue = 'sync_queue_box';
}
DART

echo "✅ hive_boxes.dart selesai"

# =============================================================================
# 3. core/constants/app_constants.dart
# =============================================================================
cat > $B/core/constants/app_constants.dart << 'DART'
class AppConstants {
  AppConstants._();

  static const String appName = 'BANKSOS';
  static const String appVersion = '1.0.0';

  /// Key untuk menyimpan data user di session_box.
  static const String sessionKey = 'current_user';

  /// Maksimum retry sinkronisasi sebelum item dianggap gagal.
  static const int maxSyncRetry = 3;
}
DART

# =============================================================================
# 4. core/services/session_service.dart
# =============================================================================
cat > $B/core/services/session_service.dart << 'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_model.dart';
import '../constants/hive_boxes.dart';
import '../constants/app_constants.dart';

/// Service untuk mengelola sesi login pengguna.
///
/// Sesi disimpan di Hive sehingga pengguna tidak perlu login ulang
/// setiap kali membuka aplikasi.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  Box? _box;

  /// Inisialisasi box. Dipanggil dari HiveService.init().
  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxes.session);
  }

  /// Menyimpan data user ke sesi lokal setelah login berhasil.
  Future<void> saveSession(UserModel user) async {
    await _box?.put(AppConstants.sessionKey, user.toMap());
  }

  /// Mengambil data user dari sesi lokal.
  /// Mengembalikan null jika belum login atau sesi sudah dihapus.
  UserModel? getSession() {
    final data = _box?.get(AppConstants.sessionKey);
    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  /// Mengecek apakah ada sesi login yang aktif.
  bool get isLoggedIn => _box?.containsKey(AppConstants.sessionKey) ?? false;

  /// Menghapus sesi login (logout).
  Future<void> clearSession() async {
    await _box?.delete(AppConstants.sessionKey);
  }
}
DART

echo "✅ session_service.dart selesai"

# =============================================================================
# 5. core/services/connectivity_service.dart
# =============================================================================
cat > $B/core/services/connectivity_service.dart << 'DART'
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk memantau status koneksi internet.
///
/// Digunakan oleh SyncManager untuk mendeteksi kapan perangkat
/// kembali online dan memulai proses sinkronisasi data offline.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Mengecek apakah perangkat saat ini terhubung ke internet.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream perubahan status koneksi.
  /// Gunakan ini di SyncManager untuk listen perubahan online/offline.
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
DART

echo "✅ connectivity_service.dart selesai"

# =============================================================================
# 6. data/local/hive/hive_service.dart
# =============================================================================
cat > $B/data/local/hive/hive_service.dart << 'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../models/category_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/bookmark_model.dart';
import '../../models/sync_queue_model.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/session_service.dart';

/// Service untuk inisialisasi dan pengelolaan Hive.
///
/// Panggil HiveService.init() di main.dart sebelum runApp()
/// untuk membuka semua box dan mendaftarkan semua adapter.
class HiveService {
  HiveService._();

  /// Inisialisasi Hive: daftarkan adapter dan buka semua box.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Daftarkan semua TypeAdapter (di-generate oleh build_runner)
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(QuestionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserProgressModelAdapter());
    Hive.registerAdapter(BookmarkModelAdapter());
    Hive.registerAdapter(SyncQueueModelAdapter());

    // Buka semua box
    await Hive.openBox(HiveBoxes.session);
    await Hive.openBox<QuestionModel>(HiveBoxes.questions);
    await Hive.openBox<CategoryModel>(HiveBoxes.categories);
    await Hive.openBox<UserProgressModel>(HiveBoxes.progress);
    await Hive.openBox<BookmarkModel>(HiveBoxes.bookmarks);
    await Hive.openBox<SyncQueueModel>(HiveBoxes.syncQueue);

    // Inisialisasi session service
    await SessionService.instance.init();
  }
}
DART

echo "✅ hive_service.dart selesai"

# =============================================================================
# 7. core/config/db_config.dart (update nama db jadi banksos_db)
# =============================================================================
cat > $B/core/config/db_config.dart << 'DART'
/// Konfigurasi koneksi MongoDB Atlas untuk aplikasi BANKSOS.
class DbConfig {
  DbConfig._();

  /// Nama database di MongoDB Atlas.
  static const String dbName = 'banksos_db';

  /// Nama semua collection.
  static const String colUsers = 'users';
  static const String colQuestions = 'questions';
  static const String colCategories = 'categories';
  static const String colUserProgress = 'user_progress';
  static const String colBookmarks = 'bookmarks';
}
DART

echo "✅ db_config.dart selesai (nama db: banksos_db)"

# =============================================================================
# 8. data/remote/mongodb/mongodb_service.dart (update nama db)
# =============================================================================
cat > $B/data/remote/mongodb/mongodb_service.dart << 'DART'
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/config/db_config.dart';

/// Service utama untuk koneksi ke MongoDB Atlas.
/// Gunakan sebagai singleton melalui MongoDBService.instance.
class MongoDBService {
  MongoDBService._();
  static final MongoDBService instance = MongoDBService._();

  Db? _db;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Membuka koneksi ke MongoDB Atlas.
  /// Dipanggil di main.dart sebelum runApp().
  Future<void> init() async {
    try {
      final uri = dotenv.env['MONGO_URI'] ?? '';
      if (uri.isEmpty) {
        throw Exception('MONGO_URI tidak ditemukan di file .env');
      }
      _db = await Db.create(uri);
      await _db!.open();
      _isConnected = true;
      print('✅ MongoDB terhubung: ${DbConfig.dbName}');
    } catch (e) {
      _isConnected = false;
      print('❌ Gagal koneksi MongoDB: $e');
      // Tidak rethrow — app tetap bisa jalan dalam mode offline
    }
  }

  Future<void> close() async {
    await _db?.close();
    _isConnected = false;
  }

  DbCollection collection(String name) {
    if (_db == null || !_isConnected) {
      throw Exception('MongoDB belum terhubung.');
    }
    return _db!.collection(name);
  }

  // Shortcut ke tiap collection
  DbCollection get users => collection(DbConfig.colUsers);
  DbCollection get questions => collection(DbConfig.colQuestions);
  DbCollection get categories => collection(DbConfig.colCategories);
  DbCollection get userProgress => collection(DbConfig.colUserProgress);
  DbCollection get bookmarks => collection(DbConfig.colBookmarks);
}
DART

echo "✅ mongodb_service.dart selesai"

# =============================================================================
# 9. main.dart
# =============================================================================
cat > $B/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'core/services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables dari .env
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Hive dan buka semua box
  await HiveService.init();

  // 3. Koneksi ke MongoDB Atlas
  await MongoDBService.instance.init();

  runApp(
    // ProviderScope dibutuhkan oleh Riverpod
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
}

class BanksosApp extends StatelessWidget {
  const BanksosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SessionService.instance.isLoggedIn;

    return MaterialApp(
      title: 'BANKSOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F5C99),
        ),
        useMaterial3: true,
      ),
      // Jika sudah login → langsung ke home, jika belum → ke login
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const Scaffold(
              body: Center(child: Text('Halaman Login — Sprint 1')),
            ),
        '/home': (context) => const Scaffold(
              body: Center(child: Text('Halaman Home — Sprint 1')),
            ),
      },
    );
  }
}
DART

echo "✅ main.dart selesai"

# =============================================================================
# 10. Update .env dengan nama db yang benar
# =============================================================================
cat > .env << 'ENV'
# Ganti USERNAME, PASSWORD, dan CLUSTER sesuai Atlas kamu
MONGO_URI=mongodb+srv://soalku_admin:PASSWORD_KAMU@banksos.5cmu9ap.mongodb.net/banksos_db?retryWrites=true&w=majority&appName=banksos
MONGO_DB_NAME=banksos_db
ENV

echo "✅ .env selesai (jangan lupa isi PASSWORD_KAMU)"

# =============================================================================
# SELESAI
# =============================================================================
echo ""
echo "============================================"
echo "✅ Sprint 0 setup selesai!"
echo "============================================"
echo ""
echo "Jalankan perintah berikut secara berurutan:"
echo ""
echo "  1. flutter pub get"
echo "  2. dart run build_runner build --delete-conflicting-outputs"
echo "  3. Isi PASSWORD_KAMU di file .env"
echo "  4. flutter run"
echo ""