// lib/core/services/download_service.dart

import '../../data/local/boxes/category_box.dart';
import '../../data/local/boxes/question_box.dart';
import '../../data/models/question_model.dart';
import 'connectivity_service.dart';

/// Status hasil proses download.
enum DownloadStatus {
  success,
  alreadyDownloaded,
  noConnection,
  failed,
}

/// Hasil download yang dikembalikan ke controller/UI.
class DownloadResult {
  const DownloadResult({
    required this.status,
    this.jumlahSoal = 0,
    this.errorMessage,
  });

  final DownloadStatus status;
  final int jumlahSoal;
  final String? errorMessage;

  bool get isSuccess => status == DownloadStatus.success;
}

/// Mengelola proses unduh soal dari MongoDB ke Hive untuk akses offline.
///
/// Cara pakai:
///   // Unduh semua soal satu kategori
///   final result = await DownloadService.instance.downloadKategori(
///     kategoriId: 'abc123',
///     fetchFromRemote: (id) => questionRemote.getByKategori(id),
///   );
///
///   if (result.isSuccess) {
///     print('Berhasil unduh ${result.jumlahSoal} soal');
///   }
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  // ─── Download soal per kategori ──────────────────────────────────────────

  /// Mengunduh semua soal dari satu kategori ke Hive.
  ///
  /// [kategoriId]      — id kategori yang akan diunduh.
  /// [fetchFromRemote] — fungsi callback yang fetch soal dari MongoDB.
  ///                     Dipisah agar DownloadService tidak langsung
  ///                     bergantung ke MongoDBService (lebih mudah di-test).
  /// [forceRefresh]    — jika true, unduh ulang meski sudah ada di Hive.
  Future<DownloadResult> downloadKategori({
    required String kategoriId,
    required Future<List<QuestionModel>> Function(String kategoriId)
        fetchFromRemote,
    bool forceRefresh = false,
  }) async {
    // 1. Cek koneksi sebelum mulai
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      return const DownloadResult(status: DownloadStatus.noConnection);
    }

    // 2. Cek apakah sudah diunduh (skip jika tidak forceRefresh)
    if (!forceRefresh &&
        QuestionBox.instance.isKategoriDownloaded(kategoriId)) {
      return DownloadResult(
        status: DownloadStatus.alreadyDownloaded,
        jumlahSoal: QuestionBox.instance.countByKategori(kategoriId),
      );
    }

    try {
      // 3. Fetch dari MongoDB via callback
      final questions = await fetchFromRemote(kategoriId);

      if (questions.isEmpty) {
        return const DownloadResult(
          status: DownloadStatus.failed,
          errorMessage: 'Tidak ada soal yang tersedia untuk kategori ini.',
        );
      }

      // 4. Simpan ke Hive
      await QuestionBox.instance.saveAll(questions);

      return DownloadResult(
        status: DownloadStatus.success,
        jumlahSoal: questions.length,
      );
    } catch (e) {
      return DownloadResult(
        status: DownloadStatus.failed,
        errorMessage: 'Gagal mengunduh soal: $e',
      );
    }
  }

  // ─── Download semua kategori ─────────────────────────────────────────────

  /// Mengunduh soal dari semua kategori aktif sekaligus.
  /// Mengembalikan Map<kategoriId, DownloadResult> untuk tiap kategori.
  Future<Map<String, DownloadResult>> downloadSemua({
    required Future<List<QuestionModel>> Function(String kategoriId)
        fetchFromRemote,
    bool forceRefresh = false,
  }) async {
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      return {};
    }

    final categories = CategoryBox.instance.getAllActive();
    final results = <String, DownloadResult>{};

    for (final category in categories) {
      results[category.id] = await downloadKategori(
        kategoriId: category.id,
        fetchFromRemote: fetchFromRemote,
        forceRefresh: forceRefresh,
      );
    }

    return results;
  }

  // ─── Hapus soal offline ──────────────────────────────────────────────────

  /// Hapus soal satu kategori dari Hive.
  /// Dipanggil saat user ingin hapus data offline untuk menghemat storage.
  Future<void> hapusKategori(String kategoriId) async {
    await QuestionBox.instance.deleteByKategori(kategoriId);
  }

  /// Hapus semua soal offline dari Hive.
  Future<void> hapusSemua() async {
    await QuestionBox.instance.clearAll();
  }

  // ─── Info status download ────────────────────────────────────────────────

  /// Cek apakah soal dari kategori tertentu sudah diunduh.
  bool isKategoriDownloaded(String kategoriId) {
    return QuestionBox.instance.isKategoriDownloaded(kategoriId);
  }

  /// Jumlah soal yang sudah diunduh untuk satu kategori.
  int jumlahSoalDownloaded(String kategoriId) {
    return QuestionBox.instance.countByKategori(kategoriId);
  }
}