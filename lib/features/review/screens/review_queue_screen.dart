import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Pemrograman Web', 'Sistem Operasi', 'Basis Data'];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pendingSoal = [
      {'id': '1', 'pertanyaan': 'Apa fungsi tag <canvas> di HTML5?', 'kategori': 'Pemrograman Web', 'submitter': 'Budi (2215...)'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Review')),
      body: Column(
        children: [
          // ─── Filter Chips Kategori (Seperti di Mockup) ───
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.bgWhite,
                    selectedColor: AppColors.lightBlue,
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: AppTextStyles.smallSemibold.copyWith(
                      color: isSelected ? AppColors.primaryBlue : AppColors.textGrey,
                    ),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
                    side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── List Antrian Soal ───
          Expanded(
            child: pendingSoal.isEmpty
                ? const AppEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Antrian Kosong',
                    subtitle: 'Wah, semua soal sudah berhasil direview!',
                  )
                : ListView.builder(
                    padding: AppSpacings.pagePadding.copyWith(top: 0),
                    itemCount: pendingSoal.length,
                    itemBuilder: (context, index) {
                      final item = pendingSoal[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacings.lg),
                        child: Padding(
                          padding: AppSpacings.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kategori Kecil di atas
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Text(item['kategori'], style: AppTextStyles.captionBold),
                              ),
                              const SizedBox(height: AppSpacings.sm),
                              Text(item['pertanyaan'], style: AppTextStyles.bodyLarge),
                              const SizedBox(height: AppSpacings.sm),
                              Text('Diajukan oleh: ${item['submitter']}', style: AppTextStyles.caption),
                              
                              const SizedBox(height: AppSpacings.lg),
                              // ─── Garis Putus-putus ───
                              const _DashedDivider(),
                              const SizedBox(height: AppSpacings.md),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(icon: Icons.check_circle_outline, label: 'Setujui', color: AppColors.successGreen, onTap: () {}),
                                  _buildActionButton(icon: Icons.edit_outlined, label: 'Revisi', color: AppColors.warningYellow, onTap: () {}),
                                  _buildActionButton(icon: Icons.cancel_outlined, label: 'Tolak', color: AppColors.errorRed, onTap: () {}),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.smallSemibold.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// Widget Bantuan untuk Garis Putus-putus
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: AppColors.borderGrey)),
            );
          }),
        );
      },
    );
  }
}