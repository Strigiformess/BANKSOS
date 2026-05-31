// lib/features/admin/screens/admin_kelola_user_screen.dart
// Sprint 5 — Seruni (SL) + Revaldi (RP) guard integration
//
// RBAC Guard dipanggil di initState menggunakan RbacGuard.redirectIfUnauthorized
// Guard CONTROLLER LEVEL ada di AdminController (Revaldi).

import 'package:flutter/material.dart';

import '../../../core/guard/rbac_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../controllers/admin_controller.dart';

class AdminKelolaUserScreen extends StatefulWidget {
  const AdminKelolaUserScreen({super.key});

  @override
  State<AdminKelolaUserScreen> createState() => _AdminKelolaUserScreenState();
}

class _AdminKelolaUserScreenState extends State<AdminKelolaUserScreen> {
  late final AdminController _controller;

  String? _filterRole;    // null = Semua
  String? _filterStatus;  // null = Semua

  @override
  void initState() {
    super.initState();
    _controller = AdminController();

    // ── GUARD RBAC UI LEVEL ─────────────────────────────────────────────────
    // Guard tambahan di UI — redirect jika bukan admin sebelum render.
    // Guard utama ada di AdminController._guardAdmin() (controller level).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RbacGuard.redirectIfUnauthorized(context, requiredRole: 'admin');

      // Load data setelah guard lolos
      _controller.loadUsers();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Filter helper ────────────────────────────────────────────────────────

  List<UserModel> get _filteredUsers {
    return _controller.users.where((u) {
      final roleMatch = _filterRole == null || u.role.name == _filterRole;
      final statusMatch = _filterStatus == null ||
          ((_filterStatus == 'active') == (u.status == UserStatus.active));
      return roleMatch && statusMatch;
    }).toList();
  }

  // ─── Aksi: Ubah Status ────────────────────────────────────────────────────

  Future<void> _onUbahStatus(UserModel user) async {
    final newStatus =
        user.status == UserStatus.active ? 'inactive' : 'active';

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus == 'inactive'
              ? 'Nonaktifkan Akun?'
              : 'Aktifkan Kembali?',
          style: AppTextStyles.h2,
        ),
        content: Text(
          newStatus == 'inactive'
              ? '${user.namaLengkap} tidak akan bisa login setelah dinonaktifkan.'
              : '${user.namaLengkap} akan bisa login kembali.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'inactive'
                  ? AppColors.errorRed
                  : AppColors.successGreen,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus == 'inactive' ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    final result = await _controller.updateUserStatus(
      userId: user.id,
      newStatus: newStatus,
    );

    if (!mounted) return;
    _showSnackBar(result.success, result.errorMessage);
  }

  // ─── Aksi: Ubah Role ─────────────────────────────────────────────────────

  Future<void> _onUbahRole(UserModel user) async {
    String selectedRole = user.role.name;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Ubah Role — ${user.namaLengkap}',
              style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Role saat ini: ${user.role.name}',
                  style: AppTextStyles.body),
              const SizedBox(height: 12),
              ...[
                ('mahasiswa', 'Mahasiswa', AppColors.primaryBlue),
                ('reviewer', 'Reviewer', AppColors.warningYellow),
                ('admin', 'Admin', AppColors.errorRed),
              ].map((item) {
                final (value, label, color) = item;
                return RadioListTile<String>(
                  title: Text(label,
                      style:
                          AppTextStyles.body.copyWith(color: color)),
                  value: value,
                  groupValue: selectedRole,
                  activeColor: color,
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v!),
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
              onPressed: () => Navigator.pop(ctx, selectedRole),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !mounted) return;
    if (confirmed == user.role.name) return; // tidak ada perubahan

    final result = await _controller.updateUserStatus(
      userId: user.id,
      newRole: confirmed,
    );

    if (!mounted) return;
    _showSnackBar(result.success, result.errorMessage);
  }

  void _showSnackBar(bool success, String? errorMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Perubahan berhasil disimpan.'
            : (errorMsg ?? 'Terjadi kesalahan.')),
        backgroundColor:
            success ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
      ),
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
                      _controller.errorMessage ?? 'Terjadi kesalahan.',
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

          final filtered = _filteredUsers;

          return Column(
            children: [
              // ── Stats Bar ──────────────────────────────────────────────
              _buildStatsBar(),

              // ── Filter ─────────────────────────────────────────────────
              _buildFilterBar(),

              const Divider(height: 1),

              // ── Tabel / List User ──────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'Tidak ada pengguna',
                        subtitle: 'Coba ubah filter.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _UserCard(
                              user: filtered[i],
                              isProcessing: _controller.isProcessing,
                              currentAdminId: '',
                              onUbahStatus: () =>
                                  _onUbahStatus(filtered[i]),
                              onUbahRole: () =>
                                  _onUbahRole(filtered[i]),
                            ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatPill(
            label: 'Aktif',
            value: _controller.totalUserAktif,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'Nonaktif',
            value: _controller.totalUserInaktif,
            color: AppColors.errorRed,
          ),
          const Spacer(),
          Text(
            '${_controller.users.length} total',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Filter Role
          ...[
            (null, 'Semua Role'),
            ('mahasiswa', 'Mahasiswa'),
            ('reviewer', 'Reviewer'),
            ('admin', 'Admin'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChipItem(
                label: item.$2,
                isSelected: _filterRole == item.$1,
                onTap: () =>
                    setState(() => _filterRole = item.$1),
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: AppColors.borderGrey),
          const SizedBox(width: 8),

          // Filter Status
          ...[
            (null, 'Semua Status'),
            ('active', 'Aktif'),
            ('inactive', 'Nonaktif'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChipItem(
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

// ─── Widget: User Card ────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isProcessing;
  final String currentAdminId;
  final VoidCallback onUbahStatus;
  final VoidCallback onUbahRole;

  const _UserCard({
    required this.user,
    required this.isProcessing,
    required this.currentAdminId,
    required this.onUbahStatus,
    required this.onUbahRole,
  });

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppColors.errorRed;
      case UserRole.reviewer:
        return AppColors.warningYellow;
      default:
        return AppColors.primaryBlue;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.reviewer:
        return 'Reviewer';
      default:
        return 'Mahasiswa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == UserStatus.active;
    final isSelf = user.id == currentAdminId;

    return Card(
      child: Padding(
        padding: AppSpacings.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: user.namaLengkap, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.namaLengkap,
                          style: AppTextStyles.bodySemibold),
                      Text(user.email,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis),
                      if (user.nim != null)
                        Text('NIM: ${user.nim}',
                            style: AppTextStyles.caption),
                    ],
                  ),
                ),
                // Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.publishedBg
                        : AppColors.archivedBg,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Nonaktif',
                    style: AppTextStyles.captionBold.copyWith(
                      color: isActive
                          ? AppColors.publishedText
                          : AppColors.archivedText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              children: [
                // Badge role
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _roleColor.withOpacity(0.1),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                        color: _roleColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _roleLabel,
                    style: AppTextStyles.captionBold
                        .copyWith(color: _roleColor),
                  ),
                ),

                const Spacer(),

                if (isSelf)
                  const Text('(Akun saya)',
                      style: AppTextStyles.caption)
                else if (isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue),
                  )
                else ...[
                  // Tombol ubah role
                  OutlinedButton.icon(
                    onPressed: onUbahRole,
                    icon: const Icon(Icons.manage_accounts_outlined,
                        size: 14),
                    label: const Text('Role'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: AppTextStyles.captionBold,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tombol ubah status
                  ElevatedButton.icon(
                    onPressed: onUbahStatus,
                    icon: Icon(
                      isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outlined,
                      size: 14,
                    ),
                    label: Text(
                        isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: AppTextStyles.captionBold,
                    ),
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

// ─── Widget helper ────────────────────────────────────────────────────────────

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
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            '$value ',
            style: AppTextStyles.bodySemibold.copyWith(color: color),
          ),
          Text(label, style: AppTextStyles.small.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
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
            color: isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}