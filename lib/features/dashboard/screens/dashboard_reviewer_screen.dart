// lib/features/dashboard/screens/dashboard_reviewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ganti ke Riverpod
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';

// TODO: Pastikan reviewControllerProvider sudah didefinisikan di controller Anda menggunakan Riverpod.
// Contoh jika belum ada: final reviewControllerProvider = ChangeNotifierProvider((ref) => ReviewController());
import '../../review/controllers/review_controller.dart';

// ─── Model chart ─────────────────────────────────────────────────────────────
class _ChartBar {
  final String label;
  final int value;
  final bool isToday;
  const _ChartBar(this.label, this.value, {this.isToday = false});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
// Menggunakan ConsumerStatefulWidget milik Riverpod
class DashboardReviewerScreen extends ConsumerStatefulWidget {
  const DashboardReviewerScreen({super.key});

  @override
  ConsumerState<DashboardReviewerScreen> createState() =>
      _DashboardReviewerScreenState();
}

class _DashboardReviewerScreenState
    extends ConsumerState<DashboardReviewerScreen> {
  final _chartData = const [
    _ChartBar('Sen', 12),
    _ChartBar('Sel', 8),
    _ChartBar('Rab', 18),
    _ChartBar('Kam', 24, isToday: true),
    _ChartBar('Jum', 15),
    _ChartBar('Sab', 6),
    _ChartBar('Min', 9),
  ];

  @override
  void initState() {
    super.initState();
    // Load data real dari database saat first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reviewControllerProvider).loadSoalPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Membaca state menggunakan Riverpod ref.watch
    final reviewController = ref.watch(reviewControllerProvider);
    final session = SessionService.instance;
    final nama = session.nama ?? 'Reviewer';
    final pendingCount = reviewController.jumlahPending;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 107, 124, 141),
      appBar: _buildAppBar(nama),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat grid ─────────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                const _StatBox(
                  label: 'Total Soal',
                  value: '1.284',
                  badge: '+12%',
                  badgeColor: Color(0xFF16A34A),
                  badgeIcon: Icons.trending_up,
                ),
                _StatBox(
                  label: 'Review',
                  value: '$pendingCount',
                  valueColor: const Color(0xFF1A6FDF),
                  badge: pendingCount > 0 ? 'Butuh Cepat' : 'Selesai',
                  badgeColor: pendingCount > 0
                      ? const Color(0xFFD97706)
                      : const Color(0xFF16A34A),
                  badgeIcon: pendingCount > 0
                      ? Icons.access_time
                      : Icons.check_circle_outline,
                ),
                const _StatBox(
                  label: 'Aktif',
                  value: '892',
                  badge: 'Live',
                  badgeColor: Color(0xFF16A34A),
                  badgeIcon: Icons.people_outline,
                ),
                const _StatBox(
                  label: 'Sistem',
                  value: '99.9%',
                  valueColor: Color(0xFF16A34A),
                  badge: 'Optimal',
                  badgeColor: Color(0xFF16A34A),
                  badgeIcon: Icons.check_circle_outline,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Bar chart ─────────────────────────────────────────────────
            _buildBarChartCard(),

            const SizedBox(height: 14),

            // ── Section label ─────────────────────────────────────────────
            const Text('Aksi Cepat',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.6)),

            const SizedBox(height: 8),

            // ── Quick action cards ────────────────────────────────────────
            _QuickCard(
              icon: Icons.checklist_outlined,
              iconBg: const Color(0xFFE8F0FD),
              iconColor: const Color(0xFF1A6FDF),
              title: 'Antrian Review',
              subtitle: '$pendingCount soal menunggu persetujuan',
              badge: pendingCount > 0 ? '$pendingCount' : null,
              onTap: () => Navigator.pushNamed(context, AppRoutes.reviewQueue),
            ),

            const SizedBox(height: 8),

            _QuickCard(
              icon: Icons.library_books_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: 'Manajemen Koleksi',
              subtitle: 'Kelola kategori dan koleksi soal aktif',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.collectionManagement),
            ),

            const SizedBox(height: 8),

            _QuickCard(
              icon: Icons.add_circle_outline,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Buat Soal Baru',
              subtitle: 'Tambahkan soal langsung ke bank soal',
              onTap: () => Navigator.pushNamed(context, AppRoutes.submitSoal),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar(String nama) => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Color(0xFF1A6FDF), shape: BoxShape.circle),
              child: const Center(
                child: Text('R',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Text(nama,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF374151)),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
      );

  // ─── Bar chart card ───────────────────────────────────────────────────────
  Widget _buildBarChartCard() {
    final maxVal =
        _chartData.map((c) => c.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengiriman Soal (7 Hari Terakhir)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.map((bar) {
                final frac = bar.value / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (frac * 60).clamp(8.0, 60.0),
                          decoration: BoxDecoration(
                            color: bar.isToday
                                ? const Color(0xFF1A6FDF)
                                : const Color(0xFFE5E7EB),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bar.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                bar.isToday ? FontWeight.w700 : FontWeight.w400,
                            color: bar.isToday
                                ? const Color(0xFF1A6FDF)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Box ─────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final String badge;
  final Color badgeColor;
  final IconData badgeIcon;

  const _StatBox({
    required this.label,
    required this.value,
    this.valueColor,
    required this.badge,
    required this.badgeColor,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF111827),
              height: 1.1,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(badgeIcon, size: 13, color: badgeColor),
              const SizedBox(width: 3),
              Text(badge,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            if (badge != null)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Color(0xFFDC2626), shape: BoxShape.circle),
                child: Center(
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}
