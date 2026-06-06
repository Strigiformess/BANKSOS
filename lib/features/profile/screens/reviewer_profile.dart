// lib/features/profile/screens/reviewer_screen.dart
// Halaman profil reviewer BANKSOS - Dinamis dari Local DB / Server

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/logout_handler.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/user_model.dart';

class ReviewerScreen extends StatefulWidget {
  const ReviewerScreen({super.key});

  @override
  State<ReviewerScreen> createState() => _ReviewerScreenState();
}

class _ReviewerScreenState extends State<ReviewerScreen> {
  final SessionService _session = SessionService.instance;
  
  late Box<UserModel> _userBox;
  UserModel? _currentUser;
  bool _isLoading = true;

  // Placeholder untuk data jurusan jika belum ada di DB
  static const String _major = 'TIM REVIEWER BANKSOS'; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Memuat data reviewer secara dinamis
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _userBox = await Hive.openBox<UserModel>('users_box');

      final currentEmail = _session.email;
      if (currentEmail != null) {
        _currentUser = _userBox.values.firstWhere(
          (user) => user.email == currentEmail,
          orElse: () => throw Exception('Reviewer tidak ditemukan di lokal box'),
        );
      }
    } catch (e) {
      debugPrint('Gagal memuat data profil reviewer: $e');
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
          'Kamu yakin ingin keluar dari akun reviewer ini?',
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
        content: Text('Fitur edit profil reviewer akan segera hadir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nama = _currentUser?.namaLengkap ?? _session.nama ?? 'Reviewer';
    final nim = _currentUser?.nim ?? _session.nim ?? '-';
    final email = _currentUser?.email ?? _session.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Reviewer Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Bagian Identitas Profil ──────────────────────────────────
                    _buildProfileSection(nama, nim, email),

                    const SizedBox(height: 20),

                    // ── Pengaturan (Edit & Logout) ───────────────────────────────
                    _buildSettingsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Widget: Profil Identitas ─────────────────────────────────────────────

  Widget _buildProfileSection(String nama, String nim, String email) {
    return Container(
      width: double.infinity,
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
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
          const SizedBox(height: 20),
          Text(
            nama,
            style: AppTextStyles.h1.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'NIP / NIM: $nim',
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
            label: 'Logout Account',
            labelColor: AppColors.errorRed,
            onTap: _onLogout,
            showChevron: false,
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Settings Item ──────────────────────────────────────────────────
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