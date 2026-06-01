// lib/features/question/screens/offline_questions_screen.dart
// PIC: Jibril (MJ)
// Sprint 2: Implementasi deteksi status koneksi dan halaman Mode Offline

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../screens/question_detail_screen.dart';

final downloadedQuestionsProvider = FutureProvider<List<QuestionModel>>((ref) async {
  final hive = HiveService.instance.questionsBox;
  final downloadedQuestions = hive.values.toList();
  return downloadedQuestions;
});

class OfflineQuestionsScreen extends ConsumerWidget {
  const OfflineQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(downloadedQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soal Offline'),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_outlined,
                        size: 64, color: AppColors.primaryBlue),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada soal yang diunduh.\nSilakan unduh kategori dari Bank Soal terlebih dahulu.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacings.pagePadding,
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final question = questions[index];
              return InkWell(
                borderRadius: AppRadius.lgAll,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionDetailScreen(question: question),
                  ),
                ),
                child: Container(
                  padding: AppSpacings.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: AppColors.borderGrey.withValues(alpha:0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.pertanyaan,
                              style: AppTextStyles.bodySemibold,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge.difficulty(question.tingkatKesulitan.name),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              size: 16, color: AppColors.warningYellow),
                          const SizedBox(width: 6),
                          Text(
                            '${question.hints.length} Hint',
                            style: AppTextStyles.caption,
                          ),
                          const Spacer(),
                          Text(
                            question.kategoriNama,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat soal offline: $error',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
