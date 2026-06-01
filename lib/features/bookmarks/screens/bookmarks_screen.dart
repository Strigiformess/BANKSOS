// lib/features/bookmarks/screens/bookmarks_screen.dart
// PIC: Seruni
// Sprint 3: Buat halaman Soal Tersimpan (list bookmark)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../question/screens/question_detail_screen.dart';

class _BookmarkEntry {
  final BookmarkModel bookmark;
  final QuestionModel question;
  const _BookmarkEntry({required this.bookmark, required this.question});
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  
  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }

  Future<void> _removeBookmark(_BookmarkEntry entry) async {
    // Gunakan fungsi hapus bawaan HiveObject
    await entry.bookmark.delete();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bookmark dihapus'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Oke', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawUserId = SessionService.instance.userId ?? '';
    final currentUserId = rawUserId.isNotEmpty ? _cleanId(rawUserId) : '';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Soal Tersimpan'),
      ),
      // MENGGUNAKAN VALUE LISTENABLE AGAR REAKTIF
      body: ValueListenableBuilder<Box<BookmarkModel>>(
        valueListenable: HiveService.instance.bookmarksBox.listenable(),
        builder: (context, box, _) {
          
          final bookmarks = box.values
              .where((b) => _cleanId(b.userId) == currentUserId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final questionBox = HiveService.instance.questionsBox;
          final entries = <_BookmarkEntry>[];

          for (final bm in bookmarks) {
            final targetQId = _cleanId(bm.questionId);
            QuestionModel? question;
            try { question = questionBox.get(targetQId); } catch (_) {}
            
            question ??= questionBox.values
                .where((q) => _cleanId(q.id) == targetQId)
                .firstOrNull;

            if (question != null) {
              entries.add(_BookmarkEntry(bookmark: bm, question: question));
            }
          }

          if (entries.isEmpty) {
            return const AppEmptyState(
              icon: Icons.bookmark_border_outlined,
              title: 'Belum ada soal tersimpan',
              subtitle: 'Tekan ikon bookmark di halaman soal untuk menyimpannya.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '${entries.length} soal',
                      style: AppTextStyles.smallSemibold.copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _BookmarkCard(
                    entry: entries[i],
                    onRemove: () => _removeBookmark(entries[i]),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuestionDetailScreen(question: entries[i].question)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
    return answer.trim().split(' ').map((word) => '_' * word.length).join(' ');
  }

  String _formatDate(DateTime dt) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
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
          color: AppColors.errorRed.withValues(alpha:0.1),
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_remove_outlined, color: AppColors.errorRed, size: 24),
            const SizedBox(height: 4),
            Text('Hapus', style: AppTextStyles.caption.copyWith(color: AppColors.errorRed)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Bookmark?'),
            content: const Text('Soal ini akan dihapus dari daftar tersimpan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ?? false;
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
                Row(
                  children: [
                    const Icon(Icons.bookmark, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    AppBadge.difficulty(difficulty),
                    const Spacer(),
                    Text(_formatDate(entry.bookmark.createdAt), style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Bookmark?'),
                            content: const Text('Soal ini akan dihapus dari daftar tersimpan.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) onRemove();
                      },
                      child: Icon(Icons.bookmark_remove_outlined, size: 18, color: AppColors.textGrey.withValues(alpha:0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.pertanyaan,
                  style: AppTextStyles.bodySemibold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(_buildPlaceholder(question.jawaban), style: AppTextStyles.answerPlaceholder),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(question.kategoriNama, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                    ),
                    if (question.hints.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.warningYellow),
                      const SizedBox(width: 2),
                      Text('${question.hints.length} hint', style: AppTextStyles.caption),
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