import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class KontribusiScreen extends StatelessWidget {
  const KontribusiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Hubungkan dengan fetch soal user dari controller
    final List<Map<String, dynamic>> dummyData = [
      {'pertanyaan': 'Apa kepanjangan dari HTTP?', 'status': 'published'},
      {'pertanyaan': 'Sebutkan 3 prinsip OOP!', 'status': 'pending'},
      {'pertanyaan': 'Cara install Flutter di Linux', 'status': 'rejected', 'alasan': 'Soal terlalu spesifik ke OS tertentu.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontribusiku'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.textLight),
        onPressed: () {
          // Navigasi ke Form Submit Soal (Pastikan route '/submit-soal' sudah dibuat)
          Navigator.pushNamed(context, '/submit-soal');
        },
      ),
      body: dummyData.isEmpty
          ? const AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Belum ada kontribusi',
              subtitle: 'Yuk, mulai ajukan soal untuk membantu teman-temanmu!',
            )
          : ListView.builder(
              padding: AppSpacings.pagePadding,
              itemCount: dummyData.length,
              itemBuilder: (context, index) {
                final item = dummyData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacings.md),
                  child: Padding(
                    padding: AppSpacings.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['pertanyaan'],
                                style: AppTextStyles.bodySemibold,
                              ),
                            ),
                            const SizedBox(width: AppSpacings.sm),
                            AppBadge.status(item['status']),
                          ],
                        ),
                        if (item['status'] == 'rejected') ...[
                          const SizedBox(height: AppSpacings.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                foregroundColor: AppColors.errorRed,
                                side: const BorderSide(color: AppColors.errorRed),
                              ),
                              onPressed: () => _showAlasanDialog(context, item['alasan']),
                              child: const Text('Lihat Alasan'),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAlasanDialog(BuildContext context, String alasan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan', style: AppTextStyles.h2),
        content: Text(alasan, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}