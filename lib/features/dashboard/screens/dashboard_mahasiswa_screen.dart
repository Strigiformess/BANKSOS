// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
// REFACTOR: Semua data dummy diganti dengan data real dari Hive / MongoDB

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../shared/layouts/main_shell.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// Menghitung total poin berdasarkan soal yang diselesaikan.
/// Easy = 25 poin, Medium = 50 poin, Hard = 100 poin.
final _totalPointsProvider = Provider<int>((ref) {
  final userId = SessionService.instance.userId ?? '';
  final progressBox = HiveService.instance.userProgressBox;
  final questionBox = HiveService.instance.questionsBox;

  int total = 0;
  for (final p in progressBox.values) {
    if (p.userId != userId || !p.isSolved) continue;
    final q = questionBox.get(p.questionId) ??
        questionBox.values.where((q) => q.id == p.questionId).firstOrNull;
    if (q == null) continue;
    switch (q.tingkatKesulitan) {
      case DifficultyLevel.easy:
        total += 25;
        break;
      case DifficultyLevel.medium:
        total += 50;
        break;
      case DifficultyLevel.hard:
        total += 100;
        break;
    }
  }
  return total;
});

/// Label rank berdasarkan total poin.
String _rankLabel(int points) {
  if (points >= 5000) return 'Master';
  if (points >= 2000) return 'Expert';
  if (points >= 1000) return 'Scholar';
  if (points >= 500) return 'Learner';
  return 'Explorer';
}

/// Poin threshold untuk naik ke rank berikutnya.
int _nextRankThreshold(int points) {
  if (points >= 5000) return 5000;
  if (points >= 2000) return 5000;
  if (points >= 1000) return 2000;
  if (points >= 500) return 1000;
  return 500;
}

String _nextRankLabel(int points) {
  if (points >= 5000) return 'Max Rank';
  if (points >= 2000) return 'Master';
  if (points >= 1000) return 'Expert';
  if (points >= 500) return 'Scholar';
  return 'Learner';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DashboardMahasiswaScreen extends ConsumerStatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  ConsumerState<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState
    extends ConsumerState<DashboardMahasiswaScreen> {
  static const Color _rankGold   = Color(0xFFFFD700);
  static const Color _rankSilver = Color(0xFFC0C0C0);
  static const Color _rankBronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final nama = SessionService.instance.nama?.split(' ').first ?? 'Pengguna';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(nama),
              _buildSyncStatusBanner(),
              const SizedBox(height: AppSpacings.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRankCard(),
                    const SizedBox(height: AppSpacings.md),
                    _buildProgressSummary(),
                    const SizedBox(height: AppSpacings.md),
                    _buildStreakStatusRow(),
                    const SizedBox(height: AppSpacings.xxl),
                    _buildMenuUtama(),
                    const SizedBox(height: AppSpacings.xxl),
                    _buildRekomendasi(),
                    const SizedBox(height: AppSpacings.xxl),
                    _buildSoalTerbaru(),
                    const SizedBox(height: AppSpacings.xxl),
                    _buildTopStudents(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(String nama) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacings.lg, AppSpacings.md, AppSpacings.lg, 0),
      child: Row(
        children: [
          UserAvatar(
            name: nama,
            size: 40,
            bgColor: AppColors.primaryBlue.withOpacity(0.1),
          ),
          const SizedBox(width: AppSpacings.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo,',
                  style: AppTextStyles.small.copyWith(
                      color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text(nama,
                      style: AppTextStyles.h3.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: AppSpacings.xs),
                  const Text('👋', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildConnectivityBadge(),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBanner() {
    return StreamBuilder<ConnectivityResult>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityResult.none,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
              AppSpacings.lg, AppSpacings.sm, AppSpacings.lg, 0),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacings.sm, horizontal: AppSpacings.md),
          decoration: BoxDecoration(
            color: isOnline
                ? AppColors.successGreen.withOpacity(0.12)
                : AppColors.errorRed.withOpacity(0.12),
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: isOnline
                  ? AppColors.successGreen.withOpacity(0.2)
                  : AppColors.errorRed.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: isOnline ? AppColors.successGreen : AppColors.errorRed,
                size: 18,
              ),
              const SizedBox(width: AppSpacings.sm),
              Expanded(
                child: Text(
                  isOnline
                      ? 'Semua data tersinkronisasi'
                      : 'Tidak ada koneksi. Data akan tersimpan offline.',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Rank Card (data real dari Hive) ─────────────────────────────────────
  Widget _buildRankCard() {
    final totalPoints = ref.watch(_totalPointsProvider);
    final rank = _rankLabel(totalPoints);
    final nextThreshold = _nextRankThreshold(totalPoints);
    final nextRank = _nextRankLabel(totalPoints);
    final progress =
        nextThreshold > 0 ? (totalPoints / nextThreshold).clamp(0.0, 1.0) : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacings.lg + 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: AppRadius.xlAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT RANK',
                        style: AppTextStyles.captionBold
                            .copyWith(color: Colors.white70, letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacings.xs),
                    Text(rank,
                        style: AppTextStyles.h1
                            .copyWith(color: Colors.white, fontSize: 26)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacings.md, vertical: AppSpacings.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Column(
                  children: [
                    Text('Total Points',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white70)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatNumber(totalPoints),
                            style:
                                AppTextStyles.h2.copyWith(color: Colors.white),
                          ),
                          TextSpan(
                            text: ' pts',
                            style: AppTextStyles.small
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.lg),
          if (totalPoints < 5000) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}% to $nextRank',
                    style: AppTextStyles.smallSemibold
                        .copyWith(color: Colors.white)),
                Text('${_formatNumber(nextThreshold)} pts',
                    style:
                        AppTextStyles.small.copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: AppSpacings.sm),
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.successGreen),
              ),
            ),
          ] else
            Text('Rank Tertinggi Dicapai! 🏆',
                style: AppTextStyles.smallSemibold
                    .copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  // ─── Progress Summary (data real dari Hive) ───────────────────────────────
  Widget _buildProgressSummary() {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;

    final totalSelesai = progressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;
    final totalSoal = questionBox.values
        .where((q) => q.status == QuestionStatus.published)
        .length;
    final totalBookmark = HiveService.instance.bookmarksBox.values
        .where((b) => b.userId == userId)
        .length;
    final persen =
        totalSoal > 0 ? (totalSelesai / totalSoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacings.lg),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progres Belajar', style: AppTextStyles.h3),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.riwayat),
                child: Text('Lihat Riwayat',
                    style: AppTextStyles.smallSemibold
                        .copyWith(color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalSoal > 0
                    ? '$totalSelesai dari $totalSoal soal'
                    : '$totalSelesai soal diselesaikan',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
              Text('${(persen * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySemibold
                      .copyWith(color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: persen,
              minHeight: 8,
              backgroundColor: AppColors.lightBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: AppSpacings.md),
          Row(
            children: [
              _MiniStat(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.successGreen,
                label: 'Selesai',
                value: '$totalSelesai',
              ),
              const SizedBox(width: AppSpacings.xl),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.bookmarks),
                child: _MiniStat(
                  icon: Icons.bookmark_outline,
                  iconColor: Colors.amber,
                  label: 'Tersimpan',
                  value: '$totalBookmark',
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.kontribusi),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Kontribusi'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  textStyle:
                      AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Streak & Status Row ──────────────────────────────────────────────────
  Widget _buildStreakStatusRow() {
    return Row(
      children: [
        Expanded(child: _buildStreakCard()),
        const SizedBox(width: AppSpacings.md),
        Expanded(child: _buildDynamicStatusCard()),
      ],
    );
  }

  /// Hitung streak dari data progress Hive berdasarkan hari berurutan.
  Widget _buildStreakCard() {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;

    // Kumpulkan tanggal unik (per hari) di mana user menyelesaikan soal
    final solvedDates = progressBox.values
        .where((p) => p.userId == userId && p.isSolved && p.solvedAt != null)
        .map((p) => DateTime(
            p.solvedAt!.year, p.solvedAt!.month, p.solvedAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (solvedDates.isNotEmpty) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      DateTime check = todayOnly;

      for (final d in solvedDates) {
        if (d == check || d == check.subtract(const Duration(days: 1))) {
          streak++;
          check = d;
        } else {
          break;
        }
      }
    }

    return Container(
      padding: AppSpacings.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warningYellow.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: AppSpacings.sm),
              Text('Streak',
                  style: AppTextStyles.smallSemibold
                      .copyWith(color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          Text('$streak Days',
              style: AppTextStyles.h2.copyWith(color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildDynamicStatusCard() {
    return StreamBuilder<ConnectivityResult>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityResult.none,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        return Container(
          padding: AppSpacings.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: AppRadius.lgAll,
            border:
                Border.all(color: AppColors.borderGrey.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : AppColors.errorRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: isOnline
                          ? AppColors.primaryBlue
                          : AppColors.errorRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacings.sm),
                  Text('Status',
                      style: AppTextStyles.smallSemibold
                          .copyWith(color: AppColors.textGrey)),
                ],
              ),
              const SizedBox(height: AppSpacings.sm),
              Text(
                isOnline ? 'Synced' : 'Offline',
                style: AppTextStyles.h2.copyWith(
                  color: isOnline
                      ? AppColors.primaryBlue
                      : AppColors.errorRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Menu Utama ───────────────────────────────────────────────────────────
  Widget _buildMenuUtama() {
    final menus = [
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Bank Soal',
        'onTap': () => MainShell.of(context)?.jumpTo(1),
      },
      {
        'icon': Icons.bookmark_rounded,
        'label': 'Bookmark',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.bookmarks),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Statistik',
        'onTap': () => MainShell.of(context)?.jumpTo(3),
      },
      {
        'icon': Icons.wifi_off_rounded,
        'label': 'Offline',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.offlineSoal),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Utama', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacings.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: menus.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isFirst = i == 0;
            return GestureDetector(
              onTap: m['onTap'] as VoidCallback?,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppColors.primaryBlue
                          : AppColors.bgWhite,
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: Icon(m['icon'] as IconData,
                        color: isFirst ? Colors.white : AppColors.primaryBlue,
                        size: 26),
                  ),
                  const SizedBox(height: AppSpacings.sm),
                  Text(m['label'] as String,
                      style: AppTextStyles.smallSemibold
                          .copyWith(color: AppColors.textDark)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Rekomendasi (data real dari Hive categories) ─────────────────────────
  Widget _buildRekomendasi() {
    final categoryBox = HiveService.instance.categoriesBox;
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;
    final userId = SessionService.instance.userId ?? '';

    // Ambil kategori aktif, prioritaskan yang belum diselesaikan semua soalnya
    final categories = categoryBox.values.where((c) => c.isActive).toList();

    // Hitung soal tersedia dan selesai per kategori
    List<Map<String, dynamic>> rekomendasi = [];
    for (final cat in categories) {
      final soalKategori = questionBox.values
          .where((q) =>
              q.kategoriId == cat.id && q.status == QuestionStatus.published)
          .length;
      if (soalKategori == 0) continue;

      final selesai = progressBox.values
          .where((p) =>
              p.userId == userId &&
              p.isSolved &&
              questionBox.values.any(
                  (q) => q.id == p.questionId && q.kategoriId == cat.id))
          .length;

      rekomendasi.add({
        'category': cat,
        'soalCount': soalKategori,
        'selesai': selesai,
        'progress': soalKategori > 0 ? selesai / soalKategori : 0.0,
      });
    }

    // Urutkan: yang paling belum selesai di atas, ambil 2 teratas
    rekomendasi.sort(
        (a, b) => (a['progress'] as double).compareTo(b['progress'] as double));
    final tampil = rekomendasi.take(2).toList();

    if (tampil.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekomendasi Matkul', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacings.md),
          Container(
            padding: AppSpacings.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('Belum ada kategori tersedia.',
                  style: AppTextStyles.body),
            ),
          ),
        ],
      );
    }

    final gradients = [
      [const Color(0xFF0D2B55), const Color(0xFF1A4A8A)],
      [const Color(0xFF0A3040), const Color(0xFF155570)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rekomendasi Matkul', style: AppTextStyles.h2),
            GestureDetector(
              onTap: () => MainShell.of(context)?.jumpTo(1),
              child: Text('Lihat Semua',
                  style: AppTextStyles.smallSemibold
                      .copyWith(color: AppColors.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacings.md),
        Row(
          children: tampil.asMap().entries.map((entry) {
            final i = entry.key;
            final data = entry.value;
            final cat = data['category'] as CategoryModel;
            final soalCount = data['soalCount'] as int;
            final selesai = data['selesai'] as int;
            final isLast = i == tampil.length - 1;

            return Expanded(
              child: Container(
                margin:
                    EdgeInsets.only(right: isLast ? 0 : AppSpacings.md),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(
                      color: AppColors.borderGrey.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg)),
                        gradient: LinearGradient(
                          colors: gradients[i % gradients.length],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -10,
                            child: Icon(Icons.computer,
                                size: 80,
                                color: Colors.white.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacings.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgBlue,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              '$selesai/$soalCount',
                              style: AppTextStyles.captionBold
                                  .copyWith(color: AppColors.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: AppSpacings.xs),
                          Text(
                            cat.nama,
                            style: AppTextStyles.bodySemibold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$soalCount Soal Tersedia',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Soal Terbaru (data real dari Hive) ──────────────────────────────────
  Widget _buildSoalTerbaru() {
    final questionBox = HiveService.instance.questionsBox;

    // Ambil 5 soal published terbaru berdasarkan updatedAt
    final soalTerbaru = questionBox.values
        .where((q) => q.status == QuestionStatus.published)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final tampil = soalTerbaru.take(5).toList();

    if (tampil.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Soal Terbaru', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacings.md),
          Container(
            padding: AppSpacings.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('Belum ada soal tersedia.', style: AppTextStyles.body),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Soal Terbaru', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacings.md),
        ...tampil.map((q) {
          final selisihJam =
              DateTime.now().difference(q.updatedAt).inHours;
          String waktuLabel;
          if (selisihJam < 1) {
            waktuLabel = 'Baru saja';
          } else if (selisihJam < 24) {
            waktuLabel = '$selisihJam jam lalu';
          } else {
            final hari = selisihJam ~/ 24;
            waktuLabel = '$hari hari lalu';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacings.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacings.md, vertical: AppSpacings.md),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                  color: AppColors.borderGrey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgBlue,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Icon(Icons.quiz_outlined,
                      color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: AppSpacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.pertanyaan,
                        style: AppTextStyles.bodySemibold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${q.kategoriNama} • $waktuLabel',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacings.sm),
                AppBadge.difficulty(q.tingkatKesulitan.name),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Top Students (data real dari Hive) ──────────────────────────────────
  Widget _buildTopStudents() {
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;

    // Hitung poin per userId
    final Map<String, int> poinPerUser = {};
    for (final p in progressBox.values) {
      if (!p.isSolved) continue;
      final q = questionBox.get(p.questionId) ??
          questionBox.values
              .where((q) => q.id == p.questionId)
              .firstOrNull;
      if (q == null) continue;
      int poin = 0;
      switch (q.tingkatKesulitan) {
        case DifficultyLevel.easy:
          poin = 25;
          break;
        case DifficultyLevel.medium:
          poin = 50;
          break;
        case DifficultyLevel.hard:
          poin = 100;
          break;
      }
      poinPerUser[p.userId] = (poinPerUser[p.userId] ?? 0) + poin;
    }

    // Urutkan dan ambil top 3
    final sorted = poinPerUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacings.sm),
            Text('Top Students', style: AppTextStyles.h2),
          ]),
          const SizedBox(height: AppSpacings.md),
          Container(
            padding: AppSpacings.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('Belum ada data peringkat.', style: AppTextStyles.body),
            ),
          ),
        ],
      );
    }

    final rankColors = [_rankGold, _rankSilver, _rankBronze];
    final currentUserId = SessionService.instance.userId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacings.sm),
          Text('Top Students', style: AppTextStyles.h2),
        ]),
        const SizedBox(height: AppSpacings.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
          ),
          child: Column(
            children: top3.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final isLast = i == top3.length - 1;
              final isCurrentUser = e.key == currentUserId;

              // Tampilkan nama dari session jika current user,
              // atau gunakan ID singkat untuk user lain
              final namaDisplay = isCurrentUser
                  ? (SessionService.instance.nama ?? 'Kamu')
                  : 'Pengguna #${e.key.substring(0, 8)}';

              return Column(
                children: [
                  Padding(
                    padding: AppSpacings.listItemPadding,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.bodySemibold.copyWith(
                                color: rankColors[i], fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacings.xs),
                        UserAvatar(
                          name: namaDisplay,
                          size: 38,
                          bgColor: rankColors[i].withOpacity(0.15),
                        ),
                        const SizedBox(width: AppSpacings.md),
                        Expanded(
                          child: Text(
                            namaDisplay,
                            style: AppTextStyles.bodySemibold.copyWith(
                              color: isCurrentUser
                                  ? AppColors.primaryBlue
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatNumber(e.value)} pts',
                          style: AppTextStyles.smallSemibold
                              .copyWith(color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: AppSpacings.xl,
                        endIndent: AppSpacings.xl),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Connectivity Badge ───────────────────────────────────────────────────
  Widget _buildConnectivityBadge() {
    return StreamBuilder<ConnectivityResult>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityResult.none,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: isOnline ? AppColors.bgBlue : AppColors.errorRed,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync : Icons.cloud_off_outlined,
                color: isOnline ? AppColors.primaryBlue : AppColors.errorRed,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'Synced' : 'Offline',
                style: AppTextStyles.smallSemibold.copyWith(
                  color: isOnline ? AppColors.primaryBlue : AppColors.errorRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      final s = value.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return value.toString();
  }
}

// ─── Helper widget ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.bodySemibold
                    .copyWith(color: AppColors.textDark)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}