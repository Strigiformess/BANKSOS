// lib/core/services/sync_service.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';
import '../../data/local/hive/hive_service.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/sync_queue_model.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _uuid = const Uuid();

  // Fungsi Pembersih ID
  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }

  // ─── 1. FASE UI KE LOKAL (TOMBOL DITEKAN) ──────────────────────────────────

  /// Mengembalikan TRUE jika sekarang di-bookmark, FALSE jika dihapus
  Future<bool> toggleBookmark({
    required String userId,
    required String questionId,
  }) async {
    final hive = HiveService.instance.bookmarksBox;
    final queueBox = HiveService.instance.syncQueueBox;

    final cleanUserId = _cleanId(userId);
    final cleanQuestionId = _cleanId(questionId);

    final existingItems = hive.values.where((b) => 
        _cleanId(b.questionId) == cleanQuestionId && 
        _cleanId(b.userId) == cleanUserId).toList();
        
    final isAlreadyBookmarked = existingItems.isNotEmpty;
    final isOnline = await ConnectivityService.instance.isOnline;

    if (isAlreadyBookmarked) {
      // LOGIKA HAPUS BOOKMARK LAMA / BARU
      final bookmark = existingItems.first;
      
      // MENGGUNAKAN FUNGSI DELETE BAWAAN HIVEOBJECT (ANTI GAGAL)
      await bookmark.delete();
      
      if (isOnline) {
        try {
          // await BookmarkRemote().removeBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint("✅ Bookmark dihapus dari Cloud");
        } catch (e) {
          debugPrint("⚠️ Gagal hapus di Cloud: $e");
        }
      }
      return false; // Status sekarang: Dihapus
    } else {
      // LOGIKA TAMBAH BOOKMARK
      final newId = _uuid.v4().replaceAll('-', '').substring(0, 24); 
      final bookmark = BookmarkModel(
        id: newId,
        userId: cleanUserId,
        questionId: cleanQuestionId,
        createdAt: DateTime.now(),
        isSynced: isOnline,
      );

      // Simpan ke memori UI lokal 
      await hive.put(newId, bookmark);

      if (isOnline) {
        try {
          // await BookmarkRemote().addBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint("✅ Bookmark sukses dikirim ke Cloud");
        } catch (e) {
          await _queueForSync(bookmark, queueBox);
        }
      } else {
        await _queueForSync(bookmark, queueBox);
      }
      return true; // Status sekarang: Disimpan
    }
  }

  Future<void> _queueForSync(BookmarkModel bookmark, dynamic queueBox) async {
    bookmark = bookmark.copyWith(isSynced: false);
    await bookmark.save(); // Simpan perubahan status isSynced ke Hive

    final queueItem = SyncQueueModel(
      id: _uuid.v4(),
      type: SyncType.bookmark,
      payload: bookmark.toMap(),
      createdAt: DateTime.now(), action: '',
    );
    await queueBox.put(queueItem.id, queueItem);
    debugPrint("📥 Bookmark masuk antrean Offline (Queue ID: ${queueItem.id})");
  }

  // ─── 2. FASE LOKAL KE CLOUD (BACKGROUND WORKER) ────────────────────────────

  Future<void> flushQueue() async {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (!isOnline) return;

    final queueBox = HiveService.instance.syncQueueBox;
    if (queueBox.isEmpty) return;

    final pendingItems = queueBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    debugPrint("🔄 Memulai sinkronisasi ${pendingItems.length} antrean data...");

    for (final item in pendingItems) {
      bool success = false;

      try {
        if (item.type == SyncType.bookmark) {
          // await BookmarkRemote().addBookmark(userId: item.payload['user_id'], questionId: item.payload['question_id']);
          debugPrint("✅ Sync sukses: Bookmark (Queue ID: ${item.id})");
          success = true;

          final bookmarkId = item.payload['_id'];
          final localBookmark = HiveService.instance.bookmarksBox.values.where((b) => b.id == bookmarkId).firstOrNull;
          if (localBookmark != null) {
            await localBookmark.copyWith(isSynced: true).save();
          }
        }
      } catch (e) {
        debugPrint("❌ Sync gagal untuk item ${item.id}: $e");
        final updatedItem = item.copyWith(retryCount: item.retryCount + 1);
        await queueBox.put(item.id, updatedItem);
      }

      if (success) {
        await queueBox.delete(item.id);
      }
    }
  }
}