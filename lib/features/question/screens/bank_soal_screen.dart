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
import '../../../routes/app_routes.dart';
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

  final allLocal = hive.values.toList();
  final isOnline = await ConnectivityService.instance.isOnline;

  if (categoryId != null) {
    final localForCategory = allLocal
        .where((q) => q.kategoriId == categoryId)
        .toList();

    if (localForCategory.isNotEmpty) {
      return localForCategory
          .where((q) => q.status == QuestionStatus.published)
          .toList();
    }

    if (isOnline) {
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);
      final fetched = rawList.map((m) => QuestionModel.fromMap(m)).toList();
      for (final q in fetched) {
        await hive.put(q.id, q);
      }
      return fetched
          .where((q) => q.status == QuestionStatus.published)
          .toList();
    }

    return [];
  }

  final all = allLocal
      .where((q) => q.status == QuestionStatus.published)
      .toList();

  return all;
});

final connectivityProvider =
    StreamProvider<ConnectivityResult>((ref) {
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Download untuk offline dengan batch write yang proper ──────────────────

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
    });

    try {
      setState(() => _downloadProgress = 0.3);
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);

      setState(() {
        _downloadProgress = 0.6;
      });

      final hive = HiveService.instance.questionsBox;
      
      // ✅ FIX: Batch write untuk menghindari corrupt data & lock file
      final questions = <String, QuestionModel>{};
      for (final raw in rawList) {
        final question = QuestionModel.fromMap(raw);
        questions[question.id] = question;
      }
      
      // Simpan semua sekaligus (atomic operation)
      await hive.putAll(questions);

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
        });
      }
    }
  }

  // ─── Filter 

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

  // ─── Build 

  @override
  Widget build(BuildContext context) {
    final categoriesAsync    = ref.watch(categoryProvider);
    final questionsAsync     = ref.watch(questionProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

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
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home_outlined),
                      tooltip: 'Beranda',
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.dashboardMahasiswa,
                        (route) => false,
                      ),
                    ),
                    IconButton(
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
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Row(
        children: [
          // ─── Sidebar Kategori ────────────────────────────────────────────────
          if (_isSidebarOpen)
            categoriesAsync.when(
              data: (categories) => Container(
                width: 200,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppColors.borderGrey.withOpacity(0.5),
                    ),
                  ),
                  color: AppColors.bgWhite,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Kategori',
                        style:
                            AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...List.generate(
                      categories.length,
                      (i) {
                        final cat = categories[i];
                        return _buildCategoryItem(
                          id: cat.id,
                          label: cat.nama,
                          icon: Icons.book_outlined,
                          isSelected: selectedCategoryId == cat.id,
                        );
                      },
                    ),
                  ],
                ),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(child: Text('Error: $err')),
            ),

          // ─── Main Content Area ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ─── Search & Filter Bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Cari soal...',
                          prefixIcon: const Icon(Icons.search_outlined),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_outlined),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mdAll,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Filter kesulitan
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: DifficultyFilter.values.map((filter) {
                            final filterLabels = {
                              DifficultyFilter.all: 'Semua',
                              DifficultyFilter.easy: 'Mudah',
                              DifficultyFilter.medium: 'Sedang',
                              DifficultyFilter.hard: 'Sulit',
                            };
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filterLabels[filter] ?? filter.name),
                                selected:
                                    _selectedDifficulty == filter,
                                onSelected: (_) {
                                  setState(() =>
                                      _selectedDifficulty = filter);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Daftar Soal ─────────────────────────────────────────────
                Expanded(
                  child: questionsAsync.when(
                    data: (questions) {
                      final filtered = _applyFilters(questions);
                      if (filtered.isEmpty) {
                        return _buildEmpty(selectedCategoryId);
                      }
                      return _buildQuestionList(filtered);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, __) =>
                        _buildError('Error: ${err.toString()}'),
                  ),
                ),
              ],
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

// ─── Card Soal 

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