// lib/features/dashboard/screens/dashboard_admin_screen.dart
// Sprint 5 UPDATE — Revaldi (RP): Hubungkan ke halaman kelola user & soal
// Dashboard admin sekarang memiliki navigasi ke panel kelola pengguna & soal.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/guard/rbac_guard.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../admin/controllers/admin_controller.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();

    // ── GUARD RBAC di UI level ─────────────────────────────────────────────
    // Guard controller level ada di setiap AdminController method.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        RbacGuard.redirectIfUnauthorized(context, requiredRole: 'admin');
      }
    });
  }

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
            // ── Greeting ─────────────────────────────────────────────────
            Row(
              children: [
                UserAvatar(
                  name: session.nama ?? 'Admin',
                  size: 44,
                  bgColor: AppColors.errorRed.withOpacity(0.15),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${session.nama?.split(' ').first ?? 'Admin'}!',
                      style: AppTextStyles.h2,
                    ),
                    Text(
                      '${session.email ?? ''}  •  Administrator',
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Badge RBAC info
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.08),
                borderRadius: AppRadius.pill,
                border: Border.all(
                    color: AppColors.errorRed.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.errorRed),
                  const SizedBox(width: 4),
                  Text(
                    'Akses Penuh — Admin',
                    style: AppTextStyles.captionBold
                        .copyWith(color: AppColors.errorRed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text('Panel Kontrol', style: AppTextStyles.h3),
            const SizedBox(height: 12),

            // ── Menu Admin ────────────────────────────────────────────────

            // SPRINT 5: Terhubung ke halaman kelola pengguna
            AppMenuCard(
              icon: Icons.people_outline,
              label: 'Kelola Pengguna',
              subtitle: 'Atur role, status aktif/nonaktif pengguna',
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.adminKelolaUser),
            ),

            const SizedBox(height: 12),

            // SPRINT 5: Terhubung ke halaman kelola soal
            AppMenuCard(
              icon: Icons.quiz_outlined,
              label: 'Kelola Soal',
              subtitle:
                  'Arsipkan, nonaktifkan, atau aktifkan kembali soal',
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.adminKelolasoal),
            ),

            const SizedBox(height: 12),

            AppMenuCard(
              icon: Icons.settings_outlined,
              label: 'Pengaturan Sistem',
              subtitle: 'Kontrol penuh konfigurasi aplikasi',
              onTap: () {
                // TODO Sprint 6
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur ini akan tersedia di Sprint 6'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}