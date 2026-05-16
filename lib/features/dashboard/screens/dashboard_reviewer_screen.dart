// lib/features/dashboard/screens/dashboard_reviewer_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';

class DashboardReviewerScreen extends StatelessWidget {
  const DashboardReviewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Reviewer'),
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
            Text('Halo, ${session.nama ?? '-'}!', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(
              'Role: Reviewer  •  ${session.email ?? ''}',
              style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
            ),

            const SizedBox(height: 32),

            // ── Menu Reviewer ─────────────────────────────────────────────
            AppMenuCard(
              icon: Icons.rate_review_outlined,
              label: 'Antrian Review',
              subtitle: 'Tinjau soal yang masuk dari mahasiswa',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.reviewQueue),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.check_circle_outline,
              label: 'Soal Disetujui',
              subtitle: 'Soal yang sudah kamu approve',
              onTap: () {}, // TODO: navigasi ke daftar soal approved
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.category_outlined,
              label: 'Kelola Kategori',
              subtitle: 'Atur kategori dan tingkat kesulitan',
              onTap: () {}, // TODO: navigasi ke halaman kategori
            ),
          ],
        ),
      ),
    );
  }
}