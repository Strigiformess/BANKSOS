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
    
    // TODO: Hubungkan ini ke State Management (misal: review_controller) untuk update real-time
    final int pendingCount = 3; 

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
      body: SingleChildScrollView(
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
              badge: pendingCount > 0 ? pendingCount.toString() : null,
              onTap: () => Navigator.pushNamed(context, AppRoutes.reviewQueue),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.category_outlined,
              label: 'Manajemen Koleksi',
              subtitle: 'Kelola kategori dan koleksi soal aktif',
              onTap: () {}, // TODO: navigasi ke halaman manajemen koleksi
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.add_circle_outline,
              label: 'Buat Soal Baru',
              subtitle: 'Tambahkan soal langsung ke bank soal',
              onTap: () {}, // TODO: navigasi ke form buat soal (opsional beda dari mahasiswa)
            ),
          ],
        ),
      ),
    );
  }
}