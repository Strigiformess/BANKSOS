// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
// PIC: Seruni (SL) — Sprint 1 placeholder, Sprint 3 akan lengkap

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';
// import '../../questions/screens/bank_soal_screen.dart';

class DashboardMahasiswaScreen extends ConsumerWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = SessionService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BANKSOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await session.clearSession();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Halo, ${session.nama ?? 'Mahasiswa'}! 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Siap belajar hari ini?',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),

            const SizedBox(height: 32),

            // Shortcut ke Bank Soal
            // _buildMenuCard(
            //   context,
            //   icon: Icons.menu_book_outlined,
            //   label: 'Bank Soal',
            //   subtitle: 'Jelajahi & kerjakan soal latihan',
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => const BankSoalScreen()),
            //   ),
            // ),

            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.bookmark_outline,
              label: 'Soal Tersimpan',
              subtitle: 'Lihat soal yang kamu bookmark',
              onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.history_outlined,
              label: 'Riwayat',
              subtitle: 'Soal yang sudah kamu kerjakan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.riwayat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
        onTap: onTap,
      ),
    );
  }
}