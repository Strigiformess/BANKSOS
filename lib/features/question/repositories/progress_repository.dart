// lib/features/question/repositories/progress_repository.dart
// Sprint 3 — Revaldi (RP): Progress Repository
//
// Tanggung jawab:
//   - recordAttempt  : catat setiap percobaan menjawab (benar atau salah)
//   - isSolved       : cek apakah soal sudah pernah diselesaikan user ini
//   - getProgress    : ambil semua data progress user dari Hive
//   - getSolvedCount : hitung jumlah soal yang sudah diselesaikan
//
// Aturan bisnis:
//   - is_solved hanya di-set true jika user menjawab BENAR.
//   - Setiap percobaan (benar/salah) menaikkan attempt_count.
//   - Data di-simpan ke Hive terlebih dahulu (offline-first).
//   - Jika online, data juga dikirim ke server via ProgressRemote.
//   - is_synced=false menandai data yang belum terkirim ke server.

import 'package:uuid/uuid.dart';

import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../features/auth/data/progress_remote.dart';

/// Abstraksi interface agar mudah di-mock saat unit test.
abstract class IProgressRepository {
  Future<void> recordAttempt({
    required String questionId,
    required String categoryId,
    required bool isCorrect,
  });

  bool isSolved(String questionId);
  List<UserProgressModel> getProgress();
  int getSolvedCount();
}

/// Implementasi progress_repository dengan pendekatan offline-first.
class ProgressRepository implements IProgressRepository {
  final HiveService _hive;
  final SessionService _session;
  final ConnectivityService _connectivity;
  final ProgressRemote _remote;

  ProgressRepository({
    HiveService? hive,
    SessionService? session,
    ConnectivityService? connectivity,
    ProgressRemote? remote,
  })  : _hive = hive ?? HiveService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance,
        _remote = remote ?? ProgressRemote();

  // ─── Catat Percobaan 

  /// Catat satu percobaan menjawab soal.
  ///
  /// [questionId]  — ID soal yang dikerjakan.
  /// [categoryId]  — ID kategori soal (untuk sinkronisasi ke server).
  /// [isCorrect]   — true jika jawaban user benar.
  ///
  /// Dipanggil dari halaman soal setiap kali user menekan 'Kirim Jawaban'.
  @override
  Future<void> recordAttempt({
    required String questionId,
    required String categoryId,
    required bool isCorrect,
  }) async {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return;

    final box = _hive.userProgressBox;

    // Cari progress yang sudah ada untuk kombinasi user + soal ini
    final existing = box.values
        .where((p) => p.questionId == questionId && p.userId == userId)
        .toList();

    UserProgressModel updated;

    if (existing.isNotEmpty) {
      // ── Update progress yang sudah ada 
      final current = existing.first;
      updated = current.copyWith(
        // is_solved hanya berubah dari false → true, tidak pernah sebaliknya
        isSolved: current.isSolved || isCorrect,
        // solvedAt hanya diisi pertama kali soal dijawab benar
        solvedAt: (isCorrect && current.solvedAt == null)
            ? DateTime.now()
            : current.solvedAt,
        attemptCount: current.attemptCount + 1,
        isSynced: false, // reset ke false karena ada perubahan baru
      );
      await box.put(current.key, updated);
    } else {
      // ── Buat record progress baru 
      const uuid = Uuid();
      updated = UserProgressModel(
        id: uuid.v4(),
        userId: userId,
        questionId: questionId,
        isSolved: isCorrect,
        solvedAt: isCorrect ? DateTime.now() : null,
        attemptCount: 1,
        isSynced: false,
      );
      await box.put(updated.id, updated);
    }

    // Coba sinkronisasi ke server jika online
    await _trySyncToServer(
      userId: userId,
      categoryId: categoryId,
      progress: updated,
    );
  }

  // ─── Sinkronisasi ke Server 

  Future<void> _trySyncToServer({
    required String userId,
    required String categoryId,
    required UserProgressModel progress,
  }) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) return; // Tidak online — biarkan SyncManager handle nanti

    try {
      // Hitung total progress user di kategori ini untuk dikirim ke server
      final allProgress = _hive.userProgressBox.values
          .where((p) => p.userId == userId)
          .toList();

      // Filter progress berdasarkan kategori (butuh questionId → kategoriId mapping)
      // Untuk Sprint 3, kita kirim aggregat per user saja
      final totalDiselesaikan = allProgress.where((p) => p.isSolved).length;
      final jawabanBenar = totalDiselesaikan; // sama karena is_solved = benar

      await _remote.syncUserProgress(
        userId: userId,
        categoryId: categoryId,
        totalDiselesaikan: totalDiselesaikan,
        jawabanBenar: jawabanBenar,
      );

      // Update is_synced = true di Hive setelah berhasil sync
      final box = _hive.userProgressBox;
      final synced = progress.copyWith(isSynced: true);
      await box.put(progress.key ?? progress.id, synced);
    } catch (_) {
      // Gagal sync — tidak apa-apa, is_synced tetap false
      // SyncManager Sprint 5 yang akan handle retry ini
    }
  }

  // ─── Read 

  /// Cek apakah soal sudah pernah diselesaikan (dijawab benar) oleh user.
  /// Operasi sinkron — langsung baca dari Hive.
  @override
  bool isSolved(String questionId) {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return false;

    return _hive.userProgressBox.values.any(
      (p) => p.questionId == questionId && p.userId == userId && p.isSolved,
    );
  }

  /// Ambil semua data progress milik user yang sedang login.
  /// Diurutkan berdasarkan solvedAt terbaru — untuk halaman riwayat.
  @override
  List<UserProgressModel> getProgress() {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return [];

    return _hive.userProgressBox.values
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) =>
          (b.solvedAt ?? DateTime(0)).compareTo(a.solvedAt ?? DateTime(0)));
  }

  /// Jumlah soal yang sudah berhasil diselesaikan oleh user saat ini.
  @override
  int getSolvedCount() {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return 0;

    return _hive.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;
  }

  /// Jumlah soal yang belum tersinkronisasi ke server (is_synced = false).
  /// Berguna untuk menampilkan badge sinkronisasi di dashboard.
  int get pendingSyncCount {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return 0;

    return _hive.userProgressBox.values
        .where((p) => p.userId == userId && !p.isSynced)
        .length;
  }

  /// Cek apakah ada data progress yang belum tersinkronisasi.
  bool get hasPendingSync => pendingSyncCount > 0;
}