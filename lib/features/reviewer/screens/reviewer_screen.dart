// lib/features/reviewer/screens/reviewer_main_screen.dart
//
// Shell screen dengan BottomNavigationBar untuk role Reviewer.
// Meng-host 4 tab: Beranda, Bank Soal, Review, Laporan.
//
// Cara pakai:
//   Navigator.pushReplacementNamed(context, AppRoutes.reviewerMain);
// atau set sebagai initialRoute setelah login reviewer berhasil.

import 'package:flutter/material.dart';

import '../../collection/screens/collection_management_screen.dart';
import '../../review/screens/review_queue_screen.dart';
import '../../dashboard/screens/dashboard_reviewer_screen.dart';

// Placeholder untuk tab Laporan (belum diimplementasi)
class _LaporanScreen extends StatelessWidget {
  const _LaporanScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined,
                  size: 48, color: Color(0xFFD1D5DB)),
              SizedBox(height: 12),
              Text('Laporan',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              SizedBox(height: 4),
              Text('Fitur ini sedang dalam pengembangan.',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
      );
}

// ─── Main Shell ───────────────────────────────────────────────────────────────
class ReviewerMainScreen extends StatefulWidget {
  /// Set [initialIndex] ke 2 untuk langsung buka tab Review
  /// (berguna saat notifikasi di-tap).
  final int initialIndex;

  const ReviewerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<ReviewerMainScreen> createState() => _ReviewerMainScreenState();
}

class _ReviewerMainScreenState extends State<ReviewerMainScreen> {
  late int _currentIndex;

  // Gunakan IndexedStack supaya state tiap tab tidak hilang saat pindah tab
  static const _screens = [
    DashboardReviewerScreen(),
    CollectionManagementScreen(),
    ReviewQueueScreen(),
    _LaporanScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gunakan IndexedStack agar scroll position & state tab dipertahankan
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ReviewerBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _ReviewerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ReviewerBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined, label: 'Beranda'),
    _NavItem(icon: Icons.library_books_outlined, label: 'Bank Soal'),
    _NavItem(icon: Icons.checklist_outlined, label: 'Review'),
    _NavItem(icon: Icons.bar_chart_outlined, label: 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active
                            ? const Color(0xFF1A6FDF)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? const Color(0xFF1A6FDF)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}