// lib/core/services/offline_question_service.dart

import '../../data/local/boxes/question_box.dart';
import '../../data/local/boxes/category_box.dart';
import '../../data/models/question_model.dart';
import '../../data/models/category_model.dart';
import 'connectivity_service.dart';

/// Hasil load soal — membawa data sekaligus info sumbernya.
class QuestionLoadResult {
  const QuestionLoadResult({
    required this.questions,
    required this.isFromCache,
    this.errorMessage,
  });

  /// Daftar soal yang berhasil diload.
  final List<QuestionModel> questions;

  /// True jika data berasal dari Hive (offline), false jika dari server.
  final bool isFromCache;

  /// Pesan error jika gagal (questions kosong dan ada error).
  final String? errorMessage;

  bool get isEmpty => questions.isEmpty;
  bool get hasError => errorMessage != null;
}

/// Mengelola logika load soal dengan offline fallback.
///
/// Alur:
///   1. Cek koneksi via ConnectivityService
///   2. Online  → fetch dari server (via callback), simpan ke Hive sebagai cache
///   3. Offline → load langsung dari Hive
///   4. Jika offline dan belum ada di Hive → kembalikan pesan error yang jelas
///
/// Cara pakai:
///   final result = await OfflineQuestionService.instance.loadByKategori(
///     kategoriId: 'abc123',
///     fetchFromRemote: (id) => questionRemote.getByKategori(id),
///   );
///
///   if (result.isFromCache) showOfflineBanner();
///   displayQuestions(result.questions);
class OfflineQuestionService {
  OfflineQuestionService._();
  static final OfflineQuestionService instance = OfflineQuestionService._();

  // ─── Load soal by kategori ────────────────────────────────────────────────

  /// Load soal satu kategori dengan fallback ke Hive jika offline.
  ///
  /// [kategoriId]      — id kategori yang akan diload.
  /// [fetchFromRemote] — fungsi fetch dari MongoDB (disuplai oleh controller).
  /// [tingkatKesulitan]— opsional, filter by 'easy'|'medium'|'hard'.
  Future<QuestionLoadResult> loadByKategori({
    required String kategoriId,
    required Future<List<QuestionModel>> Function(String kategoriId)
        fetchFromRemote,
    String? tingkatKesulitan,
  }) async {
    final isOnline = ConnectivityService.instance.isOnline;

    if (await isOnline) {
      return await _loadFromRemote(
        kategoriId: kategoriId,
        fetchFromRemote: fetchFromRemote,
        tingkatKesulitan: tingkatKesulitan,
      );
    } else {
      return _loadFromHive(
        kategoriId: kategoriId,
        tingkatKesulitan: tingkatKesulitan,
      );
    }
  }

  // ─── Load semua kategori (untuk halaman beranda) ──────────────────────────

  /// Load daftar kategori dengan fallback ke Hive jika offline.
  Future<List<CategoryModel>> loadKategori({
    required Future<List<CategoryModel>> Function() fetchFromRemote,
  }) async {
    final isOnline = ConnectivityService.instance.isOnline;

    if (await isOnline) {
      try {
        final categories = await fetchFromRemote();
        // Simpan ke Hive sebagai cache
        await CategoryBox.instance.saveAll(categories);
        return categories;
      } catch (_) {
        // Gagal fetch → fallback ke Hive
        return CategoryBox.instance.getAllActive();
      }
    } else {
      return CategoryBox.instance.getAllActive();
    }
  }

  // ─── Private: load dari remote ────────────────────────────────────────────

  Future<QuestionLoadResult> _loadFromRemote({
    required String kategoriId,
    required Future<List<QuestionModel>> Function(String) fetchFromRemote,
    String? tingkatKesulitan,
  }) async {
    try {
      final questions = await fetchFromRemote(kategoriId);

      // Simpan ke Hive sebagai cache untuk akses offline nanti
      if (questions.isNotEmpty) {
        await QuestionBox.instance.saveAll(questions);
      }

      // Filter by kesulitan jika diminta
      final filtered = tingkatKesulitan != null
          ? questions
              .where((q) => q.tingkatKesulitan == tingkatKesulitan)
              .toList()
          : questions;

      return QuestionLoadResult(
        questions: filtered,
        isFromCache: false,
      );
    } catch (e) {
      // Gagal fetch dari server → coba fallback ke Hive
      final fromHive = _loadFromHive(
        kategoriId: kategoriId,
        tingkatKesulitan: tingkatKesulitan,
      );

      if (!fromHive.isEmpty) {
        // Ada data di Hive → tampilkan dengan info cache
        return QuestionLoadResult(
          questions: fromHive.questions,
          isFromCache: true,
          errorMessage: 'Gagal memuat dari server, menampilkan data tersimpan.',
        );
      }

      // Jika tidak ada data di Hive, kembalikan pesan offline/unduh agar
      // UI dapat menampilkan instruksi yang sesuai.
      return const QuestionLoadResult(
        questions: [],
        isFromCache: true,
        errorMessage:
            'Kamu sedang offline dan soal belum diunduh. '
            'Hubungkan ke internet lalu unduh soal terlebih dahulu.',
      );
    }
  }

  // ─── Private: load dari Hive ──────────────────────────────────────────────

  QuestionLoadResult _loadFromHive({
    required String kategoriId,
    String? tingkatKesulitan,
  }) {
    final bool sudahDiunduh =
        QuestionBox.instance.isKategoriDownloaded(kategoriId);

    if (!sudahDiunduh) {
      return const QuestionLoadResult(
        questions: [],
        isFromCache: true,
        errorMessage:
            'Kamu sedang offline dan soal belum diunduh. '
            'Hubungkan ke internet lalu unduh soal terlebih dahulu.',
      );
    }

    final questions = tingkatKesulitan != null
        ? QuestionBox.instance.getByKategoriDanKesulitan(
            kategoriId: kategoriId,
            tingkatKesulitan: tingkatKesulitan,
          )
        : QuestionBox.instance.getByKategori(kategoriId);

    return QuestionLoadResult(
      questions: questions,
      isFromCache: true,
    );
  }

  // ─── Helper: status offline per kategori ─────────────────────────────────

  /// Apakah soal dari kategori ini sudah bisa diakses offline.
  bool isAvailableOffline(String kategoriId) {
    return QuestionBox.instance.isKategoriDownloaded(kategoriId);
  }
}