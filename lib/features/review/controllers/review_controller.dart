// lib/features/review/controllers/review_controller.dart
// Sprint 4 — Revaldi (RP): Review Controller
//
// Tanggung jawab:
//   - approve  : set status soal menjadi 'published', wajib pilih tingkat kesulitan
//   - revisi   : edit pertanyaan/jawaban/hints soal yang diajukan mahasiswa
//   - reject   : set status soal menjadi 'rejected', alasan WAJIB diisi
//   - loadSoalPending : ambil semua soal berstatus 'pending' dari MongoDB
//
// Validasi bisnis (di controller, bukan hanya di UI):
//   - approve  → tingkatKesulitan tidak boleh null/kosong
//   - reject   → alasan tidak boleh kosong (minimal 10 karakter)
//   - revisi   → pertanyaan & jawaban tidak boleh kosong
//   - Semua aksi hanya bisa dilakukan oleh role 'reviewer'
//
// State management menggunakan ChangeNotifier (konsisten dengan QuestionController).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where, modify;

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

// ─── Enum State ───────────────────────────────────────────────────────────────

enum ReviewLoadState { idle, loading, loaded, error }

enum ReviewActionState { idle, processing, success, error }

// ─── Result wrapper untuk aksi review ────────────────────────────────────────

class ReviewActionResult {
  const ReviewActionResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

final reviewControllerProvider = ChangeNotifierProvider<ReviewController>((ref) {
  return ReviewController();
});

// ─── Controller ───────────────────────────────────────────────────────────────

class ReviewController extends ChangeNotifier {
  final MongoDBService _db;
  final SessionService _session;
  final ConnectivityService _connectivity;

  ReviewController({
    MongoDBService? db,
    SessionService? session,
    ConnectivityService? connectivity,
  })  : _db = db ?? MongoDBService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance;

  // ─── State ─────────────────────────────────────────────────────────────────

  ReviewLoadState _loadState = ReviewLoadState.idle;
  ReviewActionState _actionState = ReviewActionState.idle;
  List<QuestionModel> _soalPending = [];
  String? _errorMessage;
  String? _actionError;

  // ─── Getter publik ─────────────────────────────────────────────────────────

  ReviewLoadState get loadState => _loadState;
  ReviewActionState get actionState => _actionState;
  List<QuestionModel> get soalPending => List.unmodifiable(_soalPending);
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  bool get isLoading => _loadState == ReviewLoadState.loading;
  bool get isProcessing => _actionState == ReviewActionState.processing;
  int get jumlahPending => _soalPending.length;

  // ─── Load Soal Pending ────────────────────────────────────────────────────

  /// Ambil semua soal berstatus 'pending' dari MongoDB.
  /// Diurut dari yang paling lama diajukan (created_at ASC) supaya
  /// reviewer memproses antrian secara FIFO.
  Future<void> loadSoalPending() async {
    // Guard RBAC di controller level
    if (!_isReviewer()) {
      _loadState = ReviewLoadState.error;
      _errorMessage = 'Akses ditolak. Halaman ini hanya untuk reviewer.';
      notifyListeners();
      return;
    }

    _loadState = ReviewLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      _loadState = ReviewLoadState.error;
      _errorMessage =
          'Antrian review membutuhkan koneksi internet.';
      notifyListeners();
      return;
    }

    try {
      final rawList = await _db.questions
          .find(where.eq('status', 'pending').sortBy('created_at'))
          .toList();

      _soalPending = rawList
          .map((m) => QuestionModel.fromMap(m))
          .toList();

      _loadState = ReviewLoadState.loaded;
    } catch (e) {
      _loadState = ReviewLoadState.error;
      _errorMessage =
          'Gagal memuat antrian soal: ${e.toString().replaceFirst('Exception: ', '')}';
    }

    notifyListeners();
  }

  // ─── Approve ─────────────────────────────────────────────────────────────

  /// Setujui soal dan publikasikan ke bank soal.
  ///
  /// [questionId]        — ID soal yang akan di-approve.
  /// [tingkatKesulitan]  — 'easy' | 'medium' | 'hard', WAJIB dipilih reviewer.
  ///
  /// Validasi:
  ///   - tingkatKesulitan tidak boleh kosong (reviewer wajib memilih)
  ///   - Hanya bisa dilakukan oleh reviewer
  Future<ReviewActionResult> approve({
    required String questionId,
    required String tingkatKesulitan,
  }) async {
    // Guard RBAC
    final guard = _guardReviewer();
    if (guard != null) return ReviewActionResult(success: false, errorMessage: guard);

    // Validasi: tingkat kesulitan wajib dipilih
    if (tingkatKesulitan.trim().isEmpty) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Pilih tingkat kesulitan soal sebelum menyetujui.',
      );
    }
    final validLevel = ['easy', 'medium', 'hard'];
    if (!validLevel.contains(tingkatKesulitan.toLowerCase())) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Tingkat kesulitan tidak valid. Pilih Easy, Medium, atau Hard.',
      );
    }

    return await _jalankanAksi(() async {
      final reviewerId = _session.userId!;
      await _db.questions.updateOne(
        where.id(ObjectId.parse(questionId)),
        modify
            .set('status', 'published')
            .set('tingkat_kesulitan', tingkatKesulitan.toLowerCase())
            .set('reviewed_by', ObjectId.parse(reviewerId))
            .set('rejection_reason', null)
            .set('updated_at', DateTime.now().toIso8601String()),
      );
    }, questionId: questionId);
  }

  // ─── Reject ──────────────────────────────────────────────────────────────

  /// Tolak soal yang diajukan mahasiswa.
  ///
  /// [questionId] — ID soal yang akan ditolak.
  /// [alasan]     — Alasan penolakan WAJIB diisi (minimal 10 karakter),
  ///                ditampilkan kepada mahasiswa di halaman 'Kontribusiku'.
  ///
  /// Validasi:
  ///   - alasan tidak boleh kosong (minimal 10 karakter)
  ///   - Hanya bisa dilakukan oleh reviewer
  Future<ReviewActionResult> reject({
    required String questionId,
    required String alasan,
  }) async {
    // Guard RBAC
    final guard = _guardReviewer();
    if (guard != null) return ReviewActionResult(success: false, errorMessage: guard);

    // Validasi: alasan wajib diisi
    if (alasan.trim().isEmpty) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Alasan penolakan tidak boleh kosong.',
      );
    }
    if (alasan.trim().length < 10) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Alasan penolakan terlalu singkat (minimal 10 karakter).',
      );
    }

    return await _jalankanAksi(() async {
      final reviewerId = _session.userId!;
      await _db.questions.updateOne(
        where.id(ObjectId.parse(questionId)),
        modify
            .set('status', 'rejected')
            .set('reviewed_by', ObjectId.parse(reviewerId))
            .set('rejection_reason', alasan.trim())
            .set('updated_at', DateTime.now().toIso8601String()),
      );
    }, questionId: questionId);
  }

  // ─── Revisi ───────────────────────────────────────────────────────────────

  /// Edit soal yang diajukan mahasiswa dan langsung mempublikasikannya.
  ///
  /// Reviewer bisa mengubah pertanyaan, jawaban, tingkat kesulitan, dan hints.
  /// Setelah direvisi, soal langsung berstatus 'published' (tidak perlu approve lagi).
  ///
  /// Validasi:
  ///   - pertanyaanBaru minimal 10 karakter
  ///   - jawabanBaru tidak boleh kosong
  ///   - tingkatKesulitan wajib dipilih
  ///   - Hanya bisa dilakukan oleh reviewer
  Future<ReviewActionResult> revisi({
    required String questionId,
    required String pertanyaanBaru,
    required String jawabanBaru,
    required String tingkatKesulitan,
    List<String> hints = const [],
  }) async {
    // Guard RBAC
    final guard = _guardReviewer();
    if (guard != null) return ReviewActionResult(success: false, errorMessage: guard);

    // Validasi field
    if (pertanyaanBaru.trim().isEmpty) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Pertanyaan tidak boleh kosong.',
      );
    }
    if (pertanyaanBaru.trim().length < 10) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Pertanyaan terlalu singkat (minimal 10 karakter).',
      );
    }
    if (jawabanBaru.trim().isEmpty) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Jawaban tidak boleh kosong.',
      );
    }
    if (tingkatKesulitan.trim().isEmpty) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Pilih tingkat kesulitan soal.',
      );
    }

    final cleanHints = hints
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toList();

    return await _jalankanAksi(() async {
      final reviewerId = _session.userId!;
      await _db.questions.updateOne(
        where.id(ObjectId.parse(questionId)),
        modify
            .set('pertanyaan', pertanyaanBaru.trim())
            // Jawaban selalu disimpan lowercase
            .set('jawaban', jawabanBaru.trim().toLowerCase())
            .set('tingkat_kesulitan', tingkatKesulitan.toLowerCase())
            .set('hints', cleanHints)
            .set('status', 'published')
            .set('reviewed_by', ObjectId.parse(reviewerId))
            .set('rejection_reason', null)
            .set('updated_at', DateTime.now().toIso8601String()),
      );
    }, questionId: questionId);
  }

  // ─── Reset state aksi ─────────────────────────────────────────────────────

  /// Reset action state — dipanggil setelah SnackBar/dialog ditutup.
  void resetActionState() {
    _actionState = ReviewActionState.idle;
    _actionError = null;
    notifyListeners();
  }

  // ─── Helper: jalankan aksi dengan state management ────────────────────────

  Future<ReviewActionResult> _jalankanAksi(
    Future<void> Function() aksi, {
    required String questionId,
  }) async {
    // Cek koneksi sebelum aksi apapun
    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      return const ReviewActionResult(
        success: false,
        errorMessage: 'Aksi review membutuhkan koneksi internet.',
      );
    }

    _actionState = ReviewActionState.processing;
    _actionError = null;
    notifyListeners();

    try {
      await aksi();

      // Hapus soal yang sudah diproses dari list pending lokal
      _soalPending.removeWhere((q) => q.id == questionId);
      _actionState = ReviewActionState.success;
      notifyListeners();

      return const ReviewActionResult(success: true);
    } catch (e) {
      _actionError = e.toString().replaceFirst('Exception: ', '');
      _actionState = ReviewActionState.error;
      notifyListeners();

      return ReviewActionResult(
        success: false,
        errorMessage: _actionError,
      );
    }
  }

  // ─── Guard RBAC ───────────────────────────────────────────────────────────

  /// Cek apakah user yang sedang login adalah reviewer.
  bool _isReviewer() {
    return _session.isLoggedIn && _session.role == 'reviewer';
  }

  /// Kembalikan pesan error jika bukan reviewer, null jika boleh akses.
  String? _guardReviewer() {
    if (!_session.isLoggedIn) {
      return 'Sesi tidak ditemukan. Silakan login ulang.';
    }
    if (_session.role != 'reviewer') {
      return 'Akses ditolak. Hanya reviewer yang dapat melakukan aksi ini.';
    }
    return null;
  }
}