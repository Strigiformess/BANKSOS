import 'package:mongo_dart/mongo_dart.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class ReviewRemote {
  final _db = MongoDBService.instance;

  /// 1. Mengambil antrian soal yang statusnya 'pending'
  Future<List<Map<String, dynamic>>> getPendingQuestions() async {
    if (!_db.isConnected) throw Exception('Tidak terhubung ke server.');

    return await _db.questions.find(
      where.eq('status', 'pending').sortBy('created_at', descending: true)
    ).toList();
  }

  /// 2. Menyetujui soal (Approve)
  Future<void> approveQuestion(String questionId, String reviewerId) async {
    if (!_db.isConnected) throw Exception('Tidak terhubung ke server.');

    final result = await _db.questions.updateOne(
      where.id(ObjectId.parse(questionId)),
      modify
          .set('status', 'published')
          .set('reviewed_by', ObjectId.parse(reviewerId))
          .set('updated_at', DateTime.now().toIso8601String()),
    );

    if (!result.isSuccess) throw Exception('Gagal menyetujui soal.');
  }

  /// 3. Menolak soal (Reject)
  Future<void> rejectQuestion(String questionId, String reviewerId, String reason) async {
    if (!_db.isConnected) throw Exception('Tidak terhubung ke server.');

    final result = await _db.questions.updateOne(
      where.id(ObjectId.parse(questionId)),
      modify
          .set('status', 'rejected')
          .set('rejection_reason', reason)
          .set('reviewed_by', ObjectId.parse(reviewerId))
          .set('updated_at', DateTime.now().toIso8601String()),
    );

    if (!result.isSuccess) throw Exception('Gagal menolak soal.');
  }

  /// 4. Menghitung jumlah soal yang menunggu review (Untuk Badge Notifikasi)
  Future<int> countPendingQuestions() async {
    if (!_db.isConnected) return 0;
    
    // Perintah 'count' jauh lebih cepat daripada 'find' karena tidak mengirim data soal
    return await _db.questions.count(where.eq('status', 'pending'));
  }
}