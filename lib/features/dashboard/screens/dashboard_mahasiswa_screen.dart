// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
// PIC: Seruni (SL) — Sprint 1 placeholder, Sprint 3 akan lengkap

// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

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
        padding: AppSpacings.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────────────────
            Text(
              'Halo, ${session.nama ?? 'Mahasiswa'}! 👋',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 6),
            Text(
              'Siap belajar hari ini?',
              style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
            ),

            const SizedBox(height: 32),

            // ── Menu Cards — pakai AppMenuCard dari app_widgets ───────────
            AppMenuCard(
              icon: Icons.menu_book_outlined,
              label: 'Bank Soal',
              subtitle: 'Jelajahi & kerjakan soal latihan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.bankSoal),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.bookmark_outline,
              label: 'Soal Tersimpan',
              subtitle: 'Lihat soal yang kamu bookmark',
              onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.history_outlined,
              label: 'Riwayat',
              subtitle: 'Soal yang sudah kamu kerjakan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.riwayat),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.add_circle_outline,
              label: 'Kontribusi Soal',
              subtitle: 'Ajukan soal baru untuk ditinjau',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.kontribusi),
            ),
          ],
        ),
      ),
    );
  }
}