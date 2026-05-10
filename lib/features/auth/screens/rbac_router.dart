import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';

// Placeholder - nanti diganti screen asli dari masing-masing PIC
import '../../dashboard/screens/dashboard_mahasiswa_screen.dart';
import '../../dashboard/screens/dashboard_reviewer_screen.dart';
import '../../dashboard/screens/dashboard_admin_screen.dart';

class RbacRouter extends StatelessWidget {
  final String role;
  const RbacRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'reviewer':
        return const DashboardReviewerScreen();
      case 'admin':
        return const DashboardAdminScreen();
      case 'mahasiswa':
      default:
        return const DashboardMahasiswaScreen();
    }
  }
}