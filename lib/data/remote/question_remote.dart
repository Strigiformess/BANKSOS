import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class QuestionRemote {
  final _db = MongoDBService.instance;

  /// Mengambil daftar soal
  Future<List<Map<String, dynamic>>> getPublishedQuestionsByCategory(String categoryId) async {
    if (!_db.isConnected) throw Exception('Koneksi internet diperlukan.');
    
    // Bersihkan ID sebelum query
    final id = _cleanId(categoryId);
    return await _db.questions.find(
      where.eq('kategori_id', ObjectId.parse(id)).eq('status', 'published')
    ).toList();
  }

  /// SUBMIT SOAL (Logika Backend Terpusat)
  Future<void> submitQuestion(Map<String, dynamic> data) async {
    if (!_db.isConnected) throw Exception('Tidak terhubung ke server.');

    try {
      // Pastikan data dalam format Map yang bisa dimodifikasi
      final doc = Map<String, dynamic>.from(data);
      
      // Bersihkan ID sebelum insert
      doc['kategori_id'] = ObjectId.parse(_cleanId(doc['kategori_id'].toString()));
      doc['submitted_by'] = ObjectId.parse(_cleanId(doc['submitted_by'].toString()));
      
      final result = await _db.questions.insertOne(doc);
      if (!result.isSuccess) {
        throw Exception('Gagal menyimpan ke database.');
      }
    } catch (e) {
      debugPrint("❌ Gagal Submit: $e");
      throw Exception('Gagal mengirim soal: $e');
    }
  }

  // Helper pembersih string ObjectId
  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }
}