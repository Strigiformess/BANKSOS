// lib/features/question/repositories/question_submit_repository.dart

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

// ─── Result wrapper ───────────────────────────────────────────────────────────

class QuestionSubmitResult {
  const QuestionSubmitResult({
    required this.success,
    this.questionId,
    this.errorMessage,
  });

  final bool success;
  final String? questionId;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

// ─── Data class untuk payload pengajuan soal ─────────────────────────────────

class SoalBaru {
  const SoalBaru({
    required this.pertanyaan,
    required this.jawaban,
    required this.kategoriId,
    required this.kategoriNama,
    this.hints = const [],
  });

  final String pertanyaan;
  final String jawaban;
  final String kategoriId;
  final String kategoriNama;
  final List<String> hints;
}

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class IQuestionSubmitRepository {
  Future<QuestionSubmitResult> ajukanSoal(SoalBaru soal);
  Future<List<Map<String, dynamic>>> getSoalSaya();
}

// ─── Implementasi ─────────────────────────────────────────────────────────────

class QuestionSubmitRepository implements IQuestionSubmitRepository {
  final MongoDBService _db;
  final SessionService _session;
  final ConnectivityService _connectivity;

  QuestionSubmitRepository({
    MongoDBService? db,
    SessionService? session,
    ConnectivityService? connectivity,
  })  : _db = db ?? MongoDBService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance;

  // ─── Helper: strip ObjectId wrapper jadi 24-hex string ───────────────────

  static String _toHex(String raw) {
    // Tangani format ObjectId("abc..."), ObjectId('abc...'), atau string biasa
    final match = RegExp(
      r'''ObjectId\(["']?([0-9a-fA-F]{24})["']?\)''',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match != null) return match.group(1)!;

    // Sudah 24-hex murni
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(raw)) return raw;

    // Coba ambil substring 24-hex pertama
    final anyHex = RegExp(r'([0-9a-fA-F]{24})').firstMatch(raw);
    if (anyHex != null) return anyHex.group(1)!;

    return raw;
  }

  // ─── Ajukan Soal ─────────────────────────────────────────────────────────

  @override
  Future<QuestionSubmitResult> ajukanSoal(SoalBaru soal) async {
    // 1. Pastikan user sudah login
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      return const QuestionSubmitResult(
        success: false,
        errorMessage: 'Sesi tidak ditemukan. Silakan login ulang.',
      );
    }

    // 2. Validasi field wajib
    final validasiError = validasi(soal);
    if (validasiError != null) {
      return QuestionSubmitResult(
        success: false,
        errorMessage: validasiError,
      );
    }

    // 3. Cek koneksi — submit WAJIB online
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) {
      return const QuestionSubmitResult(
        success: false,
        errorMessage: 'Pengajuan soal membutuhkan koneksi internet. '
            'Sambungkan ke internet lalu coba lagi.',
      );
    }

    // 4. Cek koneksi MongoDB
    if (!_db.isConnected) {
      return const QuestionSubmitResult(
        success: false,
        errorMessage:
            'Tidak dapat terhubung ke server. Coba beberapa saat lagi.',
      );
    }

    try {
      final now = DateTime.now().toIso8601String();
      final newId = ObjectId();

      // Bersihkan ID sebelum parse — cegah "Invalid argument(s)" error
      final kategoriOid = ObjectId.parse(_toHex(soal.kategoriId));
      final userOid = ObjectId.parse(_toHex(userId));

      final hints =
          soal.hints.map((h) => h.trim()).where((h) => h.isNotEmpty).toList();

      final doc = {
        '_id': newId,
        'pertanyaan': soal.pertanyaan.trim(),
        'jawaban': soal.jawaban.trim().toLowerCase(),
        'kategori_id': kategoriOid,
        'kategori_nama': soal.kategoriNama.trim(),
        'tingkat_kesulitan': 'easy',
        'status': 'pending',
        'hints': hints,
        'submitted_by': userOid,
        'reviewed_by': null,
        'rejection_reason': null,
        'solve_count': 0,
        'created_at': now,
        'updated_at': now,
      };

      final result = await _db.questions.insertOne(doc);

      if (!result.isSuccess) {
        return const QuestionSubmitResult(
          success: false,
          errorMessage: 'Gagal mengirim soal ke server. Coba lagi.',
        );
      }

      return QuestionSubmitResult(
        success: true,
        questionId: newId.oid,
      );
    } catch (e) {
      return QuestionSubmitResult(
        success: false,
        errorMessage:
            'Terjadi kesalahan: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // ─── Ambil Soal Milik User ────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSoalSaya() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) return [];

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) return [];

    try {
      final userOid = ObjectId.parse(_toHex(userId));
      final results = await _db.questions.find({
        'submitted_by': userOid,
      }).toList();

      results.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

      return results;
    } catch (_) {
      return [];
    }
  }

  // ─── Validasi Internal ────────────────────────────────────────────────────

  @visibleForTesting
  String? validasi(SoalBaru soal) {
    if (soal.pertanyaan.trim().isEmpty) {
      return 'Pertanyaan tidak boleh kosong.';
    }
    if (soal.pertanyaan.trim().length < 10) {
      return 'Pertanyaan terlalu singkat (minimal 10 karakter).';
    }
    if (soal.jawaban.trim().isEmpty) {
      return 'Jawaban tidak boleh kosong.';
    }
    if (soal.kategoriId.isEmpty) {
      return 'Pilih mata kuliah terlebih dahulu.';
    }
    return null;
  }
}