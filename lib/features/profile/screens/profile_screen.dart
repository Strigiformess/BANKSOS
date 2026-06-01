// lib/features/profile/screens/profile_screen.dart
// Halaman profil mahasiswa BANKSOS - Dinamis dari Local DB / Server

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Ditambahkan untuk reactive UI Hive jika diperlukan

import '../../../core/services/logout_handler.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_progress_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionService _session = SessionService.instance;
  
  // Instance Box Hive (sesuaikan dengan nama box di inisialisasi aplikasi kamu)
  late Box<UserModel> _userBox;
  late Box<UserProgressModel> _progressBox;
  
  UserModel? _currentUser;
  int _totalPoints = 0;
  bool _isLoading = true;

  // Placeholder untuk data yang belum ada di model database saat ini
  static const int _currentStreak = 0; // TODO: Tambahkan logic streak jika sudah ada di DB
  static const int _level = 1;         // TODO: Tambahkan formula kalkulasi level berdasarkan poin
  static const String _major = 'TEKNIK INFORMATIKA'; // TODO: Tambahkan field jurusan di UserModel jika diperlukan

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Memuat data pengguna dan menghitung statistik secara dinamis
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Buka Box Hive
      _userBox = await Hive.openBox<UserModel>('users_box');
      _progressBox = await Hive.openBox<UserProgressModel>('progress_box');

      // 2. Ambil data user yang sedang login berdasarkan email/ID dari SessionService
      final currentEmail = _session.email;
      if (currentEmail != null) {
        _currentUser = _userBox.values.firstWhere(
          (user) => user.email == currentEmail,
          orElse: () => throw Exception('User tidak ditemukan di lokal box'),
        );
      }

      // 3. Hitung total poin berdasarkan soal yang berhasil diselesaikan
      if (_currentUser != null) {
        final solvedQuestions = _progressBox.values.where(
          (progress) => progress.userId == _currentUser!.id && progress.isSolved == true
        ).length;

        _totalPoints = solvedQuestions * 100; 
      }
    } catch (e) {
      debugPrint('Gagal memuat data profil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  Future<void> _onLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('LOGOUT ACCOUNT', style: AppTextStyles.h2, textAlign: TextAlign.center),
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
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Fallback ke session service jika data UserModel dari Hive belum siap
    final nama = _currentUser?.namaLengkap ?? _session.nama ?? 'Pengguna';
    final nim = _currentUser?.nim ?? _session.nim ?? '-';
    final email = _currentUser?.email ?? _session.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadUserData, // Refresh data dari DB
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Agar bisa di-pull to refresh
                child: Column(
                  children: [
                    // ── Bagian Profil ─────────────────────────────────────────────
                    _buildProfileSection(nama, nim, email),

                    const SizedBox(height: 12),

                    // ── Statistik ─────────────────────────────────────────────────
                    _buildStatsSection(),

                    const SizedBox(height: 12),

                    // ── Settings ─────────────────────────────────────────────────
                    _buildSettingsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Widget: Profil ───────────────────────────────────────────────────────

  Widget _buildProfileSection(String nama, String nim, String email) {
    return Container(
      width: double.infinity,
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'LVL $_level',
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
          Text(
            'NIM: $nim',
            style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              _major,
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
          const Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_outlined,
              iconColor: AppColors.warningYellow,
              value: '$_currentStreak Days',
              label: 'CURRENT STREAK',
            ),
          ),
        ],
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
          const Text('Settings', style: AppTextStyles.h2),
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
      final formatted = value.toString();
      final len = formatted.length;
      final buffer = StringBuffer();
      for (int i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
        buffer.write(formatted[i]);
      }
      return buffer.toString();
    }
    return value.toString();
  }
}

// ─── Widget: Stat Card (Sama seperti sebelumnya) ──────────────────────────────
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
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: AppColors.textGrey, letterSpacing: 0.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Settings Item (Sama seperti sebelumnya) ──────────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySemibold.copyWith(color: labelColor ?? AppColors.textDark),
                ),
              ),
              if (showChevron) const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}