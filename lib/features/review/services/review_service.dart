// lib/features/review/services/review_service.dart
// PIC: Revaldi (RP)
// Sprint 4: Implementasi logic review (approve, revisi, reject)
// FINAL LOGIC: Workflow Review Soal

import 'package:flutter/foundation.dart';
import '../../../data/remote/review_remote.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _remote = ReviewRemote();

  /// Menyetujui soal dan mengubah status jadi 'published'
  Future<void> approveSoal(String questionId, String reviewerId) async {
    try {
      await _remote.approveQuestion(questionId, reviewerId);
      debugPrint("✅ Soal $questionId berhasil dipublish");
    } catch (e) {
      debugPrint("❌ Gagal approve: $e");
      throw Exception('Gagal memproses persetujuan: $e');
    }
  }

  /// Menolak soal dengan catatan
  Future<void> rejectSoal(String questionId, String reviewerId, String reason) async {
    try {
      if (reason.isEmpty) throw Exception('Alasan penolakan wajib diisi.');
      await _remote.rejectQuestion(questionId, reviewerId, reason);
      debugPrint("✅ Soal $questionId ditolak");
    } catch (e) {
      debugPrint("❌ Gagal reject: $e");
      throw Exception('Gagal memproses penolakan: $e');
    }
  }

  /// Mengambil data antrian untuk ditampilkan di Reviewer Dashboard
  Future<List<Map<String, dynamic>>> getAntrianReview() async {
    try {
      return await _remote.getPendingQuestions();
    } catch (e) {
      debugPrint("❌ Gagal fetch antrian: $e");
      return [];
    }
  }
}