// lib/features/statistics/screens/statistics_screen.dart
// PIC: Seruni 
// Sprint 5: Buat halaman Kelola Soal beserta statistik di header
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
  // ─── Computed Stats ───────────────────────────────────────────────────────

  int get _totalSolved {
    final userId = SessionService.instance.userId ?? '';
    return HiveService.instance.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;
  }

  int get _totalPoints => _totalSolved * 10;

  int get _globalRank => _totalSolved > 0 ? 42 : 0;

  int get _streakDays => 5;

  /// Distribusi kesulitan soal yang sudah diselesaikan
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
                          Text(
                            'Streak',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$_streakDays Days',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                          Text(
                            'TOTAL SOLVED',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.textGrey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.successGreen,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.successGreen,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNumber(_totalSolved),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+12% from last week',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                          Text(
                            'TOTAL POINTS',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.textGrey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_outlined,
                              color: AppColors.primaryBlue,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNumber(_totalPoints),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _globalRank > 0
                            ? 'Rank #$_globalRank Global'
                            : 'Mulai selesaikan soal!',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
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
                      Text(
                        'Difficulty Dist.',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DifficultyBar(
                        label: 'Easy',
                        percent: _totalSolved == 0
                            ? 0.45
                            : _difficultyPercent(DifficultyLevel.easy),
                        color: AppColors.easyGreen,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Medium',
                        percent: _totalSolved == 0
                            ? 0.35
                            : _difficultyPercent(DifficultyLevel.medium),
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Hard',
                        percent: _totalSolved == 0
                            ? 0.20
                            : _difficultyPercent(DifficultyLevel.hard),
                        color: AppColors.hardRed,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Weekly Activity ───────────────────────────────────────
                _StatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _WeeklyActivityChart(),
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

  const _DifficultyBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pctStr = '${(percent * 100).round()}%';
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            pctStr,
            style: AppTextStyles.smallSemibold.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Activity Bar Chart ────────────────────────────────────────────────

class _WeeklyActivityChart extends StatelessWidget {
  // Demo data — in production, compute from progressBox
  final List<int> _data = const [3, 7, 5, 9, 4, 6, 2];
  final List<String> _days = const [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  _WeeklyActivityChart();

  @override
  Widget build(BuildContext context) {
    final maxVal = _data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_data.length, (i) {
          final frac = maxVal > 0 ? _data[i] / maxVal : 0.0;
          final isToday = i == DateTime.now().weekday - 1;
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
                            color: isToday
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
                  const SizedBox(height: 4),
                  Text(
                    _days[i],
                    style: AppTextStyles.caption.copyWith(
                      color: isToday
                          ? AppColors.primaryBlue
                          : AppColors.textGrey,
                      fontWeight: isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}