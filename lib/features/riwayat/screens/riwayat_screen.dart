// lib/features/riwayat/screens/riwayat_screen.dart
// Sprint 3 — Seruni (SL): Halaman Riwayat Pengerjaan

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../question/screens/question_detail_screen.dart';

// ─── Data holder ─────────────────────────────────────────────────────────────

class _RiwayatEntry {
  final UserProgressModel progress;
  final QuestionModel question;

  const _RiwayatEntry({required this.progress, required this.question});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<_RiwayatEntry> _allEntries  = [];
  List<_RiwayatEntry> _filtered    = [];
  List<CategoryModel> _categories  = [];
  String? _selectedCategoryId;       // null = Semua
  bool    _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // ─── Load data dari Hive ──────────────────────────────────────────────────

  void _loadRiwayat() {
    setState(() => _isLoading = true);

    final userId      = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;
    final categoryBox = HiveService.instance.categoriesBox;

    // Ambil progress yang sudah solved, urutkan paling baru
    final solvedList = progressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .toList()
      ..sort((a, b) =>
          (b.solvedAt ?? DateTime(0)).compareTo(a.solvedAt ?? DateTime(0)));

    final entries = <_RiwayatEntry>[];
    for (final p in solvedList) {
      QuestionModel? question = questionBox.get(p.questionId);
      question ??= questionBox.values
          .where((q) => q.id == p.questionId)
          .firstOrNull;

      if (question != null) {
        entries.add(_RiwayatEntry(progress: p, question: question));
      }
    }

    setState(() {
      _allEntries  = entries;
      _filtered    = entries;
      _categories  = categoryBox.values.where((c) => c.isActive).toList();
      _isLoading   = false;
    });
  }

  // ─── Filter per Kategori ──────────────────────────────────────────────────

  void _applyFilter(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filtered = categoryId == null
          ? _allEntries
          : _allEntries
              .where((e) => e.question.kategoriId == categoryId)
              .toList();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Riwayat Pengerjaan'),
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Statistik ringkas ───────────────────────────────────
                _buildStatsBar(),

                // ── Filter kategori ─────────────────────────────────────
                if (_categories.isNotEmpty) _buildCategoryFilter(),

                const Divider(height: 1),

                // ── List riwayat ────────────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? AppEmptyState(
                          icon: Icons.history_outlined,
                          title: _selectedCategoryId == null
                              ? 'Belum ada soal diselesaikan'
                              : 'Belum ada soal selesai di kategori ini',
                          subtitle: _selectedCategoryId == null
                              ? 'Kerjakan soal di Bank Soal untuk mulai mencatat progresmu.'
                              : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _loadRiwayat(),
                          color: AppColors.primaryBlue,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) => _RiwayatCard(
                              entry: _filtered[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuestionDetailScreen(
                                      question: _filtered[i].question,
                                    ),
                                  ),
                                );
                                _loadRiwayat(); // refresh setelah kembali
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ─── Widget: Stats Bar ────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    final totalSoal = HiveService.instance.questionsBox.values
        .where((q) => q.status == QuestionStatus.published)
        .length;
    final totalSelesai = _allEntries.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.bgWhite,
      child: Row(
        children: [
          // ── Soal selesai ──────────────────────────────────────────────
          _StatChip(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.successGreen,
            label: 'Diselesaikan',
            value: '$totalSelesai',
          ),
          const SizedBox(width: 12),

          // ── Total soal ────────────────────────────────────────────────
          if (totalSoal > 0)
            _StatChip(
              icon: Icons.quiz_outlined,
              iconColor: AppColors.primaryBlue,
              label: 'Total Soal',
              value: '$totalSoal',
            ),
          const Spacer(),

          // ── Persentase ────────────────────────────────────────────────
          if (totalSoal > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(totalSelesai / totalSoal * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const Text('progress', style: AppTextStyles.caption),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Widget: Category Filter ──────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Chip "Semua"
          _FilterChip(
            label: 'Semua',
            isSelected: _selectedCategoryId == null,
            onTap: () => _applyFilter(null),
          ),
          const SizedBox(width: 6),
          // Chip per kategori (hanya yang ada di riwayat)
          ..._categories
              .where((cat) =>
                  _allEntries.any((e) => e.question.kategoriId == cat.id))
              .map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChip(
                    label: cat.nama,
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () => _applyFilter(cat.id),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ─── Chip Filter ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color: isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.h3.copyWith(color: AppColors.textDark),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

// ─── Card Riwayat ──────────────────────────────────────────────────────────────

class _RiwayatCard extends StatelessWidget {
  final _RiwayatEntry entry;
  final VoidCallback onTap;

  const _RiwayatCard({required this.entry, required this.onTap});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final question = entry.question;
    final progress = entry.progress;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: AppSpacings.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ikon centang hijau ──────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.easyBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // ── Konten ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pertanyaan
                    Text(
                      question.pertanyaan,
                      style: AppTextStyles.bodySemibold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Kategori + tanggal selesai
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            question.kategoriNama,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(progress.solvedAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Badge kesulitan + percobaan
                    Row(
                      children: [
                        AppBadge.difficulty(question.tingkatKesulitan.name),
                        const SizedBox(width: 8),
                        if (progress.attemptCount > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.bgBlue,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              '${progress.attemptCount}x percobaan',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Chevron ────────────────────────────────────────────
              const Icon(
                Icons.chevron_right,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}