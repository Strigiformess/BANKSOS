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
