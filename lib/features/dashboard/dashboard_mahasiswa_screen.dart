// lib/features/dashboard/screens/dashboard_mahasiswa_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';

class DashboardMahasiswaScreen extends StatelessWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
        backgroundColor: const Color(0xFF1F5C99),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Halo, ${session.nama ?? "-"}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Role: Mahasiswa | ${session.email}',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}