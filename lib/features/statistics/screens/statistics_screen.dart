// lib/features/statistics/screens/statistics_screen.dart
// REFACTOR: Weekly activity chart menggunakan data real dari Hive.
// Streak dihitung dari tanggal solvedAt yang berurutan.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // ─── Computed Stats dari Hive ─────────────────────────────────────────────

  int get _totalSolved {
    final userId = SessionService.instance.userId ?? '';
    return HiveService.instance.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;
  }

  /// Poin dihitung berdasarkan tingkat kesulitan soal.
  int get _totalPoints {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;
    int total = 0;
    for (final p in progressBox.values) {
      if (p.userId != userId || !p.isSolved) continue;
      final q = questionBox.get(p.questionId) ??
          questionBox.values.where((q) => q.id == p.questionId).firstOrNull;
      if (q == null) continue;
      switch (q.tingkatKesulitan) {
        case DifficultyLevel.easy:
          total += 25;
          break;
        case DifficultyLevel.medium:
          total += 50;
          break;
        case DifficultyLevel.hard:
          total += 100;
          break;
      }
    }
    return total;
  }

  /// Hitung streak dari tanggal-tanggal penyelesaian soal yang berurutan.
  int get _streakDays {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;

    final solvedDates = progressBox.values
        .where((p) => p.userId == userId && p.isSolved && p.solvedAt != null)
        .map((p) => DateTime(
            p.solvedAt!.year, p.solvedAt!.month, p.solvedAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (solvedDates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    DateTime check = DateTime(today.year, today.month, today.day);

    for (final d in solvedDates) {
      if (d == check || d == check.subtract(const Duration(days: 1))) {
        streak++;
        check = d;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Rank global: posisi user berdasarkan total poin di antara semua user Hive.
  int get _globalRank {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;

    if (progressBox.isEmpty) return 0;

    // Hitung poin per user
    final Map<String, int> poinPerUser = {};
    for (final p in progressBox.values) {
      if (!p.isSolved) continue;
      final q = questionBox.get(p.questionId) ??
          questionBox.values.where((q) => q.id == p.questionId).firstOrNull;
      if (q == null) continue;
      int poin = 0;
      switch (q.tingkatKesulitan) {
        case DifficultyLevel.easy: poin = 25; break;
        case DifficultyLevel.medium: poin = 50; break;
        case DifficultyLevel.hard: poin = 100; break;
      }
      poinPerUser[p.userId] = (poinPerUser[p.userId] ?? 0) + poin;
    }

    if (poinPerUser.isEmpty) return 0;

    final sorted = poinPerUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rank = sorted.indexWhere((e) => e.key == userId);
    return rank == -1 ? 0 : rank + 1;
  }

  /// Distribusi kesulitan soal yang sudah diselesaikan.
  Map<DifficultyLevel, int> get _difficultyDistribution {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final questionBox = HiveService.instance.questionsBox;

    final solvedIds = progressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .map((p) => p.questionId)
        .toSet();

    final dist = {
      DifficultyLevel.easy: 0,
      DifficultyLevel.medium: 0,
      DifficultyLevel.hard: 0,
    };

    for (final id in solvedIds) {
      final q = questionBox.get(id) ??
          questionBox.values.where((q) => q.id == id).firstOrNull;
      if (q != null) {
        dist[q.tingkatKesulitan] = (dist[q.tingkatKesulitan] ?? 0) + 1;
      }
    }

    return dist;
  }

  double _difficultyPercent(DifficultyLevel level) {
    final dist = _difficultyDistribution;
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;
    return (dist[level] ?? 0) / total;
  }

  /// Hitung jumlah soal yang diselesaikan per hari dalam 7 hari terakhir.
  List<_ActivityDay> get _weeklyActivity {
    final userId = SessionService.instance.userId ?? '';
    final progressBox = HiveService.instance.userProgressBox;
    final now = DateTime.now();
    const hariLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final Map<String, int> countPerDay = {};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      countPerDay['${d.year}-${d.month}-${d.day}'] = 0;
    }

    for (final p in progressBox.values) {
      if (p.userId != userId || !p.isSolved || p.solvedAt == null) continue;
      final d = p.solvedAt!;
      final key = '${d.year}-${d.month}-${d.day}';
      if (countPerDay.containsKey(key)) {
        countPerDay[key] = countPerDay[key]! + 1;
      }
    }

    final result = <_ActivityDay>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      result.add(_ActivityDay(
        label: hariLabels[d.weekday % 7],
        count: countPerDay[key] ?? 0,
        isToday: i == 0,
      ));
    }
    return result;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Stats & Offline Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable:
            HiveService.instance.userProgressBox.listenable(),
        builder: (context, _, __) {
          final totalSolved = _totalSolved;
          final totalPoints = _totalPoints;
          final streak = _streakDays;
          final rank = _globalRank;
          final weekly = _weeklyActivity;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Overview',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Streak Card ───────────────────────────────────────────
                _StatCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warningYellow.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.warningYellow,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Streak',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              )),
                          Text('$streak Days',
                              style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Spacer(),
                      if (streak == 0)
                        Text('Mulai hari ini!',
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textGrey)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Total Solved Card ─────────────────────────────────────
                _StatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL SOLVED',
                              style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.textGrey, letterSpacing: 0.8)),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.successGreen, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: AppColors.successGreen, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNumber(totalSolved),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('soal berhasil diselesaikan',
                          style: AppTextStyles.small
                              .copyWith(color: AppColors.textGrey)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Total Points Card ─────────────────────────────────────
                _StatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL POINTS',
                              style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.textGrey, letterSpacing: 0.8)),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.primaryBlue, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events_outlined,
                                color: AppColors.primaryBlue, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNumber(totalPoints),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rank > 0
                            ? 'Rank #$rank di antara pengguna aktif'
                            : 'Mulai selesaikan soal!',
                        style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Difficulty Distribution ───────────────────────────────
                _StatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Difficulty Dist.',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      _DifficultyBar(
                        label: 'Easy',
                        percent: _difficultyPercent(DifficultyLevel.easy),
                        color: AppColors.easyGreen,
                        count: _difficultyDistribution[DifficultyLevel.easy] ?? 0,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Medium',
                        percent: _difficultyPercent(DifficultyLevel.medium),
                        color: AppColors.primaryBlue,
                        count:
                            _difficultyDistribution[DifficultyLevel.medium] ?? 0,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Hard',
                        percent: _difficultyPercent(DifficultyLevel.hard),
                        color: AppColors.hardRed,
                        count: _difficultyDistribution[DifficultyLevel.hard] ?? 0,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Weekly Activity (dari data real) ──────────────────────
                _StatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Activity',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      _WeeklyActivityChart(data: weekly),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }
}

// ─── Data model weekly ────────────────────────────────────────────────────────
class _ActivityDay {
  final String label;
  final int count;
  final bool isToday;
  const _ActivityDay(
      {required this.label, required this.count, required this.isToday});
}

// ─── Reusable Card ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final Widget child;
  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}

// ─── Difficulty Bar ───────────────────────────────────────────────────────────
class _DifficultyBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final int count;

  const _DifficultyBar({
    required this.label,
    required this.percent,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final pctStr = '${(percent * 100).round()}%';
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: AppTextStyles.small.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppColors.borderGrey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text('$count',
              style: AppTextStyles.smallSemibold
                  .copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.right),
        ),
        SizedBox(
          width: 32,
          child: Text(pctStr,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ─── Weekly Activity Bar Chart (data dari Hive) ───────────────────────────────
class _WeeklyActivityChart extends StatelessWidget {
  final List<_ActivityDay> data;
  const _WeeklyActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty
        ? 1
        : data.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((day) {
          final frac = day.count / effectiveMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: frac < 0.05 ? 0.05 : frac,
                        child: Container(
                          decoration: BoxDecoration(
                            color: day.isToday
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withOpacity(0.25),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (day.count > 0) ...[
                    const SizedBox(height: 2),
                    Text('${day.count}',
                        style: TextStyle(
                          fontSize: 9,
                          color: day.isToday
                              ? AppColors.primaryBlue
                              : AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        )),
                  ] else
                    const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  Text(
                    day.label,
                    style: AppTextStyles.caption.copyWith(
                      color: day.isToday
                          ? AppColors.primaryBlue
                          : AppColors.textGrey,
                      fontWeight: day.isToday ? FontWeight.w600 : FontWeight.w400,
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