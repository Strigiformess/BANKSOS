import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/config/db_config.dart';

class MongoDBService {
  MongoDBService._();
  static final MongoDBService instance = MongoDBService._();

  Db? _db;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> init() async {
    try {
      final uri = dotenv.env['MONGO_URI'] ?? '';
      if (uri.isEmpty) {
        throw Exception('MONGO_URI tidak ditemukan di file .env');
      }
      
      // 1. Buat instance Db di luar blok koneksi agar _db tidak null
      _db = await Db.create(uri);
      
      // 2. Coba buka koneksi
      await _db!.open().timeout(
        const Duration(seconds: 10),
      );
      _isConnected = true;
      print('MongoDB terhubung: ${DbConfig.dbName}');
    } catch (e) {
      _isConnected = false;
      // Berikan log yang lebih informatif bahwa aplikasi masuk ke mode offline
      print('Mode Offline Aktif (Gagal koneksi MongoDB): $e');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _isConnected = false;
  }

  DbCollection collection(String name) {
    if (_db == null) {
      // Hanya lempar error jika URI benar-benar rusak/kosong
      throw Exception('Konfigurasi MongoDB rusak atau belum diinisialisasi.');
    }
    // Hapus pengecekan !_isConnected di sini.
    // Biarkan aplikasi mengambil referensi collection. Jika query dilakukan 
    // saat offline, biarkan fungsi query tersebut yang menangani error-nya.
    return _db!.collection(name);
  }

  DbCollection get users => collection(DbConfig.colUsers);
  DbCollection get questions => collection(DbConfig.colQuestions);
  DbCollection get categories => collection(DbConfig.colCategories);
  DbCollection get userProgress => collection(DbConfig.colUserProgress);
  DbCollection get bookmarks => collection(DbConfig.colBookmarks);
}