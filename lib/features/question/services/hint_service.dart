// lib/features/question/services/hint_service.dart


// Tanggung jawab:
//   - Menyimpan state hint yang sedang terbuka/tertutup per soal
//   - Mencatat apakah user sudah pernah melihat hint (untuk UI badge)
//   - Tidak ada mekanisme unlock — semua hint langsung tersedia
//
// Cara pakai:
//   final service = HintService();
//   service.toggleHints();         // buka/tutup panel hint
//   service.isExpanded             // cek apakah hint sedang terbuka
//   service.hasHints(question)     // cek apakah soal punya hint

import '../../../data/models/question_model.dart';

/// Service stateful ringan untuk mengatur tampilan hint di halaman soal.
///
/// Di-instantiate di dalam State widget, bukan singleton, karena
/// setiap halaman soal punya state hint sendiri-sendiri.
class HintService {
  /// Apakah panel hint sedang ditampilkan.
  bool _isExpanded = false;

  /// Apakah user sudah pernah buka hint di sesi ini.
  bool _hasBeenViewed = false;

  // ─── Getter publik ────────────────────────────────────────────────────────

  /// True jika panel hint sedang terbuka.
  bool get isExpanded => _isExpanded;

  /// True jika user sudah pernah membuka hint (berguna untuk badge).
  bool get hasBeenViewed => _hasBeenViewed;

  // ─── Aksi ─────────────────────────────────────────────────────────────────

  /// Toggle buka/tutup panel hint.
  /// Juga menandai bahwa hint sudah pernah dilihat.
  void toggleHints() {
    _isExpanded = !_isExpanded;
    if (_isExpanded) {
      _hasBeenViewed = true;
    }
  }

  /// Tutup panel hint secara paksa (dipanggil saat jawaban benar).
  void collapseHints() {
    _isExpanded = false;
  }

  /// Reset semua state — berguna jika instance di-reuse.
  void reset() {
    _isExpanded = false;
    _hasBeenViewed = false;
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  /// Kembalikan true jika soal memiliki minimal satu hint.
  bool hasHints(QuestionModel question) {
    return question.hints.isNotEmpty;
  }

  /// Jumlah hint yang tersedia untuk soal ini.
  int hintCount(QuestionModel question) {
    return question.hints.length;
  }

  /// Kembalikan semua teks hint dalam bentuk List<String>.
  /// Semua hint langsung tersedia tanpa unlock.
  List<String> getHints(QuestionModel question) {
    return List.unmodifiable(question.hints);
  }
}