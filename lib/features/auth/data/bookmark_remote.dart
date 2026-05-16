import 'package:mongo_dart/mongo_dart.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class BookmarkRemote {
  final _db = MongoDBService.instance;

  /// Sinkronisasi tambah bookmark dari lokal ke cloud
  Future<void> addBookmark({
    required String userId,
    required String questionId,
  }) async {
    if (!_db.isConnected) throw Exception('Koneksi terputus. Sinkronisasi tertunda.');

    final col = _db.bookmarks;
    
    final existing = await col.findOne(
      where.eq('user_id', ObjectId.parse(userId)).eq('question_id', ObjectId.parse(questionId))
    );

    if (existing == null) {
      await col.insertOne({
        '_id': ObjectId(),
        'user_id': ObjectId.parse(userId),
        'question_id': ObjectId.parse(questionId),
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Sinkronisasi hapus bookmark dari lokal ke cloud
  Future<void> removeBookmark({
    required String userId,
    required String questionId,
  }) async {
    if (!_db.isConnected) throw Exception('Koneksi terputus. Sinkronisasi tertunda.');

    final col = _db.bookmarks;
    await col.deleteOne(
      where.eq('user_id', ObjectId.parse(userId)).eq('question_id', ObjectId.parse(questionId))
    );
  }

  Future<List<String>> getUserBookmarks(String userId) async {
    if (!_db.isConnected) throw Exception('Koneksi internet diperlukan.');

    final col = _db.bookmarks;
    final results = await col.find(where.eq('user_id', ObjectId.parse(userId))).toList();
    
    return results.map((e) => (e['question_id'] as ObjectId).toHexString()).toList();
  }
}