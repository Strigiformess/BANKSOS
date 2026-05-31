import 'package:mongo_dart/mongo_dart.dart';
import 'mongodb/mongodb_service.dart';

class CategoryRemote {
  final _db = MongoDBService.instance;

  /// Mengambil semua kategori mata kuliah yang aktif
  Future<List<Map<String, dynamic>>> getActiveCategories() async {
    if (!_db.isConnected) {
      throw Exception('Gagal memuat mata kuliah. Pastikan Anda terhubung ke internet.');
    }

    final col = _db.categories;
    final result = await col.find(where.eq('is_active', true)).toList();
    
    return result;
  }
}