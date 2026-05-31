import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/local/hive/hive_service.dart';
import '../../data/models/question_model.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/models/user_progress_model.dart';
import '../../features/auth/data/bookmark_remote.dart';
import '../../features/auth/data/progress_remote.dart';
import '../services/connectivity_service.dart';
import '../services/session_service.dart';

/// Manager sinkronisasi data offline.
///
/// - Bookmark add/remove dibuat queue ketika offline.
/// - Progress yang belum tersinkronisasi dikirim saat kembali online.
/// - Scan queue dan retry otomatis setiap kali koneksi internet tersedia.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final HiveService _hive = HiveService.instance;
  final SessionService _session = SessionService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final BookmarkRemote _bookmarkRemote = BookmarkRemote();
  final ProgressRemote _progressRemote = ProgressRemote();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> init() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (status) async {
        if (status != ConnectivityResult.none) {
          await syncPendingData();
        }
      },
    );

    if (await _connectivity.checkNow()) {
      await syncPendingData();
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

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
      final userId = payload['userId']?.toString() ?? '';
      final questionId = payload['questionId']?.toString() ?? '';

      if (userId.isEmpty || questionId.isEmpty) {
        await item.delete();
        continue;
      }

      try {
        if (item.action == SyncAction.bookmarkAdd.name) {
          await _bookmarkRemote.addBookmark(
            userId: userId,
            questionId: questionId,
          );
        } else if (item.action == SyncAction.bookmarkRemove.name) {
          await _bookmarkRemote.removeBookmark(
            userId: userId,
            questionId: questionId,
          );
        }

        await item.delete();
      } catch (_) {
        await _retryQueueItem(item);
      }
    }
  }

  Future<void> _retryQueueItem(SyncQueueModel item) async {
    final nextCount = item.retryCount + 1;
    if (nextCount >= 3) {
      await item.delete();
      return;
    }

    final updated = item.copyWith(retryCount: nextCount);
    await _hive.syncQueueBox.put(item.key, updated);
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
      } catch (_) {
        // Biarkan SyncManager mencoba lagi nanti.
      }
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
      } catch (_) {
        // Biarkan SyncManager mencoba lagi nanti.
      }
    }
  }

  Future<void> enqueueBookmarkAction({
    required String userId,
    required String questionId,
    required String action,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final queueItem = SyncQueueModel(
      id: id,
      type: SyncType.bookmark,
      payload: {
        'userId': userId,
        'questionId': questionId,
      },
      action: action,
      createdAt: DateTime.now(),
    );

    await _hive.syncQueueBox.put(queueItem.id, queueItem);
  }
}
