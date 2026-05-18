// lib/features/question/repositories/bookmark_repository.dart
// Sprint 3 — Revaldi (RP): Bookmark Repository
//
// Tanggung jawab:
//   - addBookmark    : simpan bookmark ke Hive (selalu) + kirim ke server (jika online)
//   - removeBookmark : hapus bookmark dari Hive (selalu) + hapus dari server (jika online)
//   - isBookmarked   : cek apakah soal sudah di-bookmark oleh user ini di Hive
//   - getBookmarks   : ambil semua bookmark user dari Hive
//
// Alur offline-first:
//   1. Setiap operasi SELALU dilakukan ke Hive terlebih dahulu.
//   2. Jika device online, operasi dikirim ke server (via BookmarkRemote).
//   3. Jika device offline, data tetap tersimpan di Hive dengan is_synced=false.
//   4. SyncManager (Sprint 5) yang akan mengirim data is_synced=false ke server nanti.

import 'package:uuid/uuid.dart';

import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/question_model.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../features/auth/data/bookmark_remote.dart';

/// Abstraksi interface agar mudah di-mock saat unit test.
abstract class IBookmarkRepository {
  Future<BookmarkResult> addBookmark(QuestionModel question);
  Future<BookmarkResult> removeBookmark(QuestionModel question);
  bool isBookmarked(String questionId);
  List<BookmarkModel> getBookmarks();
}

/// Hasil operasi bookmark — membawa status dan pesan untuk UI.
class BookmarkResult {
  const BookmarkResult({
    required this.success,
    required this.isNowBookmarked,
    this.message,
  });

  /// Apakah operasi berhasil dilakukan (minimal ke Hive).
  final bool success;

  /// Status bookmark setelah operasi ini (true = soal sudah di-bookmark).
  final bool isNowBookmarked;

  /// Pesan opsional untuk ditampilkan ke user via SnackBar.
  final String? message;
}

/// Implementasi bookmark_repository dengan pendekatan offline-first.
class BookmarkRepository implements IBookmarkRepository {
  final HiveService _hive;
  final SessionService _session;
  final ConnectivityService _connectivity;
  final BookmarkRemote _remote;

  BookmarkRepository({
    HiveService? hive,
    SessionService? session,
    ConnectivityService? connectivity,
    BookmarkRemote? remote,
  })  : _hive = hive ?? HiveService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance,
        _remote = remote ?? BookmarkRemote();

  // ─── Add Bookmark 

  @override
  Future<BookmarkResult> addBookmark(QuestionModel question) async {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) {
      return const BookmarkResult(
        success: false,
        isNowBookmarked: false,
        message: 'Silakan login terlebih dahulu.',
      );
    }

    if (isBookmarked(question.id)) {
      return const BookmarkResult(
        success: true,
        isNowBookmarked: true,
        message: 'Soal sudah ada di bookmark.',
      );
    }

    // 1. Simpan ke Hive (operasi lokal — selalu berhasil)
    const uuid = Uuid();
    final bookmark = BookmarkModel(
      id: uuid.v4(),
      userId: userId,
      questionId: question.id,
      createdAt: DateTime.now(),
      isSynced: false, // akan diupdate jika sync ke server berhasil
    );

    final box = _hive.bookmarksBox;
    await box.put(bookmark.id, bookmark);

    // 2. Coba kirim ke server jika online
    final isOnline = await _connectivity.checkNow();
    if (isOnline) {
      try {
        await _remote.addBookmark(
          userId: userId,
          questionId: question.id,
        );
        // Update flag is_synced = true di Hive
        final synced = bookmark.copyWith(isSynced: true);
        await box.put(synced.id, synced);
      } catch (_) {
        // Gagal kirim ke server — tidak apa-apa, akan di-sync nanti
        // Tidak perlu rollback Hive karena offline-first
      }
    }

    return const BookmarkResult(
      success: true,
      isNowBookmarked: true,
      message: 'Soal disimpan ke Bookmark.',
    );
  }

  // ─── Remove Bookmark ──────────────────────────────────────────────────────

  @override
  Future<BookmarkResult> removeBookmark(QuestionModel question) async {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) {
      return const BookmarkResult(
        success: false,
        isNowBookmarked: true,
        message: 'Silakan login terlebih dahulu.',
      );
    }

    final box = _hive.bookmarksBox;

    // Cari bookmark di Hive
    final toDelete = box.values
        .where((b) => b.questionId == question.id && b.userId == userId)
        .toList();

    if (toDelete.isEmpty) {
      return const BookmarkResult(
        success: true,
        isNowBookmarked: false,
        message: 'Bookmark tidak ditemukan.',
      );
    }

    // 1. Hapus dari Hive (selalu)
    for (final b in toDelete) {
      await box.delete(b.key);
    }

    // 2. Coba hapus dari server jika online
    final isOnline = await _connectivity.checkNow();
    if (isOnline) {
      try {
        await _remote.removeBookmark(
          userId: userId,
          questionId: question.id,
        );
      } catch (_) {
        // Gagal hapus dari server — tidak kritis, data di Hive sudah dihapus
        // SyncManager bisa handle perbedaan ini di Sprint 5
      }
    }

    return const BookmarkResult(
      success: true,
      isNowBookmarked: false,
      message: 'Bookmark dihapus.',
    );
  }

  // ─── Toggle Bookmark (convenience method) ────────────────────────────────

  Future<BookmarkResult> toggleBookmark(QuestionModel question) async {
    if (isBookmarked(question.id)) {
      return removeBookmark(question);
    } else {
      return addBookmark(question);
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  @override
  bool isBookmarked(String questionId) {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return false;

    return _hive.bookmarksBox.values.any(
      (b) => b.questionId == questionId && b.userId == userId,
    );
  }

  /// Ambil semua bookmark milik user yang sedang login, urut terbaru dulu.
  @override
  List<BookmarkModel> getBookmarks() {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return [];

    final bookmarks = _hive.bookmarksBox.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookmarks;
  }

  /// Jumlah soal yang di-bookmark oleh user saat ini.
  int get bookmarkCount {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return 0;
    return _hive.bookmarksBox.values
        .where((b) => b.userId == userId)
        .length;
  }
}