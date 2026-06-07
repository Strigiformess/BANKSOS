// lib/features/kontribusi/controllers/kontribusi_controller.dart
// REFACTOR: Poin reward dihitung berdasarkan tingkat kesulitan soal
// yang sudah dipublish (bukan hanya jumlah flat × 50).
// Easy published = 10 pts, Medium = 20 pts, Hard = 30 pts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';

/// Daftar soal yang pernah dikontribusikan user yang sedang login,
/// diurutkan dari yang paling baru.
final kontribusiProvider = Provider<List<QuestionModel>>((ref) {
  final currentUserId = SessionService.instance.userId;
  if (currentUserId == null || currentUserId.isEmpty) return [];

  final hive = HiveService.instance.questionsBox;

  final userQuestions = hive.values
      .where((q) => q.submittedBy == currentUserId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return userQuestions;
});

/// Total poin reward dari kontribusi soal yang sudah dipublish.
///
/// Skema poin per soal yang diterima (published):
///   Easy   = 10 poin
///   Medium = 20 poin
///   Hard   = 30 poin
///
/// Soal yang pending/rejected/archived tidak memberikan poin.
final rewardPointsProvider = Provider<int>((ref) {
  final questions = ref.watch(kontribusiProvider);

  int total = 0;
  for (final q in questions) {
    if (q.status != QuestionStatus.published) continue;
    switch (q.tingkatKesulitan) {
      case DifficultyLevel.easy:
        total += 10;
        break;
      case DifficultyLevel.medium:
        total += 20;
        break;
      case DifficultyLevel.hard:
        total += 30;
        break;
    }
  }
  return total;
});

/// Statistik detail kontribusi user.
final kontribusiStatsProvider = Provider<KontribusiStats>((ref) {
  final questions = ref.watch(kontribusiProvider);

  final published =
      questions.where((q) => q.status == QuestionStatus.published).length;
  final pending =
      questions.where((q) => q.status == QuestionStatus.pending).length;
  final rejected =
      questions.where((q) => q.status == QuestionStatus.rejected).length;

  return KontribusiStats(
    total: questions.length,
    published: published,
    pending: pending,
    rejected: rejected,
  );
});

/// Data class untuk statistik kontribusi.
class KontribusiStats {
  final int total;
  final int published;
  final int pending;
  final int rejected;

  const KontribusiStats({
    required this.total,
    required this.published,
    required this.pending,
    required this.rejected,
  });
}