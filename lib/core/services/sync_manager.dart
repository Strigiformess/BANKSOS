// lib/core/services/sync_manager.dart
// Sprint 5/6 — Mohammad Jibril Fathi (MJF): Implementasi SyncManager
//
// SyncManager memproses antrian sinkronisasi (SyncQueueModel) yang terkumpul
// saat device offline. Saat device kembali online, semua item di syncQueue
// dikirim ke server secara berurutan.
//
// Alur:
//   1. startListening() → subscribe ke ConnectivityService.onConnectivityChanged
//   2. Saat status berubah ke online → panggil syncAll()
//   3. syncAll() → ambil semua item dari SyncQueueModel di Hive
//   4. Untuk tiap item, kirim ke server sesuai type (progress / bookmark)
//   5. Jika berhasil → hapus dari Hive
//   6. Jika gagal → increment retryCount, skip jika sudah >= maxRetry
//
// Cara pakai di main.dart:
//   SyncManager.instance.startListening();
//
// Cara tambah item ke antrian (dari repository lain):
//   await SyncManager.instance.enqueue(SyncQueueModel(...));

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/local/hive/hive_service.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/remote/mongodb/mongodb_service.dart';

// ─── Enum hasil sync tiap item ────────────────────────────────────────────────

enum _SyncItemResult { success, failed, skipped }

// ─── SyncManager ─────────────────────────────────────────────────────────────

/// Service singleton yang mengelola sinkronisasi data offline → server.
///
/// Dipanggil dari main.dart saat app pertama kali buka.
/// Juga bisa dipanggil manual dari UI jika user menekan tombol "Sync Sekarang".
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  // ─── Dependency ─────────────────────────────────────────────────────────────

  final ConnectivityService _connectivity = ConnectivityService.instance;
  final HiveService _hive = HiveService.instance;
  final MongoDBService _db = MongoDBService.instance;

  // ─── State internal ─────────────────────────────────────────────────────────

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isSyncing = false;

  /// True jika proses sync sedang berjalan.
  bool get isSyncing => _isSyncing;

  /// Jumlah item yang sedang menunggu sync.
  int get pendingCount => _hive.syncQueueBox.length;

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Mulai mendengarkan perubahan koneksi.
  /// Dipanggil sekali di main() setelah HiveService.init().
  void startListening() {
    _connectivitySub?.cancel();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        // Device baru saja kembali online — coba sync
        await syncAll();
      }
    });

    // Coba sync langsung saat pertama kali app buka (jika sudah online)
    _trySyncOnStart();
  }

  /// Hentikan listener. Dipanggil saat app ditutup (opsional).
  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Tambahkan item baru ke antrian sinkronisasi.
  ///
  /// Dipanggil dari BookmarkRepository atau ProgressRepository saat
  /// operasi dilakukan dalam kondisi offline.
  Future<void> enqueue(SyncQueueModel item) async {
    await _hive.syncQueueBox.put(item.id, item);
  }

  /// Helper untuk membuat dan langsung mengantre item progress.
  Future<void> enqueueProgress({
    required String userId,
    required String questionId,
    required String categoryId,
    required bool isSolved,
    required int attemptCount,
    DateTime? solvedAt,
  }) async {
    const uuid = Uuid();
    final item = SyncQueueModel(
      id: uuid.v4(),
      type: SyncType.progress,
      payload: {
        'user_id': userId,
        'question_id': questionId,
        'category_id': categoryId,
        'is_solved': isSolved,
        'attempt_count': attemptCount,
        'solved_at': solvedAt?.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
    await enqueue(item);
  }

  /// Helper untuk membuat dan langsung mengantre item bookmark.
  Future<void> enqueueBookmark({
    required String userId,
    required String questionId,
    required bool isAdd, // true = tambah, false = hapus
  }) async {
    const uuid = Uuid();
    final item = SyncQueueModel(
      id: uuid.v4(),
      type: SyncType.bookmark,
      payload: {
        'user_id': userId,
        'question_id': questionId,
        'action': isAdd ? 'add' : 'remove',
      },
      createdAt: DateTime.now(),
    );
    await enqueue(item);
  }

  /// Proses semua item di antrian.
  ///
  /// Aman dipanggil berkali-kali — jika sudah running, panggilan baru diabaikan.
  /// Mengembalikan jumlah item yang berhasil disinkronisasi.
  Future<int> syncAll() async {
    if (_isSyncing) return 0;

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) return 0;

    _isSyncing = true;
    int successCount = 0;

    try {
      // Ambil semua item dari Hive, urutkan dari yang paling lama (FIFO)
      final items = _hive.syncQueueBox.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final item in items) {
        final result = await _processItem(item);

        if (result == _SyncItemResult.success) {
          // Hapus dari antrian setelah berhasil
          await _hive.syncQueueBox.delete(item.key);
          successCount++;
        } else if (result == _SyncItemResult.skipped) {
          // Sudah melebihi maxRetry — hapus agar tidak memblokir antrian
          await _hive.syncQueueBox.delete(item.key);
        }
        // Jika failed, biarkan di antrian dengan retryCount+1 untuk dicoba lagi nanti
      }
    } catch (e) {
      // Log error tanpa crash
      // ignore: avoid_print
      print('[SyncManager] syncAll() error: $e');
    } finally {
      _isSyncing = false;
    }

    return successCount;
  }

  // ─── Private: coba sync saat app pertama buka ─────────────────────────────

  Future<void> _trySyncOnStart() async {
    // Tunggu sebentar agar koneksi dan MongoDB sempat terkoneksi
    await Future.delayed(const Duration(seconds: 3));
    await syncAll();
  }

  // ─── Private: proses satu item ───────────────────────────────────────────

  Future<_SyncItemResult> _processItem(SyncQueueModel item) async {
    // Cek apakah sudah melebihi batas retry
    if (item.retryCount >= AppConstants.maxSyncRetry) {
      // ignore: avoid_print
      print('[SyncManager] Item ${item.id} melebihi maxRetry, dilewati.');
      return _SyncItemResult.skipped;
    }

    try {
      switch (item.type) {
        case SyncType.progress:
          await _syncProgress(item.payload);
          break;
        case SyncType.bookmark:
          await _syncBookmark(item.payload);
          break;
      }
      return _SyncItemResult.success;
    } catch (e) {
      // ignore: avoid_print
      print('[SyncManager] Gagal sync item ${item.id}: $e');

      // Increment retryCount dan simpan kembali ke Hive
      final updated = item.copyWith(retryCount: item.retryCount + 1);
      await _hive.syncQueueBox.put(item.key, updated);

      return _SyncItemResult.failed;
    }
  }

  // ─── Private: sync progress ke MongoDB ───────────────────────────────────

  Future<void> _syncProgress(Map<String, dynamic> payload) async {
    final userId    = payload['user_id']    as String?;
    final questionId = payload['question_id'] as String?;
    final categoryId = payload['category_id'] as String?;
    final isSolved  = payload['is_solved']  as bool? ?? false;
    final attemptCount = payload['attempt_count'] as int? ?? 1;
    final solvedAtStr  = payload['solved_at']  as String?;

    if (userId == null || questionId == null || categoryId == null) {
      throw Exception('Payload progress tidak lengkap: $payload');
    }

    final now = DateTime.now().toIso8601String();

    // Upsert: update jika sudah ada, insert jika belum
    await _db.userProgress.update(
      {
        'user_id': userId,
        'question_id': questionId,
      },
      {
        r'$set': {
          'user_id': userId,
          'question_id': questionId,
          'category_id': categoryId,
          'is_solved': isSolved,
          'attempt_count': attemptCount,
          'solved_at': solvedAtStr,
          'is_synced': true,
          'updated_at': now,
        },
        r'$setOnInsert': {
          'created_at': now,
        },
      },
      upsert: true,
    );
  }

  // ─── Private: sync bookmark ke MongoDB ───────────────────────────────────

  Future<void> _syncBookmark(Map<String, dynamic> payload) async {
    final userId     = payload['user_id']     as String?;
    final questionId = payload['question_id'] as String?;
    final action     = payload['action']      as String?; // 'add' | 'remove'

    if (userId == null || questionId == null || action == null) {
      throw Exception('Payload bookmark tidak lengkap: $payload');
    }

    final col = _db.bookmarks;

    if (action == 'add') {
      // Cek duplikat sebelum insert
      final existing = await col.findOne({
        'user_id': userId,
        'question_id': questionId,
      });

      if (existing == null) {
        await col.insertOne({
          'user_id': userId,
          'question_id': questionId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } else if (action == 'remove') {
      await col.deleteOne({
        'user_id': userId,
        'question_id': questionId,
      });
    }
  }
}