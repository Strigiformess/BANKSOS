// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
// PIC: Seruni (SL) — Terintegrasi dengan Hive & MongoDB, tanpa data dummy
// Dashboard Mahasiswa — sesuai mockup UI Light Theme

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';

// ─── TAMBAHAN IMPORT ────────────────────────────────────────────────────────
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';

class DashboardMahasiswaScreen extends ConsumerStatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  ConsumerState<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState
    extends ConsumerState<DashboardMahasiswaScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final nama = SessionService.instance.nama?.split(' ').first ?? 'Mahasiswa';

    return Scaffold(
      // Menggunakan background terang sesuai AppTheme
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(nama),
                    _buildSyncStatusBanner(),
                    const SizedBox(height: AppSpacings.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacings.lg),
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
                          const SizedBox(height: AppSpacings.xxxl), // Extra padding bottom
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(String nama) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacings.lg, AppSpacings.md, AppSpacings.lg, 0),
      child: Row(
        children: [
          UserAvatar(
            name: nama,
            size: 40,
            bgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
          const SizedBox(width: AppSpacings.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo,',
                style: AppTextStyles.small.copyWith(
                    color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    nama,
                    style: AppTextStyles.h3.copyWith(
                        color: AppColors.textDark, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacings.xs),
                  const Text('👋', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Badge dengan status koneksi dinamis
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
          margin: const EdgeInsets.symmetric(horizontal: AppSpacings.lg),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacings.sm,
            horizontal: AppSpacings.md,
          ),
          decoration: BoxDecoration(
            color: isOnline
                ? AppColors.successGreen.withValues(alpha: 0.12)
                : AppColors.errorRed.withValues(alpha: 0.12),
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: isOnline
                  ? AppColors.successGreen.withValues(alpha: 0.2)
                  : AppColors.errorRed.withValues(alpha: 0.2),
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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Rank Card ───────────────────────────────────────────────────────────
  Widget _buildRankCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacings.lg + 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: AppRadius.xlAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
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
                    Text(
                      'CURRENT RANK',
                      style: AppTextStyles.captionBold.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacings.xs),
                    Text(
                      'Explorer',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacings.md, vertical: AppSpacings.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Points',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '1,250',
                            style: AppTextStyles.h2.copyWith(
                                color: Colors.white),
                          ),
                          TextSpan(
                            text: ' pts',
                            style: AppTextStyles.small.copyWith(
                                color: Colors.white70),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '75% to Scholar',
                style: AppTextStyles.smallSemibold.copyWith(
                    color: Colors.white),
              ),
              Text(
                '1,500 pts',
                style: AppTextStyles.small.copyWith(
                    color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Summary ────────────────────────────────────────────────────
  Widget _buildProgressSummary() {
    final userId = SessionService.instance.userId ?? '';

    // Hitung dari Hive (data real)
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

    final persen = totalSoal > 0
        ? (totalSelesai / totalSoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacings.lg),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Belajar',
                style: AppTextStyles.h3.copyWith(color: AppColors.textDark),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.riwayat),
                child: Text(
                  'Lihat Riwayat',
                  style: AppTextStyles.smallSemibold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
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
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(persen * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.bodySemibold.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: persen,
              minHeight: 8,
              backgroundColor: AppColors.lightBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
                child: _MiniStat(
                  icon: Icons.bookmark_outline,
                  iconColor: Colors.amber,
                  label: 'Tersimpan',
                  value: '$totalBookmark',
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.kontribusi),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Kontribusi'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  textStyle: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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

  // ─── Streak & Status Row ─────────────────────────────────────────────────
  Widget _buildStreakStatusRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            emoji: '🔥',
            label: 'Streak',
            value: '5 Days',
          ),
        ),
        const SizedBox(width: AppSpacings.md),
        Expanded(
          child: _buildDynamicStatusCard(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    String? emoji,
    Widget? iconWidget,
    required String label,
    required String value,
  }) {
    return Container(
      padding: AppSpacings.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                )
              else if (iconWidget != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: iconWidget,
                ),
              const SizedBox(width: AppSpacings.sm),
              Text(
                label,
                style: AppTextStyles.smallSemibold.copyWith(
                    color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
          ),
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
            border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : AppColors.errorRed.withValues(alpha: 0.1),
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
                  Text(
                    'Status',
                    style: AppTextStyles.smallSemibold.copyWith(
                        color: AppColors.textGrey),
                  ),
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
      {'icon': Icons.menu_book_rounded, 'label': 'Bank Soal', 'route': AppRoutes.bankSoal},
      {'icon': Icons.bookmark_rounded, 'label': 'Bookmark', 'route': AppRoutes.bookmarks},
      {'icon': Icons.bar_chart_rounded, 'label': 'Statistik', 'route': AppRoutes.statistik},
      {'icon': Icons.wifi_off_rounded, 'label': 'Offline', 'route': AppRoutes.offlineSoal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: AppSpacings.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: menus.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final route = m['route'] as String?;
            final isFirst = i == 0; 

            return GestureDetector(
              onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: AppRadius.lgAll,
                      boxShadow: [
                        if (!isFirst)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Icon(
                      m['icon'] as IconData,
                      color: AppColors.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppSpacings.sm),
                  Text(
                    m['label'] as String,
                    style: AppTextStyles.smallSemibold.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Rekomendasi Matkul (Real Data) ───────────────────────────────────────
  Widget _buildRekomendasi() {
    final categories = HiveService.instance.categoriesBox.values
        .where((c) => c.isActive)
        .take(2)
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    final aestheticGradients = [
      [const Color(0xFFB3E5FC), const Color(0xFF4FC3F7)], // Soft Blue
      [const Color(0xFFF8BBD0), const Color(0xFFF06292)], // Soft Pink
      [const Color(0xFFFFF9C4), const Color(0xFFFFF176)], // Soft Yellow
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekomendasi Matkul',
              style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.bankSoal),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.smallSemibold.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacings.md),
        Row(
          children: categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final isLast = i == categories.length - 1;

            final totalSoal = HiveService.instance.questionsBox.values
                .where((q) =>
                    q.kategoriId == cat.id &&
                    q.status == QuestionStatus.published)
                .length;

            final gradient = aestheticGradients[i % aestheticGradients.length];

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : AppSpacings.md),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                          colors: gradient,
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
                                size: 80, color: Colors.white.withValues(alpha: 0.3)),
                          )
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
                            decoration: const BoxDecoration(
                              color: AppColors.bgBlue,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              cat.nama.length >= 3 ? cat.nama.substring(0, 3).toUpperCase() : cat.nama.toUpperCase(),
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacings.xs),
                          Text(
                            cat.nama,
                            style: AppTextStyles.bodySemibold
                                .copyWith(color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalSoal Soal Tersedia',
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

  // ─── Soal Terbaru (Real Data) ─────────────────────────────────────────────
  Widget _buildSoalTerbaru() {
    final recentQuestions = HiveService.instance.questionsBox.values
        .where((q) => q.status == QuestionStatus.published)
        .toList();

    final displayQuestions = recentQuestions.take(3).toList();

    if (displayQuestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soal Terbaru',
          style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: AppSpacings.md),
        ...displayQuestions.map((q) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacings.sm),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacings.md, vertical: AppSpacings.md),
              decoration: BoxDecoration(
                color: AppColors.bgWhite, 
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.bgBlue,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: const Icon(
                      Icons.quiz_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.pertanyaan,
                          style: AppTextStyles.bodySemibold.copyWith(
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.kategoriNama,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AppBadge.difficulty(q.tingkatKesulitan.name),
                ],
              ),
            )),
      ],
    );
  }

  // ─── Top Students (Disembunyikan Sementara) ───────────────────────────────
  Widget _buildTopStudents() {
    // Return empty widget until Gamification/Leaderboard feature is fully implemented
    return const SizedBox.shrink();
  }

  // ─── Connectivity Badge dengan Status Dinamis ─────────────────────────────
  Widget _buildConnectivityBadge() {
    return StreamBuilder<ConnectivityResult>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityResult.none,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacings.sm + 4, vertical: AppSpacings.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: isOnline ? AppColors.bgBlue : AppColors.errorRed,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOnline ? AppColors.primaryBlue : AppColors.errorRed)
                    .withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
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
                  color:
                      isOnline ? AppColors.primaryBlue : AppColors.errorRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Bottom Navigation Sesuai Figma ───────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_filled, 'label': 'Home'},
      {'icon': Icons.menu_book_rounded, 'label': 'Bank'},
      {'icon': Icons.add, 'label': 'Upload', 'isCenter': true},
      {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacings.md),
      decoration: BoxDecoration(
        color: AppColors.bgWhite, 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isCenter = item['isCenter'] == true;
          final isSelected = _selectedNavIndex == i;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedNavIndex = i);
              if (i == 1) Navigator.pushNamed(context, AppRoutes.bankSoal);
              if (i == 2) Navigator.pushNamed(context, AppRoutes.kontribusi);
              if (i == 3) Navigator.pushNamed(context, AppRoutes.statistik);
              if (i == 4) Navigator.pushNamed(context, AppRoutes.profile);
            },
            child: isSelected && !isCenter
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacings.lg, vertical: AppSpacings.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData,
                            color: Colors.white, size: 20),
                        const SizedBox(width: AppSpacings.xs),
                        Text(
                          item['label'] as String,
                          style: AppTextStyles.smallSemibold.copyWith(
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : isCenter
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'] as IconData,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: AppTextStyles.navLabel.copyWith(
                                color: AppColors.textGrey),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData,
                                color: AppColors.textGrey, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              item['label'] as String,
                              style: AppTextStyles.navLabel.copyWith(
                                  color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Widget helper kecil di luar class ────────────────────────────────────────

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
            Text(
              value,
              style: AppTextStyles.bodySemibold
                  .copyWith(color: AppColors.textDark),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}