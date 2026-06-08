import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';
import '../../data/local/hive/hive_service.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/remote/bookmark_remote.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _uuid = const Uuid();

  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }

  Future<bool> toggleBookmark({
    required String userId,
    required String questionId,
  }) async {
    final hive = HiveService.instance.bookmarksBox;
    final queueBox = HiveService.instance.syncQueueBox;

    final cleanUserId = _cleanId(userId);
    final cleanQuestionId = _cleanId(questionId);

    final existingItems = hive.values
        .where((b) =>
            _cleanId(b.questionId) == cleanQuestionId &&
            _cleanId(b.userId) == cleanUserId)
        .toList();

    final isAlreadyBookmarked = existingItems.isNotEmpty;
    final isOnline = await ConnectivityService.instance.isOnline;

    if (isAlreadyBookmarked) {
      final bookmark = existingItems.first;
      await bookmark.delete();

      final queueItem = SyncQueueModel(
        id: _uuid.v4(),
        type: SyncType.bookmark,
        payload: {
          'user_id': cleanUserId,
          'question_id': cleanQuestionId,
          'action': 'remove',
        },
        action: SyncAction.bookmarkRemove.name,
        createdAt: DateTime.now(),
      );

      if (isOnline) {
        try {
          await BookmarkRemote()
              .removeBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint('✅ Bookmark dihapus dari Cloud');
        } catch (e) {
          debugPrint('⚠️ Gagal hapus langsung di Cloud, masuk antrean: $e');
          await queueBox.put(queueItem.id, queueItem);
        }
      } else {
        debugPrint('📴 Offline: Antrean hapus bookmark disimpan lokal');
        await queueBox.put(queueItem.id, queueItem);
      }

      return false;
    } else {
      final newId = _uuid.v4().replaceAll('-', '').substring(0, 24);
      final bookmark = BookmarkModel(
        id: newId,
        userId: cleanUserId,
        questionId: cleanQuestionId,
        createdAt: DateTime.now(),
        isSynced: isOnline,
      );

      await hive.put(newId, bookmark);

      final queueItem = SyncQueueModel(
        id: _uuid.v4(),
        type: SyncType.bookmark,
        payload: {
          'user_id': cleanUserId,
          'question_id': cleanQuestionId,
          'action': 'add',
        },
        action: SyncAction.bookmarkAdd.name,
        createdAt: DateTime.now(),
      );

      if (isOnline) {
        try {
          await BookmarkRemote()
              .addBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint('✅ Bookmark sukses dikirim ke Cloud');
        } catch (e) {
          debugPrint('⚠️ Gagal kirim langsung ke Cloud, masuk antrean: $e');
          await queueBox.put(queueItem.id, queueItem);
        }
      } else {
        debugPrint('📴 Offline: Antrean tambah bookmark disimpan lokal');
        await queueBox.put(queueItem.id, queueItem);
      }

      return true;
    }
  }

  Future<void> flushQueue() async {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (!isOnline) return;

    final queueBox = HiveService.instance.syncQueueBox;
    if (queueBox.isEmpty) return;

    final pendingItems = queueBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    debugPrint('🔄 Memulai sinkronisasi ${pendingItems.length} antrean data...');

    for (final item in pendingItems) {
      bool success = false;

      try {
        if (item.type == SyncType.bookmark) {
          final userId = item.payload['user_id'];
          final questionId = item.payload['question_id'];
          final action = item.payload['action'];

          if (action == 'add') {
            await BookmarkRemote()
                .addBookmark(userId: userId, questionId: questionId);

            final bookmarksBox = HiveService.instance.bookmarksBox;
            final localBookmark = bookmarksBox.values
                .where((b) =>
                    _cleanId(b.questionId) == questionId &&
                    _cleanId(b.userId) == userId)
                .firstOrNull;

            if (localBookmark != null) {
              final synced = localBookmark.copyWith(isSynced: true);
              await bookmarksBox.put(localBookmark.key, synced);
            }
          } else if (action == 'remove') {
            await BookmarkRemote()
                .removeBookmark(userId: userId, questionId: questionId);
          }

          debugPrint('✅ Sync sukses: Bookmark $action (Queue ID: ${item.id})');
          success = true;
        }
      } catch (e) {
        debugPrint('❌ Sync gagal untuk item ${item.id}: $e');
        final updatedItem = item.copyWith(retryCount: item.retryCount + 1);
        await queueBox.put(item.id, updatedItem);
      }

      if (success) {
        await queueBox.delete(item.id);
      }
    }
  }
}