// lib/features/kontribusi/screens/kontribusi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/question_model.dart';
import '../controllers/kontribusi_controller.dart';

class KontribusiScreen extends ConsumerWidget {
  const KontribusiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userQuestions = ref.watch(kontribusiProvider);
    final rewardPoints = ref.watch(rewardPointsProvider);
    final stats = ref.watch(kontribusiStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Kontribusiku'),
        backgroundColor: AppColors.bgWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primaryBlue),
            onPressed: () {
              ref.invalidate(kontribusiProvider);
              ref.invalidate(rewardPointsProvider);
              ref.invalidate(kontribusiStatsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () => Navigator.pushNamed(context, '/submit-soal'),
        child: const Icon(Icons.add, color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: AppSpacings.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage and track your question submissions',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: AppSpacings.lg),
            
            // ─── Stat Cards Sesuai Desain Figma (ANTI OVERFLOW) ───────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: AppSpacings.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            // FIX: FittedBox agar teks "TOTAL SUBMITTED" bisa mengecil di layar sempit
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('TOTAL SUBMITTED', style: AppTextStyles.smallSemibold.copyWith(color: AppColors.textGrey)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacings.sm),
                        Text(stats.total.toString(), style: AppTextStyles.h2.copyWith(color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacings.md),
                Expanded(
                  child: Container(
                    padding: AppSpacings.cardPadding,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIX: FittedBox untuk judul poin reward
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('REWARD POINTS', style: AppTextStyles.smallSemibold.copyWith(color: AppColors.lightBlue)),
                        ),
                        const SizedBox(height: AppSpacings.sm),
                        Row(
                          children: [
                            const Icon(Icons.stars,
                                color: AppColors.warningYellow, size: 24),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(rewardPoints.toString(), style: AppTextStyles.h2.copyWith(color: AppColors.textLight)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacings.md),

            // ─── Status Breakdown ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatusPill(
                    label: 'Diterima',
                    count: stats.published,
                    bg: AppColors.publishedBg,
                    fg: AppColors.publishedText,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: AppSpacings.sm),
                Expanded(
                  child: _StatusPill(
                    label: 'Pending',
                    count: stats.pending,
                    bg: AppColors.pendingBg,
                    fg: AppColors.pendingText,
                    icon: Icons.access_time_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacings.sm),
                Expanded(
                  child: _StatusPill(
                    label: 'Ditolak',
                    count: stats.rejected,
                    bg: AppColors.rejectedBg,
                    fg: AppColors.rejectedText,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacings.xxl),

            // ─── Keterangan poin ─────────────────────────────────────────
            Container(
              padding: AppSpacings.cardPadding,
              decoration: AppDecorations.bannerInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skema Poin Kontribusi',
                    style: AppTextStyles.smallSemibold
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 6),
                  const _PoinInfo(label: 'Easy (Mudah)', poin: 10),
                  const _PoinInfo(label: 'Medium (Sedang)', poin: 20),
                  const _PoinInfo(label: 'Hard (Sulit)', poin: 30),
                  const SizedBox(height: 4),
                  Text(
                    'Poin hanya diberikan untuk soal yang sudah disetujui reviewer.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacings.xxl),
            const Text('Recent Submissions', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacings.sm),

            // ─── List Kontribusi ──────────────────────────────────────────
            userQuestions.isEmpty
                ? const AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada kontribusi',
                    subtitle:
                        'Klik tombol + untuk mengirim soal baru.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userQuestions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacings.sm),
                    itemBuilder: (context, index) {
                      final item = userQuestions[index];
                      return _buildKontribusiCard(context, item);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildKontribusiCard(BuildContext context, QuestionModel item) {
    // Poin yang diperoleh dari soal ini
    int poin = 0;
    if (item.status == QuestionStatus.published) {
      switch (item.tingkatKesulitan) {
        case DifficultyLevel.easy:
          poin = 10;
          break;
        case DifficultyLevel.medium:
          poin = 20;
          break;
        case DifficultyLevel.hard:
          poin = 30;
          break;
      }
    }

    return Card(
      elevation: 0,
      color: AppColors.bgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.4)), 
      ),
      child: Padding(
        padding: AppSpacings.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge.status(item.status.name),
                Row(
                  children: [
                    if (poin > 0) ...[
                      const Icon(Icons.stars,
                          size: 14, color: AppColors.warningYellow),
                      const SizedBox(width: 3),
                      Text('+$poin pts',
                          style: AppTextStyles.captionBold
                              .copyWith(color: AppColors.warningYellow)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacings.sm),
            Text(item.pertanyaan, style: AppTextStyles.bodySemibold),
            const SizedBox(height: AppSpacings.sm),
            Row(
              children: [
                const Icon(Icons.folder_outlined,
                    size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(item.kategoriNama, style: AppTextStyles.caption),
                const SizedBox(width: 8),
                AppBadge.difficulty(item.tingkatKesulitan.name),
              ],
            ),
            if (item.status == QuestionStatus.rejected &&
                item.rejectionReason != null) ...[
              const SizedBox(height: AppSpacings.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      _showAlasanDialog(context, item.rejectionReason!),
                  child: const Text('Lihat Alasan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAlasanDialog(BuildContext context, String alasan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Alasan Penolakan', style: AppTextStyles.h2),
        content: Text(alasan, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.count,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(height: 4),
          Text('$count',
              style: AppTextStyles.h3.copyWith(color: fg)),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: fg),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PoinInfo extends StatelessWidget {
  final String label;
  final int poin;

  const _PoinInfo({required this.label, required this.poin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.primaryBlue)),
          const Spacer(),
          Text('+$poin pts',
              style: AppTextStyles.smallSemibold
                  .copyWith(color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
}