// lib/shared/layouts/main_shell.dart
// PIC: Seruni
// Sprint 1: Pembuatan UI Layer dasar dan struktur halaman aplikasi


import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/session_service.dart';
import '../../features/dashboard/screens/dashboard_mahasiswa_screen.dart';
import '../../features/question/screens/bank_soal_screen.dart';
import '../../features/kontribusi/screens/submit_soal_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  /// Indeks tab awal. Default 0 (Home).
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();

  /// Akses controller dari manapun via context.
  static _MainShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellState>();
  }
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Pindah tab secara programatik dari halaman mana pun.
  /// Contoh: MainShell.of(context)?.jumpTo(1);
  void jumpTo(int index) {
    if (index < 0 || index > 4) return;
    setState(() => _currentIndex = index);
  }

  // Daftar halaman — IndexedStack mempertahankan state masing-masing
  static const List<Widget> _pages = [
    _HomeTab(),
    BankSoalScreen(),
    _UploadTab(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  // ─── Definisi item navbar ─────────────────────────────────────────────────

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,       label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded,  label: 'Bank'),
    _NavItem(icon: Icons.add,                label: 'Upload', isCenter: true),
    _NavItem(icon: Icons.bar_chart_rounded,  label: 'Stats'),
    _NavItem(icon: Icons.person_rounded,     label: 'Profile'),
  ];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) {
          // Tab Upload langsung push ke submit soal (tidak switch tab)
          if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubmitSoalScreen()),
            );
            return;
          }
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

// ─── Bottom Nav Widget ────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == i && !item.isCenter;

          if (item.isCenter) {
            return GestureDetector(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: AppTextStyles.navLabel.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (isSelected) {
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: AppTextStyles.navLabel.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: AppColors.textGrey, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: AppTextStyles.navLabel.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Wrapper Tab Home ─────────────────────────────────────────────────────────
// Membungkus DashboardMahasiswaScreen tapi tanpa bottom nav bawaannya,
// karena nav sudah dihandle MainShell.

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const _DashboardBody();
  }
}

// Versi DashboardMahasiswaScreen tanpa bottom nav bawaan.
// Copy semua content dari DashboardMahasiswaScreen KECUALI _buildBottomNav().
// Cara paling mudah: jadikan _HomeTab langsung merender DashboardMahasiswaScreen,
// lalu di DashboardMahasiswaScreen hapus Scaffold.bottomNavigationBar dan
// ganti _selectedNavIndex logic dengan MainShell.of(context)?.jumpTo().
//
// Kalau tidak ingin refactor besar, gunakan pendekatan ini:
// Bungkus DashboardMahasiswaScreen di dalam Stack dan sembunyikan nav lamanya.

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    // DashboardMahasiswaScreen sudah punya Scaffold dengan navbar sendiri.
    // Setelah refactor (lihat PETUNJUK REFACTOR di bawah), hapus
    // bottomNavigationBar dari Scaffold-nya sehingga tidak double navbar.
    return const DashboardMahasiswaScreen();
  }
}

// ─── Upload Tab (placeholder langsung push screen) ────────────────────────────

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}