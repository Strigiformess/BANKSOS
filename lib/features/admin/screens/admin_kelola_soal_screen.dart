// lib/features/admin/screens/admin_kelola_soal_screen.dart
// Sprint 5 — Seruni + Revaldi guard integration
//
// Halaman admin untuk mengelola semua soal (termasuk arsip).
// RBAC guard di initState (UI) + AdminController._guardAdmin() (controller).

import 'package:flutter/material.dart';

import '../../../core/guard/rbac_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../controllers/admin_controller.dart';

class AdminKelolasoalScreen extends StatefulWidget {
  const AdminKelolasoalScreen({super.key});

  @override
  State<AdminKelolasoalScreen> createState() =>
      _AdminKelolasoalScreenState();
}

class _AdminKelolasoalScreenState
    extends State<AdminKelolasoalScreen> {
  late final AdminController _controller;

  String? _filterStatus;   // null = Semua
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AdminController();

    // ── GUARD RBAC UI LEVEL ─────────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RbacGuard.redirectIfUnauthorized(context, requiredRole: 'admin');
      _controller.loadSoal();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Filter helper ────────────────────────────────────────────────────────

  List<QuestionModel> get _filteredSoal {
    return _controller.soal.where((q) {
      final statusMatch =
          _filterStatus == null || q.status.name == _filterStatus;
      final searchMatch = _searchQuery.isEmpty ||
          q.pertanyaan
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          q.kategoriNama
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
  }

  // ─── Aksi: Ubah Status Soal ───────────────────────────────────────────────

  Future<void> _onUbahStatus(
      QuestionModel soal, String newStatus) async {
    final labels = {
      'archived': 'Arsipkan',
      'inactive': 'Nonaktifkan',
      'published': 'Aktifkan Kembali',
    };

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${labels[newStatus] ?? newStatus} Soal?',
          style: AppTextStyles.h2,
        ),
        content: Text(
          'Soal "${soal.pertanyaan.length > 60 ? '${soal.pertanyaan.substring(0, 60)}…' : soal.pertanyaan}" akan diubah statusnya.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'published'
                  ? AppColors.successGreen
                  : newStatus == 'archived'
                      ? AppColors.warningYellow
                      : AppColors.errorRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(labels[newStatus] ?? newStatus,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    final result = await _controller.updateStatusSoal(
      questionId: soal.id,
      newStatus: newStatus,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Status soal berhasil diubah.'
            : (result.errorMessage ?? 'Terjadi kesalahan.')),
        backgroundColor: result.success
            ? AppColors.successGreen
            : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Soal')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loadState == AdminLoadState.error) {
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
                      _controller.errorMessage ??
                          'Terjadi kesalahan.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (_controller.isLoading) {
            return const AppLoadingIndicator();
          }

          final filtered = _filteredSoal;

          return Column(
            children: [
              // ── Stats Header ───────────────────────────────────────────
              _buildStatsHeader(),

              // ── Search + Filter ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari soal atau kategori...',
                    isDense: true,
                    prefixIcon: const Icon(
                        Icons.search_outlined,
                        size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                ),
              ),

              _buildFilterBar(),

              const Divider(height: 1),

              // ── List Soal ──────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.quiz_outlined,
                        title: 'Tidak ada soal',
                        subtitle: 'Coba ubah filter atau kata kunci.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) => _SoalCard(
                          soal: filtered[i],
                          isProcessing: _controller.isProcessing,
                          onArsip: () => _onUbahStatus(
                              filtered[i], 'archived'),
                          onNonaktif: () => _onUbahStatus(
                              filtered[i], 'inactive'),
                          onAktif: () => _onUbahStatus(
                              filtered[i], 'published'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      color: AppColors.bgWhite,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatPill(
            label: 'Aktif',
            value: _controller.totalSoalAktif,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'Arsip',
            value: _controller.totalSoalArsip,
            color: AppColors.textGrey,
          ),
          const Spacer(),
          Text(
            '${_controller.soal.length} total soal',
            style: AppTextStyles.smallSemibold
                .copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ...[
            (null, 'Semua'),
            ('published', 'Aktif'),
            ('pending', 'Pending'),
            ('archived', 'Arsip'),
            ('inactive', 'Nonaktif'),
            ('rejected', 'Ditolak'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: item.$2,
                isSelected: _filterStatus == item.$1,
                onTap: () =>
                    setState(() => _filterStatus = item.$1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Soal Card ────────────────────────────────────────────────────────

class _SoalCard extends StatelessWidget {
  final QuestionModel soal;
  final bool isProcessing;
  final VoidCallback onArsip;
  final VoidCallback onNonaktif;
  final VoidCallback onAktif;

  const _SoalCard({
    required this.soal,
    required this.isProcessing,
    required this.onArsip,
    required this.onNonaktif,
    required this.onAktif,
  });

  bool get _isPublished => soal.status == QuestionStatus.published;
  bool get _isArchived => soal.status == QuestionStatus.archived;
  bool get _isInactive => soal.status == QuestionStatus.inactive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacings.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header baris
            Row(
              children: [
                AppBadge.difficulty(soal.tingkatKesulitan.name),
                const SizedBox(width: 6),
                AppBadge.status(soal.status.name),
                const Spacer(),
                Text(soal.kategoriNama,
                    style: AppTextStyles.caption),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              soal.pertanyaan,
              style: AppTextStyles.bodySemibold,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Tombol aksi
            if (isProcessing)
              const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Aktifkan kembali (jika arsip/nonaktif)
                  if (_isArchived || _isInactive)
                    _ActionButton(
                      icon: Icons.restore_outlined,
                      label: 'Aktifkan',
                      color: AppColors.successGreen,
                      onTap: onAktif,
                    ),

                  // Nonaktifkan (jika published)
                  if (_isPublished) ...[
                    _ActionButton(
                      icon: Icons.visibility_off_outlined,
                      label: 'Nonaktif',
                      color: AppColors.warningYellow,
                      onTap: onNonaktif,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.archive_outlined,
                      label: 'Arsipkan',
                      color: AppColors.textGrey,
                      onTap: onArsip,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: AppRadius.smAll,
          border: Border.all(color: color.withValues(alpha:0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.captionBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Text('$value ',
              style: AppTextStyles.bodySemibold.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.small.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color:
                isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}