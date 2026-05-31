// lib/features/question/repositories/bookmark_repository.dart
// Sprint 3 — Revaldi (RP): Bookmark Repository
// TERINTEGRASI DENGAN FINAL SYNC SERVICE (ADJIE)

import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/question_model.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/sync_service.dart';

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

  final bool success;
  final bool isNowBookmarked;
  final String? message;
}

/// Implementasi bookmark_repository yang sudah dialirkan ke SyncService
class BookmarkRepository implements IBookmarkRepository {
  final HiveService _hive;
  final SessionService _session;

  BookmarkRepository({
    HiveService? hive,
    SessionService? session,
  })  : _hive = hive ?? HiveService.instance,
        _session = session ?? SessionService.instance;

  // Pembersih ID agar aman di pencarian lokal
  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }

  // ─── Toggle Bookmark (Dialirkan langsung ke SyncService) ───────────────
  
  Future<BookmarkResult> toggleBookmark(QuestionModel question) async {
    final rawUserId = _session.userId ?? '';
    if (rawUserId.isEmpty) {
      return const BookmarkResult(
        success: false,
        isNowBookmarked: false,
        message: 'Silakan login terlebih dahulu.',
      );
    }

    final userId = _cleanId(rawUserId);

    // SyncService akan mengurus Hive, MongoDB, Queue, dan Network Check secara otomatis!
    final isNowSaved = await SyncService.instance.toggleBookmark(
      userId: userId,
      questionId: question.id,
    );

    return BookmarkResult(
      success: true,
      isNowBookmarked: isNowSaved,
      message: isNowSaved ? 'Soal disimpan ke Bookmark.' : 'Bookmark dihapus.',
    );
  }

  // ─── Add & Remove (Dialihkan ke Toggle) ────────────────────────────────

  @override
  Future<BookmarkResult> addBookmark(QuestionModel question) async {
    if (isBookmarked(question.id)) {
      return const BookmarkResult(
        success: true,
        isNowBookmarked: true,
        message: 'Soal sudah ada di bookmark.',
      );
    }
    return toggleBookmark(question);
  }

  @override
  Future<BookmarkResult> removeBookmark(QuestionModel question) async {
    if (!isBookmarked(question.id)) {
      return const BookmarkResult(
        success: true,
        isNowBookmarked: false,
        message: 'Bookmark tidak ditemukan.',
      );
    }
    return toggleBookmark(question);
  }

  // ─── Read Data ──────────────────────────────────────────────────────────

  @override
  bool isBookmarked(String questionId) {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return false;

    final cUserId = _cleanId(userId);
    final cQuestionId = _cleanId(questionId);

    return _hive.bookmarksBox.values.any(
      (b) => _cleanId(b.questionId) == cQuestionId && _cleanId(b.userId) == cUserId,
    );
  }

  @override
  List<BookmarkModel> getBookmarks() {
    final userId = _session.userId ?? '';
    if (userId.isEmpty) return [];

    final cUserId = _cleanId(userId);

    final bookmarks = _hive.bookmarksBox.values
        .where((b) => _cleanId(b.userId) == cUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookmarks;
  }

  int get bookmarkCount {
    return getBookmarks().length;
  }
}