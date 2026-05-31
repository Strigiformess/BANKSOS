// lib/features/question/repositories/question_submit_repository.dart
// Sprint 4 — Revaldi (RP): Submit Soal Repository
//
// Tanggung jawab:
//   - ajukanSoal     : POST soal baru ke MongoDB dengan status 'pending'
//   - getSoalSaya    : ambil daftar soal yang pernah diajukan user dari server
//   - getSoalSayaLokal : fallback dari Hive jika offline (soal pending lokal)
//
// Aturan bisnis:
//   - Submit soal WAJIB online — tidak ada mekanisme queue offline untuk pengajuan soal
//   - Status default selalu 'pending' saat pertama diajukan
//   - Jawaban otomatis di-lowercase sebelum dikirim ke server
//   - Validasi field wajib dilakukan di layer repository (bukan hanya UI)
//
// Alur:
//   1. Validasi input (pertanyaan, jawaban, kategoriId tidak boleh kosong)
//   2. Cek koneksi — jika offline, throw exception dengan pesan yang jelas
//   3. POST ke MongoDB via MongoDBService
//   4. Return QuestionSubmitResult dengan data soal yang baru dibuat

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

// ─── Result wrapper ───────────────────────────────────────────────────────────

/// Hasil operasi pengajuan soal.
class QuestionSubmitResult {
  const QuestionSubmitResult({
    required this.success,
    this.questionId,
    this.errorMessage,
  });

  final bool success;

  /// ID soal yang baru dibuat di MongoDB (jika berhasil).
  final String? questionId;

  /// Pesan error yang bisa langsung ditampilkan ke user.
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

// ─── Data class untuk payload pengajuan soal ─────────────────────────────────

/// Data yang dibutuhkan untuk mengajukan soal baru.
/// Dipisah dari model agar tidak tergantung pada semua field QuestionModel.
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

  // ─── Ajukan Soal ─────────────────────────────────────────────────────────

  /// POST soal baru ke MongoDB dengan status default 'pending'.
  ///
  /// Soal yang diajukan tidak langsung muncul di bank soal —
  /// harus melewati review oleh reviewer terlebih dahulu.
  ///
  /// Melempar exception jika:
  ///   - user tidak login
  ///   - koneksi tidak tersedia
  ///   - field wajib kosong
  ///   - gagal insert ke MongoDB
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
    final validasiError = _validasi(soal);
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
        errorMessage:
            'Pengajuan soal membutuhkan koneksi internet. '
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

      // Hints — filter yang kosong
      final hints = soal.hints
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList();

      final doc = {
        '_id': newId,
        'pertanyaan': soal.pertanyaan.trim(),
        // Jawaban selalu disimpan lowercase (case-insensitive matching)
        'jawaban': soal.jawaban.trim().toLowerCase(),
        'kategori_id': ObjectId.parse(soal.kategoriId),
        'kategori_nama': soal.kategoriNama.trim(),
        // Tingkat kesulitan akan diset reviewer saat approve
        'tingkat_kesulitan': 'easy',
        'status': 'pending',
        'hints': hints,
        'submitted_by': ObjectId.parse(userId),
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
        questionId: newId.toHexString(),
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

  /// Ambil semua soal yang pernah diajukan oleh user yang sedang login.
  /// Digunakan di halaman 'Kontribusiku'.
  ///
  /// Mengembalikan raw Map agar UI bisa handle field yang mungkin berubah
  /// tanpa harus regenerate model.
  @override
  Future<List<Map<String, dynamic>>> getSoalSaya() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) return [];

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) return [];

    try {
      final results = await _db.questions
          .find({
            'submitted_by': ObjectId.parse(userId),
          })
          .toList();

      // Urutkan: terbaru dulu
      results.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(0);
        return bDate.compareTo(aDate);
      });

      return results;
    } catch (_) {
      return [];
    }
  }

  // ─── Validasi Internal ────────────────────────────────────────────────────

  /// Validasi field wajib. Mengembalikan pesan error atau null jika valid.
  String? _validasi(SoalBaru soal) {
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