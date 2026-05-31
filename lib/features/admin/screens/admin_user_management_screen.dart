// lib/features/admin/screens/admin_user_management_screen.dart
// Sprint 5 — Seruni (SL): Admin Kelola Pengguna
//
// Fitur:
//   - Tabel user dengan kolom: Nama, NIM/Email, Role, Status, Tanggal Bergabung
//   - Filter: Role (Semua/Mahasiswa/Reviewer/Admin), Status (Aktif/Nonaktif)
//   - Tombol aksi per baris: Ubah Role, Ubah Status, Hapus
//   - Dialog konfirmasi sebelum mengubah data

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where, modify;

import '../../../core/theme/app_theme.dart';
import '../../../core/guard/rbac_guard.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../../shared/widgets/app_widgets.dart';

// ─── Enum Filter ──────────────────────────────────────────────────────────────

enum RoleFilter { all, mahasiswa, reviewer, admin }
enum StatusFilter { all, active, inactive }

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final MongoDBService _db = MongoDBService.instance;
  final SessionService _session = SessionService.instance;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];

  RoleFilter _roleFilter = RoleFilter.all;
  StatusFilter _statusFilter = StatusFilter.all;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  // ─── Guard RBAC ───────────────────────────────────────────────────────────

  void _checkAuthAndLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        RbacGuard.redirectIfUnauthorized(context, requiredRole: 'admin');
        _loadUsers();
      } catch (e) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ─── Load Users dari MongoDB ──────────────────────────────────────────────

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isOnline = await ConnectivityService.instance.checkNow();

    try {
      if (!isOnline || !_db.isConnected) {
        setState(() {
          _errorMessage =
              'Halaman kelola pengguna membutuhkan koneksi internet.';
          _isLoading = false;
        });
        return;
      }

      final rawList = await _db.users.find({}).toList();
      final users = rawList
          .map((map) => UserModel.fromMap(map))
          .toList();

      // Urutkan: terbaru dulu
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat data pengguna: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  // ─── Apply Filters ────────────────────────────────────────────────────────

  void _applyFilters() {
    _filteredUsers = _allUsers.where((user) {
      // Filter role
      if (_roleFilter != RoleFilter.all) {
        final roleMap = {
          RoleFilter.mahasiswa: UserRole.mahasiswa,
          RoleFilter.reviewer: UserRole.reviewer,
          RoleFilter.admin: UserRole.admin,
        };
        if (user.role != roleMap[_roleFilter]) return false;
      }

      // Filter status
      if (_statusFilter != StatusFilter.all) {
        final statusMap = {
          StatusFilter.active: UserStatus.active,
          StatusFilter.inactive: UserStatus.inactive,
        };
        if (user.status != statusMap[_statusFilter]) return false;
      }

      return true;
    }).toList();
  }

  void _setRoleFilter(RoleFilter filter) {
    setState(() {
      _roleFilter = filter;
      _applyFilters();
    });
  }

  void _setStatusFilter(StatusFilter filter) {
    setState(() {
      _statusFilter = filter;
      _applyFilters();
    });
  }

  // ─── Update User Status ───────────────────────────────────────────────────

  Future<void> _updateUserStatus(UserModel user, UserStatus newStatus) async {
    setState(() => _isProcessing = true);

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline || !_db.isConnected) {
        throw Exception('Koneksi internet diperlukan untuk mengubah status.');
      }

      await _db.users.updateOne(
        where.id(ObjectId.parse(user.id)),
        modify.set('status', newStatus.name),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status ${user.namaLengkap} berhasil diubah menjadi '
              '${newStatus.name.toUpperCase()}.',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── Update User Role ─────────────────────────────────────────────────────

  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    setState(() => _isProcessing = true);

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline || !_db.isConnected) {
        throw Exception('Koneksi internet diperlukan untuk mengubah role.');
      }

      await _db.users.updateOne(
        where.id(ObjectId.parse(user.id)),
        modify.set('role', newRole.name),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role ${user.namaLengkap} berhasil diubah menjadi '
              '${newRole.name.toUpperCase()}.',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── Dialog: Ubah Status ──────────────────────────────────────────────────

  Future<void> _showChangeStatusDialog(UserModel user) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Status ${user.namaLengkap}', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<UserStatus>(
              title: const Text('Aktif'),
              value: UserStatus.active,
              groupValue: user.status,
              activeColor: AppColors.successGreen,
              onChanged: (newStatus) => Navigator.pop(ctx, newStatus),
            ),
            RadioListTile<UserStatus>(
              title: const Text('Nonaktif'),
              value: UserStatus.inactive,
              groupValue: user.status,
              activeColor: AppColors.errorRed,
              onChanged: (newStatus) => Navigator.pop(ctx, newStatus),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    ).then((newStatus) {
      if (newStatus != null && newStatus != user.status) {
        _updateUserStatus(user, newStatus);
      }
    });
  }

  // ─── Dialog: Ubah Role ────────────────────────────────────────────────────

  Future<void> _showChangeRoleDialog(UserModel user) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Role ${user.namaLengkap}', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<UserRole>(
              title: const Text('Mahasiswa'),
              value: UserRole.mahasiswa,
              groupValue: user.role,
              activeColor: AppColors.primaryBlue,
              onChanged: (newRole) => Navigator.pop(ctx, newRole),
            ),
            RadioListTile<UserRole>(
              title: const Text('Reviewer'),
              value: UserRole.reviewer,
              groupValue: user.role,
              activeColor: AppColors.warningYellow,
              onChanged: (newRole) => Navigator.pop(ctx, newRole),
            ),
            RadioListTile<UserRole>(
              title: const Text('Admin'),
              value: UserRole.admin,
              groupValue: user.role,
              activeColor: AppColors.errorRed,
              onChanged: (newRole) => Navigator.pop(ctx, newRole),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    ).then((newRole) {
      if (newRole != null && newRole != user.role) {
        _updateUserRole(user, newRole);
      }
    });
  }

  // ─── Format Date ──────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.reviewer:
        return 'Reviewer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _getStatusLabel(UserStatus status) {
    return status == UserStatus.active ? 'Aktif' : 'Nonaktif';
  }

  Color _getStatusColor(UserStatus status) {
    return status == UserStatus.active
        ? AppColors.successGreen
        : AppColors.errorRed;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        elevation: 0,
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacings.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined,
                            size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Filter Bar ─────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Filter Role
                          _buildFilterChip(
                            label: 'Semua',
                            isSelected: _roleFilter == RoleFilter.all,
                            onTap: () => _setRoleFilter(RoleFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Mahasiswa',
                            isSelected: _roleFilter == RoleFilter.mahasiswa,
                            onTap: () => _setRoleFilter(RoleFilter.mahasiswa),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Reviewer',
                            isSelected: _roleFilter == RoleFilter.reviewer,
                            onTap: () => _setRoleFilter(RoleFilter.reviewer),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Admin',
                            isSelected: _roleFilter == RoleFilter.admin,
                            onTap: () => _setRoleFilter(RoleFilter.admin),
                          ),
                          const SizedBox(width: 16),
                          // Status filter
                          _buildFilterChip(
                            label: 'Semua Status',
                            isSelected: _statusFilter == StatusFilter.all,
                            onTap: () => _setStatusFilter(StatusFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Aktif',
                            isSelected: _statusFilter == StatusFilter.active,
                            color: AppColors.successGreen,
                            onTap: () => _setStatusFilter(StatusFilter.active),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Nonaktif',
                            isSelected: _statusFilter == StatusFilter.inactive,
                            color: AppColors.errorRed,
                            onTap: () =>
                                _setStatusFilter(StatusFilter.inactive),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ── Tabel User ────────────────────────────────────
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.people_outline,
                              title: 'Tidak ada pengguna',
                              subtitle:
                                  'Coba ubah filter atau refresh halaman.',
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 16,
                                horizontalMargin: 16,
                                headingRowColor: WidgetStateColor.resolveWith(
                                  (_) => AppColors.bgWhite,
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text('Nama'),
                                  ),
                                  DataColumn(
                                    label: Text('Email / NIM'),
                                  ),
                                  DataColumn(
                                    label: Text('Role'),
                                  ),
                                  DataColumn(
                                    label: Text('Status'),
                                  ),
                                  DataColumn(
                                    label: Text('Bergabung'),
                                  ),
                                  DataColumn(
                                    label: Text('Aksi'),
                                  ),
                                ],
                                rows: _filteredUsers.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final user = entry.value;
                                  final isLast =
                                      i == _filteredUsers.length - 1;

                                  return DataRow(
                                    cells: [
                                      // Nama
                                      DataCell(
                                        Text(
                                          user.namaLengkap,
                                          style: AppTextStyles.bodySemibold,
                                        ),
                                      ),
                                      // Email / NIM
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user.email,
                                              style: AppTextStyles.small,
                                            ),
                                            if (user.nim != null)
                                              Text(
                                                user.nim!,
                                                style: AppTextStyles.caption,
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Role
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.lightBlue,
                                            borderRadius:
                                                AppRadius.pill,
                                          ),
                                          child: Text(
                                            _getRoleLabel(user.role),
                                            style: AppTextStyles.smallSemibold
                                                .copyWith(
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Status
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(user.status)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                AppRadius.pill,
                                          ),
                                          child: Text(
                                            _getStatusLabel(user.status),
                                            style: AppTextStyles.smallSemibold
                                                .copyWith(
                                              color: _getStatusColor(
                                                  user.status),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bergabung
                                      DataCell(
                                        Text(
                                          _formatDate(user.createdAt),
                                          style: AppTextStyles.small,
                                        ),
                                      ),
                                      // Aksi
                                      DataCell(
                                        _isProcessing
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'status') {
                                                    _showChangeStatusDialog(
                                                        user);
                                                  } else if (value ==
                                                      'role') {
                                                    _showChangeRoleDialog(
                                                        user);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'status',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .toggle_on_outlined,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Ubah Status'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'role',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.badge_outlined,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Ubah Role'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.1) : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected ? chipColor : AppColors.borderGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color: isSelected ? chipColor : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}