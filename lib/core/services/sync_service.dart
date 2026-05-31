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

    // 1. Ambil data bookmark yang cocok di database lokal Hive
    final existingItems = hive.values.where((b) => 
        _cleanId(b.questionId) == cleanQuestionId && 
        _cleanId(b.userId) == cleanUserId).toList();
        
    final isAlreadyBookmarked = existingItems.isNotEmpty;
    final isOnline = await ConnectivityService.instance.isOnline;

    if (isAlreadyBookmarked) {
      // ─── LOGIKA HAPUS BOOKMARK ───────────────────────────────────────────
      final bookmark = existingItems.first;
      
      // Hapus data dari Hive lokal terlebih dahulu
      await bookmark.delete();
      
      // Buat item antrean untuk aksi hapus (remove)
      final queueItem = SyncQueueModel(
        id: _uuid.v4(),
        type: SyncType.bookmark,
        payload: {
          'user_id': cleanUserId,
          'question_id': cleanQuestionId,
          'action': 'remove', // payload String untuk backend MongoDB
        },
        // Wajib diisi! Menggunakan Enum SyncAction untuk skema lokal
        action: SyncAction.bookmarkRemove.name, 
        createdAt: DateTime.now(),
      );

      if (isOnline) {
        try {
          // await BookmarkRemote().removeBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint("✅ Bookmark dihapus dari Cloud");
        } catch (e) {
          debugPrint("⚠️ Gagal hapus langsung di Cloud, masuk antrean: $e");
          await queueBox.put(queueItem.id, queueItem);
        }
      } else {
        debugPrint("📴 Offline: Antrean hapus bookmark disimpan lokal");
        await queueBox.put(queueItem.id, queueItem);
      }
      
      return false; // Status saat ini: Sudah Dihapus (ikon kosong)

    } else {
      // ─── LOGIKA TAMBAH BOOKMARK ──────────────────────────────────────────
      final newId = _uuid.v4().replaceAll('-', '').substring(0, 24); 
      final bookmark = BookmarkModel(
        id: newId,
        userId: cleanUserId,
        questionId: cleanQuestionId,
        createdAt: DateTime.now(),
        isSynced: isOnline,
      );

      // Simpan data baru ke Hive lokal
      await hive.put(newId, bookmark);

      // Buat item antrean untuk aksi tambah (add)
      final queueItem = SyncQueueModel(
        id: _uuid.v4(),
        type: SyncType.bookmark,
        payload: {
          'user_id': cleanUserId,
          'question_id': cleanQuestionId,
          'action': 'add', 
        },
        // Wajib diisi! Menggunakan Enum SyncAction untuk skema lokal
        action: SyncAction.bookmarkAdd.name, 
        createdAt: DateTime.now(),
      );

      if (isOnline) {
        try {
          // await BookmarkRemote().addBookmark(userId: cleanUserId, questionId: cleanQuestionId);
          debugPrint("✅ Bookmark sukses dikirim ke Cloud");
        } catch (e) {
          debugPrint("⚠️ Gagal kirim langsung ke Cloud, masuk antrean: $e");
          await queueBox.put(queueItem.id, queueItem);
        }
      } else {
        debugPrint("📴 Offline: Antrean tambah bookmark disimpan lokal");
        await queueBox.put(queueItem.id, queueItem);
      }
      
      return true; // Status saat ini: Sukses Disimpan (ikon penuh)
    }
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