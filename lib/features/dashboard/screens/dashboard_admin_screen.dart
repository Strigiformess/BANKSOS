// lib/features/dashboard/screens/dashboard_admin_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';

class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
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
              'Role: Admin  •  ${session.email ?? ''}',
              style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
            ),

            const SizedBox(height: 32),

            // ── Menu Admin ────────────────────────────────────────────────
            AppMenuCard(
              icon: Icons.people_outline,
              label: 'Kelola Pengguna',
              subtitle: 'Atur role, status, dan akses pengguna',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminUserManagement),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.quiz_outlined,
              label: 'Kelola Soal',
              subtitle: 'Arsipkan atau nonaktifkan soal',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminQuestionManagement),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.settings_outlined,
              label: 'Pengaturan Sistem',
              subtitle: 'Kontrol penuh konfigurasi aplikasi',
              onTap: () {}, // TODO: navigasi ke pengaturan
            ),
          ],
        ),
      ),
    );
  }
}