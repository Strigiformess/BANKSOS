import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/local/hive/hive_service.dart';
import '../../data/models/question_model.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/models/user_progress_model.dart';
import '../../data/remote/bookmark_remote.dart';
import '../../data/remote/progress_remote.dart';
import '../../data/remote/mongodb/mongodb_service.dart';
import '../services/connectivity_service.dart';
import '../services/session_service.dart';

// ─── Enum hasil sync tiap item ────────────────────────────────────────────────
enum _SyncItemResult { success, failed, skipped }

// ─── SyncManager ─────────────────────────────────────────────────────────────
/// Service singleton yang mengelola sinkronisasi data offline → server.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  // ─── Dependency ─────────────────────────────────────────────────────────────
  final HiveService _hive = HiveService.instance;
  final SessionService _session = SessionService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final MongoDBService _db = MongoDBService.instance;
  final BookmarkRemote _bookmarkRemote = BookmarkRemote();
  final ProgressRemote _progressRemote = ProgressRemote();

  // ─── State internal ─────────────────────────────────────────────────────────
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  /// True jika proses sync sedang berjalan.
  bool get isSyncing => _isSyncing;

  /// Jumlah item yang sedang menunggu sync.
  int get pendingCount => _hive.syncQueueBox.length;

  // ─── Public API ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    startListening();
  }

  /// Mulai mendengarkan perubahan koneksi.
  void startListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (status) async {
        if (status != ConnectivityResult.none) {
          await syncAll();
          await syncPendingData();
        }
      },
    );

    // Coba sync langsung saat pertama kali app buka (jika sudah online)
    _trySyncOnStart();
  }

  /// Hentikan listener. Dipanggil saat app ditutup (opsional).
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> dispose() async {
    stopListening();
  }

  // ─── Queue Methods ─────────────────────────────────────────────────────────
  /// Tambahkan item baru ke antrian sinkronisasi secara umum.
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
      action: 'update_progress',
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
      action: isAdd ? 'bookmarkAdd' : 'bookmarkRemove',
      payload: {
        'user_id': userId,
        'question_id': questionId,
        'action': isAdd ? 'add' : 'remove',
      },
      createdAt: DateTime.now(),
    );
    await enqueue(item);
  }

  /// Sinkronisasi alternatif berdasarkan nama aksi mentah
  Future<void> enqueueBookmarkAction({
    required String userId,
    required String questionId,
    required String action, // Harus "bookmarkAdd" atau "bookmarkRemove" sesuai fallback logic
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final queueItem = SyncQueueModel(
      id: id,
      type: SyncType.bookmark,
      payload: {
        'user_id': userId,
        'question_id': questionId,
        'action': action == 'bookmarkAdd' ? 'add' : 'remove',
      },
      action: action,
      createdAt: DateTime.now(),
    );

    await _hive.syncQueueBox.put(queueItem.id, queueItem);
  }

  // ─── Sync Logic (Versi Baru / Queue Based) ─────────────────────────────────
  /// Proses semua item di antrian. Mengembalikan jumlah item yang sukses.
  Future<int> syncAll() async {
    if (_isSyncing) return 0;

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) return 0;

    _isSyncing = true;
    int successCount = 0;

    try {
      // Ambil semua item dari Hive, urutkan FIFO (First In First Out)
      final items = _hive.syncQueueBox.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final item in items) {
        final result = await _processItem(item);

        if (result == _SyncItemResult.success || result == _SyncItemResult.skipped) {
          await _hive.syncQueueBox.delete(item.id);
          if (result == _SyncItemResult.success) successCount++;
        }
      }
    } catch (e) {
      print('[SyncManager] syncAll() error: $e');
    } finally {
      _isSyncing = false;
    }

    return successCount;
  }

  // ─── Sync Logic (Fallback / Direct Sync) ───────────────────────────────────
  Future<void> syncPendingData() async {
    if (!_session.isLoggedIn) return;
    if (!await _connectivity.checkNow()) return;

    await _processBookmarkQueue();
    await _syncUnsyncedBookmarks();
    await _syncUnsyncedProgress();
  }

  Future<void> _processBookmarkQueue() async {
    final pending = _hive.syncQueueBox.values
        .where((item) => item.type == SyncType.bookmark)
        .toList();

    for (final item in pending) {
      final payload = item.payload;
      final userId = payload['user_id']?.toString() ?? payload['userId']?.toString() ?? '';
      final questionId = payload['question_id']?.toString() ?? payload['questionId']?.toString() ?? '';

      if (userId.isEmpty || questionId.isEmpty) {
        await _hive.syncQueueBox.delete(item.id);
        continue;
      }

      try {
        if (item.action == 'bookmarkAdd' || payload['action'] == 'add') {
          await _bookmarkRemote.addBookmark(
            userId: userId,
            questionId: questionId,
          );
        } else if (item.action == 'bookmarkRemove' || payload['action'] == 'remove') {
          await _bookmarkRemote.removeBookmark(
            userId: userId,
            questionId: questionId,
          );
        }
        await _hive.syncQueueBox.delete(item.id);
      } catch (_) {
        await _retryQueueItem(item);
      }
    }
  }

  Future<void> _syncUnsyncedBookmarks() async {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return;

    final unsynced = _hive.bookmarksBox.values
        .where((bookmark) => bookmark.userId == userId && !bookmark.isSynced)
        .toList();

    for (final bookmark in unsynced) {
      try {
        await _bookmarkRemote.addBookmark(
          userId: userId,
          questionId: bookmark.questionId,
        );

        final synced = bookmark.copyWith(isSynced: true);
        await _hive.bookmarksBox.put(bookmark.key ?? bookmark.id, synced);
      } catch (_) {}
    }
  }

  Future<void> _syncUnsyncedProgress() async {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return;

    final unsynced = _hive.userProgressBox.values
        .where((progress) => progress.userId == userId && !progress.isSynced)
        .toList();

    if (unsynced.isEmpty) return;

    final byCategory = <String, List<UserProgressModel>>{};

    for (final progress in unsynced) {
      final QuestionModel? question = _hive.questionsBox.get(progress.questionId);
      final categoryId = question?.kategoriId ?? '';
      if (categoryId.isEmpty) continue;

      byCategory.putIfAbsent(categoryId, () => []).add(progress);
    }

    for (final entry in byCategory.entries) {
      final categoryId = entry.key;
      final items = entry.value;
      final totalDiselesaikan = _hive.userProgressBox.values
          .where((p) => p.userId == userId && p.isSolved)
          .length;
      final jawabanBenar = totalDiselesaikan;

      try {
        await _progressRemote.syncUserProgress(
          userId: userId,
          categoryId: categoryId,
          totalDiselesaikan: totalDiselesaikan,
          jawabanBenar: jawabanBenar,
        );

        for (final item in items) {
          final synced = item.copyWith(isSynced: true);
          await _hive.userProgressBox.put(item.key ?? item.id, synced);
        }
      } catch (_) {}
    }
  }

  // ─── Helper Internal ────────────────────────────────────────────────────────
  Future<void> _trySyncOnStart() async {
    await Future.delayed(const Duration(seconds: 3));
    if (await _connectivity.checkNow()) {
      await syncAll();
      await syncPendingData();
    }
  }

  Future<_SyncItemResult> _processItem(SyncQueueModel item) async {
    // Membaca batas retry maksimal dari AppConstants (jika tidak ada, fallback ke 3)
    final maxRetry = AppConstants.maxSyncRetry; 
    if (item.retryCount >= maxRetry) {
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
      print('[SyncManager] Gagal sync item ${item.id}: $e');
      final updated = item.copyWith(retryCount: item.retryCount + 1);
      await _hive.syncQueueBox.put(item.id, updated);
      return _SyncItemResult.failed;
    }
  }

  Future<void> _retryQueueItem(SyncQueueModel item) async {
    final nextCount = item.retryCount + 1;
    if (nextCount >= 3) {
      await _hive.syncQueueBox.delete(item.id);
      return;
    }

    final updated = item.copyWith(retryCount: nextCount);
    await _hive.syncQueueBox.put(item.id, updated);
  }

  Future<void> _syncProgress(Map<String, dynamic> payload) async {
    final userId = payload['user_id'] as String?;
    final questionId = payload['question_id'] as String?;
    final categoryId = payload['category_id'] as String?;
    final isSolved = payload['is_solved'] as bool? ?? false;
    final attemptCount = payload['attempt_count'] as int? ?? 1;
    final solvedAtStr = payload['solved_at'] as String?;

    if (userId == null || questionId == null || categoryId == null) {
      throw Exception('Payload progress tidak lengkap: $payload');
    }

    final now = DateTime.now().toIso8601String();

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

  Future<void> _syncBookmark(Map<String, dynamic> payload) async {
    final userId = payload['user_id'] as String?;
    final questionId = payload['question_id'] as String?;
    final action = payload['action'] as String?;

    if (userId == null || questionId == null || action == null) {
      throw Exception('Payload bookmark tidak lengkap: $payload');
    }

    final col = _db.bookmarks;

    if (action == 'add') {
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