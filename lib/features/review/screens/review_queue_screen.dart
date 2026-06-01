// lib/features/review/screens/review_queue_screen.dart
// Sprint 4 — Seruni UI + Revaldi guard & controller integration
//
// Update dari Revaldi (Sprint 4 Kamis):
//   - Guard RBAC di initState (redirect jika bukan reviewer)
//   - Terhubung ke ReviewController untuk aksi approve/revisi/reject
//   - Validasi dilakukan di controller level (bukan hanya UI)

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import 'package:banksos/core/guard/rbac_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../controllers/review_controller.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  late final ReviewController _controller;
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Pemrograman Web',
    'Sistem Operasi',
    'Basis Data',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ReviewController();

    // Guard RBAC: redirect ke halaman lain jika bukan reviewer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RbacGuard.redirectIfUnauthorized(context, requiredRole: 'reviewer');

      // Load soal pending setelah guard lolos
      _controller.loadSoalPending();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Approve ───────────────────────────────────────────────────────────────

  Future<void> _onApprove(String questionId) async {
    // Tampilkan dialog untuk memilih tingkat kesulitan
    final tingkat = await _showTingkatKesulitanDialog();
    if (tingkat == null || !mounted) return;

    final result = await _controller.approve(
      questionId: questionId,
      tingkatKesulitan: tingkat,
    );

    if (!mounted) return;
    _showResultSnackBar(
      result.success,
      successMsg: 'Soal berhasil disetujui dan dipublikasikan.',
      errorMsg: result.errorMessage,
    );
  }

  // ─── Reject ────────────────────────────────────────────────────────────────

  Future<void> _onReject(String questionId) async {
    final alasan = await _showAlasanDialog();
    if (alasan == null || !mounted) return;

    final result = await _controller.reject(
      questionId: questionId,
      alasan: alasan,
    );

    if (!mounted) return;
    _showResultSnackBar(
      result.success,
      successMsg: 'Soal ditolak. Mahasiswa akan mendapat notifikasi alasan.',
      errorMsg: result.errorMessage,
    );
  }

  // ─── Revisi ────────────────────────────────────────────────────────────────

  Future<void> _onRevisi(String questionId, String pertanyaanAwal, String jawabanAwal) async {
    final data = await _showRevisiDialog(pertanyaanAwal, jawabanAwal);
    if (data == null || !mounted) return;

    final result = await _controller.revisi(
      questionId: questionId,
      pertanyaanBaru: data['pertanyaan']!,
      jawabanBaru: data['jawaban']!,
      tingkatKesulitan: data['tingkat']!,
    );

    if (!mounted) return;
    _showResultSnackBar(
      result.success,
      successMsg: 'Soal berhasil direvisi dan dipublikasikan.',
      errorMsg: result.errorMessage,
    );
  }

  // ─── Dialog: Pilih Tingkat Kesulitan ──────────────────────────────────────

  Future<String?> _showTingkatKesulitanDialog() {
    String selected = 'easy';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pilih Tingkat Kesulitan', style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reviewer wajib menentukan tingkat kesulitan soal:',
                  style: AppTextStyles.body),
              const SizedBox(height: 16),
              ...[
                ('easy', 'Mudah', AppColors.easyGreen),
                ('medium', 'Sedang', AppColors.mediumAmber),
                ('hard', 'Sulit', AppColors.hardRed),
              ].map((item) {
                final (value, label, color) = item;
                return RadioListTile<String>(
                  title: Text(label,
                      style: AppTextStyles.body.copyWith(color: color)),
                  value: value,
                  groupValue: selected,
                  activeColor: color,
                  onChanged: (v) => setDialogState(() => selected = v!),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Setujui & Publikasikan'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialog: Alasan Penolakan ─────────────────────────────────────────────

  Future<String?> _showAlasanDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alasan akan ditampilkan kepada mahasiswa:',
                style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tulis alasan penolakan (wajib, minimal 10 karakter)...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed),
            onPressed: () {
              if (ctrl.text.trim().length < 10) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan minimal 10 karakter.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Tolak Soal'),
          ),
        ],
      ),
    );
  }

  // ─── Dialog: Form Revisi ──────────────────────────────────────────────────

  Future<Map<String, String>?> _showRevisiDialog(
      String pertanyaanAwal, String jawabanAwal) {
    final pCtrl = TextEditingController(text: pertanyaanAwal);
    final jCtrl = TextEditingController(text: jawabanAwal);
    String tingkat = 'easy';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Revisi Soal', style: AppTextStyles.h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pertanyaan:', style: AppTextStyles.bodySemibold),
                const SizedBox(height: 4),
                TextField(
                  controller: pCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Pertanyaan soal'),
                ),
                const SizedBox(height: 12),
                const Text('Jawaban:', style: AppTextStyles.bodySemibold),
                const SizedBox(height: 4),
                TextField(
                  controller: jCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Jawaban (akan disimpan lowercase)'),
                ),
                const SizedBox(height: 12),
                const Text('Tingkat Kesulitan:', style: AppTextStyles.bodySemibold),
                DropdownButton<String>(
                  value: tingkat,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Mudah')),
                    DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                    DropdownMenuItem(value: 'hard', child: Text('Sulit')),
                  ],
                  onChanged: (v) => setDialogState(() => tingkat = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningYellow),
              onPressed: () {
                if (pCtrl.text.trim().length < 10 || jCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Isi pertanyaan (min 10 karakter) dan jawaban.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'pertanyaan': pCtrl.text.trim(),
                  'jawaban': jCtrl.text.trim(),
                  'tingkat': tingkat,
                });
              },
              child: const Text('Simpan & Publikasikan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Snackbar hasil aksi ──────────────────────────────────────────────────

  void _showResultSnackBar(
    bool success, {
    required String successMsg,
    String? errorMsg,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : (errorMsg ?? 'Terjadi kesalahan.')),
        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Review')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          // Error state (termasuk RBAC error)
          if (_controller.loadState == ReviewLoadState.error) {
            return Center(
              child: Padding(
                padding: AppSpacings.pagePadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 48, color: AppColors.errorRed),
                    const SizedBox(height: 12),
                    Text(
                      _controller.errorMessage ?? 'Terjadi kesalahan.',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Loading state
          if (_controller.loadState == ReviewLoadState.loading) {
            return const AppLoadingIndicator();
          }

          return Column(
            children: [
              // ── Filter Chips Kategori ───────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        backgroundColor: AppColors.bgWhite,
                        selectedColor: AppColors.lightBlue,
                        checkmarkColor: AppColors.primaryBlue,
                        labelStyle: AppTextStyles.smallSemibold.copyWith(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textGrey,
                        ),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pill),
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.borderGrey),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Badge jumlah soal pending ───────────────────────────────
              if (_controller.jumlahPending > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.pendingBg,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          '${_controller.jumlahPending} soal menunggu review',
                          style: AppTextStyles.smallSemibold.copyWith(
                              color: AppColors.pendingText),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── List Antrian Soal ───────────────────────────────────────
              Expanded(
                child: _controller.soalPending.isEmpty &&
                        _controller.loadState == ReviewLoadState.loaded
                    ? const AppEmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'Antrian Kosong',
                        subtitle:
                            'Wah, semua soal sudah berhasil direview!',
                      )
                    : ListView.builder(
                        padding: AppSpacings.pagePadding.copyWith(top: 4),
                        itemCount: _controller.soalPending.length,
                        itemBuilder: (context, index) {
                          final soal = _controller.soalPending[index];

                          // Filter kategori
                          if (_selectedFilter != 'Semua' &&
                              soal.kategoriNama != _selectedFilter) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppSpacings.lg),
                            child: Padding(
                              padding: AppSpacings.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kategori
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.bgLight,
                                      borderRadius: AppRadius.smAll,
                                    ),
                                    child: Text(soal.kategoriNama,
                                        style: AppTextStyles.captionBold),
                                  ),
                                  const SizedBox(height: AppSpacings.sm),

                                  // Pertanyaan
                                  Text(soal.pertanyaan,
                                      style: AppTextStyles.bodyLarge),
                                  const SizedBox(height: AppSpacings.sm),

                                  // Placeholder jawaban (tersembunyi untuk reviewer)
                                  Text(
                                    'Jawaban: ${soal.jawaban}',
                                    style: AppTextStyles.bodySemibold.copyWith(
                                        color: AppColors.primaryBlue),
                                  ),

                                  if (soal.hints.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacings.xs),
                                    Text(
                                      '${soal.hints.length} hint tersedia',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],

                                  const SizedBox(height: AppSpacings.lg),
                                  const _DashedDivider(),
                                  const SizedBox(height: AppSpacings.md),

                                  // Tombol aksi
                                  _controller.isProcessing
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryBlue,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildActionButton(
                                              icon:
                                                  Icons.check_circle_outline,
                                              label: 'Setujui',
                                              color: AppColors.successGreen,
                                              onTap: () =>
                                                  _onApprove(soal.id),
                                            ),
                                            _buildActionButton(
                                              icon: Icons.edit_outlined,
                                              label: 'Revisi',
                                              color: AppColors.warningYellow,
                                              onTap: () => _onRevisi(
                                                soal.id,
                                                soal.pertanyaan,
                                                soal.jawaban,
                                              ),
                                            ),
                                            _buildActionButton(
                                              icon: Icons.cancel_outlined,
                                              label: 'Tolak',
                                              color: AppColors.errorRed,
                                              onTap: () =>
                                                  _onReject(soal.id),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style:
                    AppTextStyles.smallSemibold.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Widget Garis Putus-putus ─────────────────────────────────────────────────

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
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: AppColors.borderGrey)),
            );
          }),
        );
      },
    );
  }
}