// lib/features/question/screens/bank_soal_screen.dart
// PIC: Seruni Libertina Islami
// Collab: Revaldi untuk State Management
// Sprint 2 & 3: Halaman Bank Soal - UI Horizontal Chips 100% Figma Match & Clean

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/remote/category_remote.dart';
import '../../../data/remote/question_remote.dart';
import '../../question/screens/question_detail_screen.dart';

// ─── PROVIDERS ─────────────────────────────────────────────────────────────
final categoryProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final hive = HiveService.instance.categoriesBox;
  if (hive.isNotEmpty) return hive.values.where((c) => c.isActive).toList();
  
  final isOnline = await ConnectivityService.instance.isOnline;
  if (!isOnline) return [];

  try {
    final rawList = await CategoryRemote().getActiveCategories();
    final categories = rawList.map((m) => CategoryModel.fromMap(m)).toList();
    for (final cat in categories) { await hive.put(cat.id, cat); }
    return categories;
  } catch (e) {
    debugPrint('Fetch Category Error: $e');
    return []; 
  }
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final questionProvider = FutureProvider.autoDispose<List<QuestionModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final hive = HiveService.instance.questionsBox;
  final allLocal = hive.values.toList();
  final isOnline = await ConnectivityService.instance.isOnline;

  if (categoryId != null) {
    final localForCategory = allLocal.where((q) => q.kategoriId == categoryId).toList();
    if (localForCategory.isNotEmpty) {
      return localForCategory.where((q) => q.status == QuestionStatus.published).toList();
    }
    if (isOnline) {
      final rawList = await QuestionRemote().getPublishedQuestionsByCategory(categoryId);
      final fetched = rawList.map((m) => QuestionModel.fromMap(m)).toList();
      for (final q in fetched) { await hive.put(q.id, q); }
      return fetched.where((q) => q.status == QuestionStatus.published).toList();
    }
    return [];
  }
  return allLocal.where((q) => q.status == QuestionStatus.published).toList();
});

// ─── SCREEN ────────────────────────────────────────────────────────────────
class BankSoalScreen extends ConsumerStatefulWidget {
  const BankSoalScreen({super.key});
  @override
  ConsumerState<BankSoalScreen> createState() => _BankSoalScreenState();
}

class _BankSoalScreenState extends ConsumerState<BankSoalScreen> {
  DifficultyFilter _selectedDifficulty = DifficultyFilter.all;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QuestionModel> _applyFilters(List<QuestionModel> questions) {
    var filtered = questions;
    if (_selectedDifficulty != DifficultyFilter.all) {
      final levelMap = {
        DifficultyFilter.easy: DifficultyLevel.easy,
        DifficultyFilter.medium: DifficultyLevel.medium,
        DifficultyFilter.hard: DifficultyLevel.hard,
      };
      filtered = filtered.where((q) => q.tingkatKesulitan == levelMap[_selectedDifficulty]).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((q) => q.pertanyaan.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final questionsAsync = ref.watch(questionProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacings.sm),
            Text('BANKSOS', style: AppTextStyles.h2.copyWith(color: AppColors.primaryBlue)),
          ],
        ),
        backgroundColor: AppColors.bgWhite,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.bgWhite,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg, vertical: AppSpacings.sm),
            child: Column(
              children: [
                // Search Bar Sesuai Figma
                TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Cari materi atau topik...',
                    prefixIcon: Icon(Icons.search_outlined),
                    suffixIcon: Icon(Icons.tune_outlined),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacings.md),
                
                // Kategori Chips Sesuai Figma
                categoriesAsync.when(
                  data: (categories) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(null, 'Semua', selectedCategoryId == null),
                        ...categories.map((cat) => _buildCategoryChip(cat.id, cat.nama, selectedCategoryId == cat.id)),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Gagal memuat kategori'),
                ),
                const SizedBox(height: AppSpacings.sm),
                
                // Difficulty Chips
                AppDifficultyChips(
                  selected: _selectedDifficulty,
                  onChanged: (val) => setState(() => _selectedDifficulty = val),
                ),
              ],
            ),
          ),

          // Daftar Soal
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                final filtered = _applyFilters(questions);
                if (filtered.isEmpty) return const AppEmptyState(icon: Icons.inbox, title: 'Soal tidak ditemukan');
                return ListView.separated(
                  padding: AppSpacings.pagePadding,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacings.sm),
                  itemBuilder: (context, index) => _QuestionCard(question: filtered[index]),
                );
              },
              loading: () => const AppLoadingIndicator(),
              error: (err, __) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? id, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacings.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(selectedCategoryIdProvider.notifier).state = id;
          setState(() => _searchCtrl.clear());
          ref.invalidate(questionProvider);
        },
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.bgWhite,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        showCheckmark: false,
      ),
    );
  }
}

// ─── CARD SOAL ─────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.3)), // FIX: Deprecation withValues
      ),
      child: Padding(
        padding: AppSpacings.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(question.kategoriNama, style: AppTextStyles.captionBold.copyWith(color: AppColors.primaryBlue)),
                const Icon(Icons.bookmark_border, size: 20, color: AppColors.textGrey),
              ],
            ),
            const SizedBox(height: AppSpacings.xs),
            Text(question.pertanyaan, style: AppTextStyles.bodySemibold, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacings.md),
            Row(
              children: [
                AppBadge.difficulty(question.tingkatKesulitan.name),
                const SizedBox(width: AppSpacings.sm),
                Text('+25 pts', style: AppTextStyles.captionBold.copyWith(color: AppColors.textGrey)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionDetailScreen(question: question))),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: AppTextStyles.captionBold,
                  ),
                  child: const Text('Solve Now'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}