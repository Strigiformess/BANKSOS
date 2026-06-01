// lib/features/kontribusi/controllers/kontribusi_controller.dart
// PIC: Seruni Libertina Islami (SL)
// Catatan: Memisahkan logic pengambilan data kontribusi dari UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';

final kontribusiProvider = Provider<List<QuestionModel>>((ref) {
  final currentUserId = SessionService.instance.userId;
  final hive = HiveService.instance.questionsBox;
  
  final userQuestions = hive.values
      .where((q) => q.submittedBy == currentUserId)
      .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
  return userQuestions;
});

final rewardPointsProvider = Provider<int>((ref) {
  final questions = ref.watch(kontribusiProvider);
  // Asumsi poin per submission yang di-publish = 50
  return questions.where((q) => q.status.name == 'published').length * 50;
});