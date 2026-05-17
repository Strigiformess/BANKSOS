// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
// PIC: Seruni (SL) — Sprint 1 placeholder, Sprint 3 akan lengkap
// Dashboard Mahasiswa — sesuai mockup UI Light Theme

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';


class DashboardMahasiswaScreen extends ConsumerStatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  ConsumerState<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState
    extends ConsumerState<DashboardMahasiswaScreen> {
  int _selectedNavIndex = 0;

  // Warna khusus untuk ranking (emas, perak, perunggu)
  static const Color _rankGold   = Color(0xFFFFD700);
  static const Color _rankSilver = Color(0xFFC0C0C0);
  static const Color _rankBronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final nama = SessionService.instance.nama?.split(' ').first ?? 'Ahmad';

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
                    const SizedBox(height: AppSpacings.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacings.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRankCard(),
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
            bgColor: AppColors.primaryBlue.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.15),
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
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
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
        color: AppColors.bgWhite, // Light Mode Background
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                    color: AppColors.warningYellow.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                )
              else if (iconWidget != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
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

  // ─── Dynamic Status Card (berubah saat offline) ────────────────────────────
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
            border: Border.all(color: AppColors.borderGrey.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
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
      {'icon': Icons.bar_chart_rounded, 'label': 'Statistik', 'route': null},
      {'icon': Icons.wifi_off_rounded, 'label': 'Offline', 'route': null},
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
            final isFirst = i == 0; // Item pertama di-highlight biru seperti Figma

            return GestureDetector(
              onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isFirst ? AppColors.primaryBlue : AppColors.bgWhite,
                      borderRadius: AppRadius.lgAll,
                      boxShadow: [
                        if (!isFirst)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Icon(
                      m['icon'] as IconData,
                      color: isFirst ? Colors.white : AppColors.primaryBlue,
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

  // ─── Rekomendasi Matkul ───────────────────────────────────────────────────
  Widget _buildRekomendasi() {
    final matkuls = [
      {
        'kode': 'CS101',
        'nama': 'Basis Data',
        'soal': '450 Soal Tersedia',
        'gradientStart': const Color(0xFF0D2B55),
        'gradientEnd': const Color(0xFF1A4A8A),
      },
      {
        'kode': 'CS102',
        'nama': 'Sistem Operasi',
        'soal': '320 Soal Tersedia',
        'gradientStart': const Color(0xFF0A3040),
        'gradientEnd': const Color(0xFF155570),
      },
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
          children: matkuls.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isLast = i == matkuls.length - 1;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : AppSpacings.md),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Placeholder Atas (Pakai Gradien)
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg)),
                        gradient: LinearGradient(
                          colors: [
                            m['gradientStart'] as Color,
                            m['gradientEnd'] as Color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -10,
                            child: Icon(Icons.computer, size: 80, color: Colors.white.withOpacity(0.1)),
                          )
                        ],
                      ),
                    ),
                    // Teks Bawah (Warna Terang)
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
                              m['kode'] as String,
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacings.xs),
                          Text(
                            m['nama'] as String,
                            style: AppTextStyles.bodySemibold.copyWith(
                                color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['soal'] as String,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textGrey),
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

  // ─── Soal Terbaru ─────────────────────────────────────────────────────────
  Widget _buildSoalTerbaru() {
    final soals = [
      {
        'judul': 'Normalisasi 3NF',
        'sub': 'Basis Data • 2 jam yang lalu',
        'difficulty': 'easy',
      },
      {
        'judul': 'Deadlock Prevention',
        'sub': 'Sistem Operasi • 5 jam yang lalu',
        'difficulty': 'hard',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soal Terbaru',
          style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: AppSpacings.md),
        ...soals.map((s) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacings.sm),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacings.md, vertical: AppSpacings.md),
              decoration: BoxDecoration(
                color: AppColors.bgWhite, // Light Mode Card
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
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
                    decoration: BoxDecoration(
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
                          s['judul'] as String,
                          style: AppTextStyles.bodySemibold.copyWith(
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['sub'] as String,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  // AppBadge.difficulty sudah diset dengan warna terang di app_theme
                  AppBadge.difficulty(s['difficulty'] as String),
                ],
              ),
            )),
      ],
    );
  }

  // ─── Top Students ─────────────────────────────────────────────────────────
  Widget _buildTopStudents() {
    final students = [
      {'nama': 'Sarah Wijaya', 'pts': '2,450 pts', 'rank': 1},
      {'nama': 'Budi Santoso', 'pts': '2,120 pts', 'rank': 2},
      {'nama': 'Citra Putri', 'pts': '1,980 pts', 'rank': 3},
    ];

    final rankColors = [_rankGold, _rankSilver, _rankBronze];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacings.sm),
            Text(
              'Top Students',
              style: AppTextStyles.h2.copyWith(color: AppColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: AppSpacings.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite, // Light Mode Card
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: students.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == students.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: AppSpacings.listItemPadding,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${s['rank']}',
                            style: AppTextStyles.bodySemibold.copyWith(
                                color: rankColors[i], fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacings.xs),
                        UserAvatar(
                          name: s['nama'] as String,
                          size: 38,
                          bgColor: rankColors[i].withOpacity(0.15),
                        ),
                        const SizedBox(width: AppSpacings.md),
                        Expanded(
                          child: Text(
                            s['nama'] as String,
                            style: AppTextStyles.bodySemibold.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          s['pts'] as String,
                          style: AppTextStyles.smallSemibold.copyWith(
                              color: AppColors.primaryBlue), // Points warna biru
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: AppSpacings.xl,
                      endIndent: AppSpacings.xl,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Connectivity Badge dengan Status Dinamis ─────────────────────────────
  /// Badge yang berubah icon, warna, dan text saat koneksi offline
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
                    .withOpacity(0.05),
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
      {'icon': Icons.emoji_events_rounded, 'label': 'Rewards'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacings.md),
      decoration: BoxDecoration(
        color: AppColors.bgWhite, // Pure white
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            },
            child: isSelected && !isCenter
                // Tampilan saat Item Biasa Terpilih (Pill Biru seperti di Figma)
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacings.lg, vertical: AppSpacings.sm),
                    decoration: BoxDecoration(
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
                // Tampilan Tombol Tengah (Upload / Plus Bulat)
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
                    // Tampilan Item Biasa Tidak Terpilih
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