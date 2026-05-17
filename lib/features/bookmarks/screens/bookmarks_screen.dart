// lib/features/bookmarks/screens/bookmarks_screen.dart
// Sprint 3 — Seruni (SL): Halaman Soal Tersimpan

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../question/screens/question_detail_screen.dart';

// ─── Data holder ─────────────────────────────────────────────────────────────

class _BookmarkEntry {
  final BookmarkModel bookmark;
  final QuestionModel question;

  const _BookmarkEntry({required this.bookmark, required this.question});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<_BookmarkEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  void _loadBookmarks() {
    setState(() => _isLoading = true);

    final userId = SessionService.instance.userId ?? '';
    final bookmarkBox = HiveService.instance.bookmarksBox;
    final questionBox = HiveService.instance.questionsBox;

    // Ambil semua bookmark user, urutkan terbaru dulu
    final bookmarks = bookmarkBox.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final entries = <_BookmarkEntry>[];
    for (final bm in bookmarks) {
      // Cari soal dari Hive (key = question.id)
      QuestionModel? question = questionBox.get(bm.questionId);
      // Fallback linear scan jika key tidak match
      question ??= questionBox.values
          .where((q) => q.id == bm.questionId)
          .firstOrNull;

      if (question != null) {
        entries.add(_BookmarkEntry(bookmark: bm, question: question));
      }
    }

    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  // ─── Hapus Bookmark ───────────────────────────────────────────────────────

  Future<void> _removeBookmark(_BookmarkEntry entry) async {
    final box = HiveService.instance.bookmarksBox;
    await box.delete(entry.bookmark.key);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bookmark dihapus'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Oke',
            onPressed: () {},
          ),
        ),
      );
    }

    _loadBookmarks();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Soal Tersimpan'),
        actions: [
          if (_entries.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${_entries.length} soal',
                  style: AppTextStyles.smallSemibold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : _entries.isEmpty
              ? const AppEmptyState(
                  icon: Icons.bookmark_border_outlined,
                  title: 'Belum ada soal tersimpan',
                  subtitle:
                      'Tekan ikon bookmark di halaman soal untuk menyimpannya.',
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadBookmarks(),
                  color: AppColors.primaryBlue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _BookmarkCard(
                      entry: _entries[i],
                      onRemove: () => _removeBookmark(_entries[i]),
                      onTap: () => _openQuestion(_entries[i]),
                    ),
                  ),
                ),
    );
  }

  // Buka halaman detail soal, lalu reload bookmark saat kembali
  // (user mungkin unbookmark dari dalam halaman soal)
  Future<void> _openQuestion(_BookmarkEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionDetailScreen(question: entry.question),
      ),
    );
    _loadBookmarks(); // refresh karena mungkin ada perubahan bookmark
  }
}

// ─── Card Bookmark ────────────────────────────────────────────────────────────

class _BookmarkCard extends StatelessWidget {
  final _BookmarkEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.entry,
    required this.onRemove,
    required this.onTap,
  });

  String _buildPlaceholder(String answer) {
    return answer
        .trim()
        .split(' ')
        .map((word) => '_' * word.length)
        .join(' ');
  }

  String _formatDate(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final question = entry.question;
    final difficulty = question.tingkatKesulitan.name;

    return Dismissible(
      key: Key(entry.bookmark.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.1),
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_remove_outlined,
                color: AppColors.errorRed, size: 24),
            const SizedBox(height: 4),
            Text(
              'Hapus',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.errorRed),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Bookmark?'),
            content: const Text(
                'Soal ini akan dihapus dari daftar tersimpan kamu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onRemove(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: AppSpacings.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Baris atas ─────────────────────────────────────────
                Row(
                  children: [
                    // Ikon bookmark terisi (penanda sudah tersimpan)
                    const Icon(
                      Icons.bookmark,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),

                    // Badge kesulitan
                    AppBadge.difficulty(difficulty),

                    const Spacer(),

                    // Tanggal disimpan
                    Text(
                      _formatDate(entry.bookmark.createdAt),
                      style: AppTextStyles.caption,
                    ),

                    const SizedBox(width: 8),

                    // Tombol hapus
                    GestureDetector(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Bookmark?'),
                            content: const Text(
                                'Soal ini akan dihapus dari daftar tersimpan.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.errorRed),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) onRemove();
                      },
                      child: Icon(
                        Icons.bookmark_remove_outlined,
                        size: 18,
                        color: AppColors.textGrey.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Pertanyaan ─────────────────────────────────────────
                Text(
                  question.pertanyaan,
                  style: AppTextStyles.bodySemibold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // ── Placeholder jawaban ─────────────────────────────────
                Text(
                  _buildPlaceholder(question.jawaban),
                  style: AppTextStyles.answerPlaceholder,
                ),

                const SizedBox(height: 8),

                // ── Footer: kategori + hint count ───────────────────────
                Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        question.kategoriNama,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (question.hints.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lightbulb_outline,
                          size: 13, color: AppColors.warningYellow),
                      const SizedBox(width: 2),
                      Text(
                        '${question.hints.length} hint',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}