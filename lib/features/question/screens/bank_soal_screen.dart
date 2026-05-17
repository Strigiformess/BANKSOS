// lib/features/questions/screens/bank_soal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../features/auth/data/category_remote.dart';
import '../../../features/auth/data/question_remote.dart';
import '../../question/screens/question_detail_screen.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final categoryProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final hive = HiveService.instance.categoriesBox;
  if (hive.isNotEmpty) {
    return hive.values.where((c) => c.isActive).toList();
  }

  final isOnline = await ConnectivityService.instance.isOnline;
  if (!isOnline) return [];

  final rawList = await CategoryRemote().getActiveCategories();
  final categories = rawList.map((m) => CategoryModel.fromMap(m)).toList();
  for (final cat in categories) {
    await hive.put(cat.id, cat);
  }
  return categories;
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final questionProvider =
    FutureProvider.autoDispose<List<QuestionModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final hive = HiveService.instance.questionsBox;

  List<QuestionModel> all = hive.values.toList();

  if (all.isEmpty && categoryId != null) {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (isOnline) {
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);
      final fetched = rawList.map((m) => QuestionModel.fromMap(m)).toList();
      for (final q in fetched) {
        await hive.put(q.id, q);
      }
      all = fetched;
    }
  }

  if (categoryId != null) {
    all = all
        .where((q) =>
            q.kategoriId == categoryId &&
            q.status == QuestionStatus.published)
        .toList();
  } else {
    all = all.where((q) => q.status == QuestionStatus.published).toList();
  }

  return all;
});

final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return ConnectivityService.instance.onConnectivityChanged;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class BankSoalScreen extends ConsumerStatefulWidget {
  const BankSoalScreen({super.key});

  @override
  ConsumerState<BankSoalScreen> createState() => _BankSoalScreenState();
}

class _BankSoalScreenState extends ConsumerState<BankSoalScreen> {
  bool _isSidebarOpen = true;

  // Filter kesulitan — pakai enum dari app_widgets
  DifficultyFilter _selectedDifficulty = DifficultyFilter.all;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  bool   _isDownloading    = false;
  double _downloadProgress = 0;
  String _downloadStatus   = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Download untuk offline ───────────────────────────────────────────────

  Future<void> _downloadForOffline(
      String categoryId, String categoryName) async {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada koneksi internet. Unduh gagal.'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading    = true;
      _downloadProgress = 0;
      _downloadStatus   = 'Mengambil soal $categoryName...';
    });

    try {
      setState(() => _downloadProgress = 0.3);
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);

      setState(() {
        _downloadProgress = 0.6;
        _downloadStatus   = 'Menyimpan ${rawList.length} soal...';
      });

      final hive = HiveService.instance.questionsBox;
      for (final raw in rawList) {
        final question = QuestionModel.fromMap(raw);
        await hive.put(question.id, question);
      }

      setState(() => _downloadProgress = 1.0);
      ref.invalidate(questionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${rawList.length} soal $categoryName berhasil diunduh.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading    = false;
          _downloadProgress = 0;
          _downloadStatus   = '';
        });
      }
    }
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<QuestionModel> _applyFilters(List<QuestionModel> questions) {
    var filtered = questions;

    if (_selectedDifficulty != DifficultyFilter.all) {
      final levelMap = {
        DifficultyFilter.easy:   DifficultyLevel.easy,
        DifficultyFilter.medium: DifficultyLevel.medium,
        DifficultyFilter.hard:   DifficultyLevel.hard,
      };
      filtered = filtered
          .where((q) => q.tingkatKesulitan == levelMap[_selectedDifficulty])
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((q) => q.pertanyaan
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoriesAsync    = ref.watch(categoryProvider);
    final questionsAsync     = ref.watch(questionProvider);
    final connectivityAsync  = ref.watch(connectivityProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    final isOffline = connectivityAsync.when(
      data: (results) =>
          results.contains(ConnectivityResult.none) || results.isEmpty,
      loading: () => false,
      error:   (_, __) => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Soal'),
        leading: IconButton(
          icon: Icon(
            _isSidebarOpen
                ? Icons.menu_open_outlined
                : Icons.menu_outlined,
          ),
          tooltip:
              _isSidebarOpen ? 'Tutup Kategori' : 'Buka Kategori',
          onPressed: () =>
              setState(() => _isSidebarOpen = !_isSidebarOpen),
        ),
        actions: [
          if (selectedCategoryId != null)
            categoriesAsync.when(
              data: (categories) {
                final match = categories
                    .where((c) => c.id == selectedCategoryId)
                    .toList();
                final categoryName =
                    match.isNotEmpty ? match.first.nama : 'Soal';
                return IconButton(
                  icon: _isDownloading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: _downloadProgress,
                            color: AppColors.textLight,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_outlined),
                  tooltip: 'Unduh untuk Offline',
                  onPressed: _isDownloading
                      ? null
                      : () => _downloadForOffline(
                            selectedCategoryId,
                            categoryName,
                          ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner Offline — pakai OfflineBanner dari app_widgets ───────
          if (isOffline) const OfflineBanner(),

          // ── Progress Bar Unduh ─────────────────────────────────────────
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppColors.lightBlue,
              color: AppColors.primaryBlue,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(_downloadStatus, style: AppTextStyles.small),
                  const Spacer(),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: AppTextStyles.smallSemibold
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ],

          // ── Konten Utama: Sidebar + Daftar Soal ───────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sidebar Kategori ───────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarOpen ? 150 : 0,
                  child: _isSidebarOpen
                      ? _buildSidebar(categoriesAsync, selectedCategoryId)
                      : const SizedBox.shrink(),
                ),

                if (_isSidebarOpen)
                  const VerticalDivider(width: 1, thickness: 1),

                // ── Kolom Kanan ────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari soal...',
                            isDense: true,
                            prefixIcon: const Icon(
                                Icons.search_outlined,
                                size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(
                                          () => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                        ),
                      ),

                      // Filter Chip — pakai AppDifficultyChips ──────────
                      AppDifficultyChips(
                        selected: _selectedDifficulty,
                        onChanged: (val) =>
                            setState(() => _selectedDifficulty = val),
                      ),

                      const Divider(height: 1),

                      // Daftar Soal
                      Expanded(
                        child: questionsAsync.when(
                          loading: () =>
                              const AppLoadingIndicator(),
                          error: (e, _) => _buildError(e.toString()),
                          data: (questions) {
                            final filtered =
                                _applyFilters(questions);
                            if (filtered.isEmpty) {
                              return _buildEmpty(
                                  selectedCategoryId);
                            }
                            return _buildQuestionList(filtered);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar Kategori ─────────────────────────────────────────────────────

  Widget _buildSidebar(
    AsyncValue<List<CategoryModel>> categoriesAsync,
    String? selectedCategoryId,
  ) {
    return Container(
      color: AppColors.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text('Mata Kuliah', style: AppTextStyles.captionBold),
          ),
          _buildCategoryItem(
            id: null,
            label: 'Semua',
            icon: Icons.grid_view_outlined,
            isSelected: selectedCategoryId == null,
          ),
          const Divider(height: 8, indent: 12, endIndent: 12),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Gagal memuat kategori',
                    style: AppTextStyles.small
                        .copyWith(color: AppColors.errorRed)),
              ),
              data: (categories) => ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  return _buildCategoryItem(
                    id: cat.id,
                    label: cat.nama,
                    icon: Icons.book_outlined,
                    isSelected: selectedCategoryId == cat.id,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String? id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(selectedCategoryIdProvider.notifier).state = id;
        setState(() {
          _selectedDifficulty = DifficultyFilter.all;
          _searchCtrl.clear();
          _searchQuery = '';
        });
        ref.invalidate(questionProvider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.08)
              : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(
                      color: AppColors.primaryBlue, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.small.copyWith(
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Daftar Soal ──────────────────────────────────────────────────────────

  Widget _buildQuestionList(List<QuestionModel> questions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _QuestionCard(
          question: questions[index],
          nomor: index + 1,
        );
      },
    );
  }

  // ─── Empty & Error State ──────────────────────────────────────────────────

  /// Pakai AppEmptyState dari app_widgets
  Widget _buildEmpty(String? categoryId) {
    return AppEmptyState(
      icon: categoryId == null
          ? Icons.menu_book_outlined
          : Icons.inbox_outlined,
      title: _searchQuery.isNotEmpty
          ? 'Soal tidak ditemukan'
          : categoryId == null
              ? 'Pilih mata kuliah di sidebar'
              : 'Belum ada soal',
      subtitle: _searchQuery.isNotEmpty
          ? null
          : categoryId == null
              ? null
              : 'Coba unduh soal terlebih dahulu.',
      action: _searchQuery.isNotEmpty
          ? TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Hapus pencarian'),
            )
          : null,
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Soal ────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int nomor;

  const _QuestionCard({required this.question, required this.nomor});

  String _buildPlaceholder(String answer) {
    return answer
        .trim()
        .split(' ')
        .map((word) => '_' * word.length)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  QuestionDetailScreen(question: question),
            ),
          );
        },
        child: Padding(
          padding: AppSpacings.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: nomor + badge kesulitan + hint count + bookmark
              Row(
                children: [
                  // Nomor soal
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: AppRadius.smAll,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$nomor',
                      style: AppTextStyles.captionBold
                          .copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge kesulitan — pakai AppBadge.difficulty() ─────────
                  AppBadge.difficulty(question.tingkatKesulitan.name),

                  const Spacer(),

                  // Ikon hint
                  if (question.hints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              size: 14,
                              color: AppColors.warningYellow),
                          const SizedBox(width: 2),
                          Text(
                            '${question.hints.length}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),

                  Icon(
                    Icons.bookmark_border_outlined,
                    size: 18,
                    color: AppColors.textGrey.withOpacity(0.5),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Pertanyaan
              Text(question.pertanyaan, style: AppTextStyles.bodySemibold),

              const SizedBox(height: 8),

              // Placeholder jawaban
              Text(
                _buildPlaceholder(question.jawaban),
                style: AppTextStyles.answerPlaceholder,
              ),

              const SizedBox(height: 8),

              // Kategori
              Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(question.kategoriNama,
                      style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}