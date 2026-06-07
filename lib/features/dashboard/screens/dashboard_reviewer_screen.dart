// lib/features/dashboard/screens/dashboard_reviewer_screen.dart
// REFACTOR: Weekly chart menggunakan data submission real dari Hive/MongoDB

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../routes/app_routes.dart';

import '../../review/controllers/review_controller.dart';

// ─── Model chart ─────────────────────────────────────────────────────────────
class _ChartBar {
  final String label;
  final int value;
  final bool isToday;
  const _ChartBar(this.label, this.value, {this.isToday = false});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DashboardReviewerScreen extends ConsumerStatefulWidget {
  const DashboardReviewerScreen({super.key});

  @override
  ConsumerState<DashboardReviewerScreen> createState() =>
      _DashboardReviewerScreenState();
}

class _DashboardReviewerScreenState
    extends ConsumerState<DashboardReviewerScreen> {
  /// Hitung jumlah soal yang di-submit per hari dalam 7 hari terakhir
  /// menggunakan data yang tersimpan di Hive (questionsBox).
  List<_ChartBar> _buildChartData() {
    final questionBox = HiveService.instance.questionsBox;
    final now = DateTime.now();

    // Label hari dalam bahasa Indonesia
    const hariLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Buat map: tanggal → jumlah soal yang disubmit
    final Map<String, int> countPerDay = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      countPerDay[key] = 0;
    }

    for (final q in questionBox.values) {
      final d = q.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      if (countPerDay.containsKey(key)) {
        countPerDay[key] = countPerDay[key]! + 1;
      }
    }

    // Konversi ke list _ChartBar
    final List<_ChartBar> bars = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      final isToday = i == 0;
      bars.add(_ChartBar(
        hariLabels[day.weekday % 7],
        countPerDay[key] ?? 0,
        isToday: isToday,
      ));
    }
    return bars;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reviewControllerProvider).loadSoalPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewController = ref.watch(reviewControllerProvider);
    final session = SessionService.instance;
    final nama = session.nama ?? 'Reviewer';
    final pendingCount = reviewController.jumlahPending;

    // Hitung statistik dari Hive
    final questionBox = HiveService.instance.questionsBox;
    final totalSoal = questionBox.length;
    final totalPublished = questionBox.values
        .where((q) => q.status == QuestionStatus.published)
        .length;
    final totalArsip = questionBox.values
        .where((q) => q.status == QuestionStatus.archived)
        .length;

    final chartData = _buildChartData();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 107, 124, 141),
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
                _StatBox(
                  label: 'Total Soal',
                  value: '$totalSoal',
                  badge: '$totalPublished Aktif',
                  badgeColor: const Color(0xFF16A34A),
                  badgeIcon: Icons.check_circle_outline,
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
                _StatBox(
                  label: 'Dipublish',
                  value: '$totalPublished',
                  badge: 'Live',
                  badgeColor: const Color(0xFF16A34A),
                  badgeIcon: Icons.people_outline,
                ),
                _StatBox(
                  label: 'Diarsip',
                  value: '$totalArsip',
                  valueColor: const Color(0xFF9CA3AF),
                  badge: 'Arsip',
                  badgeColor: const Color(0xFF9CA3AF),
                  badgeIcon: Icons.archive_outlined,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Bar chart dari data real ───────────────────────────────────
            _buildBarChartCard(chartData),

            const SizedBox(height: 14),

            const Text('Aksi Cepat',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.6)),

            const SizedBox(height: 8),

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
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.collectionManagement),
            ),

            const SizedBox(height: 8),

            _QuickCard(
              icon: Icons.add_circle_outline,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Buat Soal Baru',
              subtitle: 'Tambahkan soal langsung ke bank soal',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.submitSoal),
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

  // ─── Bar chart card dari data real ────────────────────────────────────────
  Widget _buildBarChartCard(List<_ChartBar> chartData) {
    final maxVal = chartData.isEmpty
        ? 1
        : chartData.map((c) => c.value).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

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
              children: chartData.map((bar) {
                final frac = bar.value / effectiveMax;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (bar.value > 0)
                          Text('${bar.value}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: bar.isToday
                                    ? const Color(0xFF1A6FDF)
                                    : const Color(0xFF9CA3AF),
                              )),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (frac * 55).clamp(4.0, 55.0),
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
                            fontWeight: bar.isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
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