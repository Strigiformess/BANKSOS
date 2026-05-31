import 'package:mongo_dart/mongo_dart.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class QuestionRemote {
  final _db = MongoDBService.instance;

  /// Mengunduh daftar soal berdasarkan ID Kategori (Mata Kuliah)
  Future<List<Map<String, dynamic>>> getPublishedQuestionsByCategory(String categoryId) async {
    if (!_db.isConnected) {
      throw Exception('Koneksi internet diperlukan untuk mengunduh soal.');
    }

    final col = _db.questions;
    final result = await col.find(
      where
        .eq('kategori_id', ObjectId.parse(categoryId))
        .eq('status', 'published')
    ).toList();
    
    return result;
  }

  /// Mengunduh seluruh soal yang berstatus published.
  Future<List<Map<String, dynamic>>> getPublishedQuestions() async {
    if (!_db.isConnected) {
      throw Exception('Koneksi internet diperlukan untuk mengunduh soal.');
    }

    final col = _db.questions;
    final result = await col.find(
      where.eq('status', 'published')
    ).toList();

    return result;
  }
}