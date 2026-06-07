// lib/features/profile/screens/profile_screen.dart
// REFACTOR: Streak, level, dan poin dihitung dari data Hive yang real.
// Major diambil dari SessionService jika tersedia, fallback ke default.

import 'package:flutter/material.dart';

import '../../../core/services/logout_handler.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionService _session = SessionService.instance;
  bool _isLoading = false;

  // ─── Computed dari Hive ───────────────────────────────────────────────────

  /// Poin berdasarkan tingkat kesulitan: Easy=25, Medium=50, Hard=100.
  int get _totalPoints {
    final userId = _session.userId ?? '';
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
  }

  /// Level dihitung dari total poin.
  /// Setiap 500 poin = 1 level.
  int get _level {
    final pts = _totalPoints;
    if (pts <= 0) return 1;
    return (pts / 500).floor() + 1;
  }

  /// Streak dihitung dari hari berurutan di mana user menyelesaikan soal.
  int get _streakDays {
    final userId = _session.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;

    final solvedDates = progressBox.values
        .where((p) => p.userId == userId && p.isSolved && p.solvedAt != null)
        .map((p) => DateTime(
            p.solvedAt!.year, p.solvedAt!.month, p.solvedAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (solvedDates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    DateTime check = DateTime(today.year, today.month, today.day);

    for (final d in solvedDates) {
      if (d == check || d == check.subtract(const Duration(days: 1))) {
        streak++;
        check = d;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Jumlah soal yang diselesaikan.
  int get _totalSolved {
    final userId = _session.userId ?? '';
    return HiveService.instance.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;
  }

  /// Jumlah soal yang pernah dikontribusikan.
  int get _totalKontribusi {
    final userId = _session.userId ?? '';
    return HiveService.instance.questionsBox.values
        .where((q) => q.submittedBy == userId)
        .length;
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> _onLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('LOGOUT ACCOUNT',
            style: AppTextStyles.h2, textAlign: TextAlign.center),
        content: const Text(
          'Kamu yakin ingin keluar dari akun ini?',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.easyBg,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yakin'),
          ),
        ],
      ),
    );

    if (konfirmasi == true && mounted) {
      await LogoutHandler.instance.logout(context);
    }
  }

  // ─── Edit Profile ─────────────────────────────────────────────────────────

  void _onEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur edit profil akan segera hadir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Refresh ─────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nama = _session.nama ?? 'Pengguna';
    final nim = _session.nim ?? '-';
    final email = _session.email ?? '-';
    final role = _session.role ?? 'mahasiswa';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Bagian Profil ─────────────────────────────────────
                    _buildProfileSection(nama, nim, email, role),

                    const SizedBox(height: 12),

                    // ── Statistik ─────────────────────────────────────────
                    _buildStatsSection(),

                    const SizedBox(height: 12),

                    // ── Aktivitas Ringkas ─────────────────────────────────
                    _buildActivitySection(),

                    const SizedBox(height: 12),

                    // ── Settings ──────────────────────────────────────────
                    _buildSettingsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Widget: Profil ───────────────────────────────────────────────────────

  Widget _buildProfileSection(
      String nama, String nim, String email, String role) {
    final level = _level;

    return Container(
      width: double.infinity,
      color: AppColors.bgWhite,
      padding:
          const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue,
                    width: 2.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: UserAvatar(
                    name: nama,
                    size: 80,
                    bgColor: AppColors.lightBlue,
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'LVL $level',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            nama,
            style: AppTextStyles.h1.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (nim != '-')
            Text('NIM: $nim',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textGrey)),
          const SizedBox(height: 4),
          Text(email,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.textGrey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              _roleLabel(role),
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.textGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'reviewer':
        return 'REVIEWER';
      case 'admin':
        return 'ADMINISTRATOR';
      default:
        return 'MAHASISWA';
    }
  }

  // ─── Widget: Stats ────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.primaryBlue,
              value: _formatNumber(_totalPoints),
              label: 'TOTAL POINTS',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_outlined,
              iconColor: AppColors.warningYellow,
              value: '$_streakDays Days',
              label: 'CURRENT STREAK',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widget: Activity ringkas ─────────────────────────────────────────────

  Widget _buildActivitySection() {
    final solved = _totalSolved;
    final kontribusi = _totalKontribusi;
    final bookmark = HiveService.instance.bookmarksBox.values
        .where((b) => b.userId == (_session.userId ?? ''))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.borderGrey, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktivitas',
                style: AppTextStyles.h3
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActivityTile(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.successGreen,
                    value: '$solved',
                    label: 'Diselesaikan',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActivityTile(
                    icon: Icons.bookmark_outline,
                    iconColor: Colors.amber,
                    value: '$bookmark',
                    label: 'Tersimpan',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActivityTile(
                    icon: Icons.upload_outlined,
                    iconColor: AppColors.primaryBlue,
                    value: '$kontribusi',
                    label: 'Kontribusi',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widget: Settings ─────────────────────────────────────────────────────

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.manage_accounts_outlined,
            iconColor: AppColors.primaryBlue,
            iconBgColor: AppColors.lightBlue,
            label: 'Edit Profile',
            onTap: _onEditProfile,
            showChevron: true,
          ),
          const SizedBox(height: 10),
          _SettingsItem(
            icon: Icons.logout_outlined,
            iconColor: AppColors.errorRed,
            iconBgColor: AppColors.hardBg,
            label: 'Logout',
            labelColor: AppColors.errorRed,
            onTap: _onLogout,
            showChevron: false,
          ),
        ],
      ),
    );
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

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

// ─── Widget: Stat Card ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.h2.copyWith(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.captionBold
                .copyWith(color: AppColors.textGrey, letterSpacing: 0.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Activity Tile ────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Widget: Settings Item ────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    this.labelColor,
    required this.onTap,
    required this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySemibold.copyWith(
                      color: labelColor ?? AppColors.textDark),
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right,
                    color: AppColors.textGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}