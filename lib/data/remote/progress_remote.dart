import 'package:mongo_dart/mongo_dart.dart';
import 'mongodb/mongodb_service.dart';

class ProgressRemote {
  final _db = MongoDBService.instance;

  /// Sinkronisasi progres pengerjaan soal dari lokal ke cloud (Upsert)
  Future<void> syncUserProgress({
    required String userId,
    required String categoryId,
    required int totalDiselesaikan,
    required int jawabanBenar,
  }) async {
    if (!_db.isConnected) throw Exception('Koneksi terputus. Progres akan disinkronkan nanti.');

    final col = _db.userProgress;
    final uId = ObjectId.parse(userId);
    final cId = ObjectId.parse(categoryId);

    await col.update(
      where.eq('user_id', uId).eq('kategori_id', cId),
      modify
        .set('total_diselesaikan', totalDiselesaikan)
        .set('jawaban_benar', jawabanBenar)
        .set('last_accessed', DateTime.now().toIso8601String()),
      upsert: true, 
    );
  }

  Future<List<Map<String, dynamic>>> getUserStats(String userId) async {
    if (!_db.isConnected) throw Exception('Koneksi internet diperlukan.');

    final col = _db.userProgress;
    return await col.find(where.eq('user_id', ObjectId.parse(userId))).toList();
  }
}