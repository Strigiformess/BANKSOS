import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'mongodb/mongodb_service.dart';

class BookmarkRemote {
  final _db = MongoDBService.instance;

  /// Sinkronisasi tambah bookmark dari lokal ke cloud
 // Di dalam class BookmarkRemote
  Future<void> addBookmark({
    required String userId,
    required String questionId,
  }) async {
    if (!_db.isConnected) throw Exception('Koneksi terputus.');

    try {
      final col = _db.bookmarks;
      
      // Gunakan try-catch agar ObjectId.parse tidak membunuh aplikasi
      final userOid = ObjectId.parse(userId);
      final questionOid = ObjectId.parse(questionId);

      final existing = await col.findOne(
        where.eq('user_id', userOid).eq('question_id', questionOid)
      );

      if (existing == null) {
        await col.insertOne({
          '_id': ObjectId(),
          'user_id': userOid,
          'question_id': questionOid,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("❌ Gagal addBookmark: $e");
      rethrow; // Biarkan SyncService tahu bahwa ini gagal
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
    
    return results.map((e) => (e['question_id'] as ObjectId).oid).toList();
  }
}