// lib/features/admin/screens/admin_question_management_screen.dart
// Sprint 5 — Seruni (SL): Admin Kelola Soal
//
// Fitur:
//   - Tabel soal dengan kolom: No, Pertanyaan, Kategori, Tingkat, Status, Aksi
//   - Filter: Status (Semua/Published/Pending/Rejected/Archived)
//   - Filter: Kategori
//   - Filter: Kesulitan
//   - Tombol aksi per baris: Arsipkan, Nonaktifkan, Aktifkan Kembali
//   - Statistik di header: Total Aktif vs Arsip
//   - Dialog konfirmasi sebelum aksi

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where, modify;

import '../../../core/theme/app_theme.dart';
import '../../../core/guard/rbac_guard.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../../shared/widgets/app_widgets.dart';

// ─── Enum Filter ──────────────────────────────────────────────────────────────

enum QuestionStatusFilter { all, published, pending, rejected, archived }

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminQuestionManagementScreen extends StatefulWidget {
  const AdminQuestionManagementScreen({super.key});

  @override
  State<AdminQuestionManagementScreen> createState() =>
      _AdminQuestionManagementScreenState();
}

class _AdminQuestionManagementScreenState
    extends State<AdminQuestionManagementScreen> {
  final MongoDBService _db = MongoDBService.instance;
  final HiveService _hive = HiveService.instance;

  List<QuestionModel> _allQuestions = [];
  List<QuestionModel> _filteredQuestions = [];
  List<CategoryModel> _categories = [];

  QuestionStatusFilter _statusFilter = QuestionStatusFilter.all;
  String? _categoryIdFilter;
  DifficultyFilter _difficultyFilter = DifficultyFilter.all;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  int _totalActive = 0;
  int _totalArchived = 0;

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
        _loadData();
      } catch (e) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ─── Load Data dari MongoDB ───────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isOnline = await ConnectivityService.instance.checkNow();

    try {
      if (!isOnline || !_db.isConnected) {
        setState(() {
          _errorMessage =
              'Halaman kelola soal membutuhkan koneksi internet.';
          _isLoading = false;
        });
        return;
      }

      // Load soal
      final rawQuestions = await _db.questions.find({}).toList();
      final questions = rawQuestions
          .map((map) => QuestionModel.fromMap(map))
          .toList();

      // Load kategori
      final rawCategories = await _db.categories.find({}).toList();
      final categories = rawCategories
          .map((map) => CategoryModel.fromMap(map))
          .toList();

      // Hitung statistik
      final totalActive = questions
          .where((q) => q.status == QuestionStatus.published)
          .length;
      final totalArchived = questions
          .where((q) => q.status == QuestionStatus.archived)
          .length;

      setState(() {
        _allQuestions = questions;
        _categories = categories;
        _totalActive = totalActive;
        _totalArchived = totalArchived;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat data soal: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  // ─── Apply Filters ────────────────────────────────────────────────────────

  void _applyFilters() {
    _filteredQuestions = _allQuestions.where((question) {
      // Filter status
      if (_statusFilter != QuestionStatusFilter.all) {
        final statusMap = {
          QuestionStatusFilter.published: QuestionStatus.published,
          QuestionStatusFilter.pending: QuestionStatus.pending,
          QuestionStatusFilter.rejected: QuestionStatus.rejected,
          QuestionStatusFilter.archived: QuestionStatus.archived,
        };
        if (question.status != statusMap[_statusFilter]) return false;
      }

      // Filter kategori
      if (_categoryIdFilter != null) {
        if (question.kategoriId != _categoryIdFilter) return false;
      }

      // Filter kesulitan
      if (_difficultyFilter != DifficultyFilter.all) {
        final diffMap = {
          DifficultyFilter.easy: DifficultyLevel.easy,
          DifficultyFilter.medium: DifficultyLevel.medium,
          DifficultyFilter.hard: DifficultyLevel.hard,
        };
        if (question.tingkatKesulitan != diffMap[_difficultyFilter]) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ─── Update Question Status ───────────────────────────────────────────────

  Future<void> _updateQuestionStatus(
    QuestionModel question,
    QuestionStatus newStatus,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline || !_db.isConnected) {
        throw Exception('Koneksi internet diperlukan untuk mengubah soal.');
      }

      await _db.questions.updateOne(
        where.id(ObjectId.parse(question.id)),
        modify.set('status', newStatus.name),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Soal berhasil diubah menjadi ${newStatus.name.toUpperCase()}.',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
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

  // ─── Dialog: Konfirmasi Aksi ──────────────────────────────────────────────

  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    Color? buttonColor,
  }) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTextStyles.h2),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor ?? AppColors.primaryBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  // ─── Format String ────────────────────────────────────────────────────────

  String _getDifficultyLabel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 'Mudah';
      case DifficultyLevel.medium:
        return 'Sedang';
      case DifficultyLevel.hard:
        return 'Sulit';
    }
  }

  String _getStatusLabel(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return 'Pending';
      case QuestionStatus.published:
        return 'Dipublikasikan';
      case QuestionStatus.rejected:
        return 'Ditolak';
      case QuestionStatus.archived:
        return 'Diarsipkan';
      case QuestionStatus.inactive:
        return 'Nonaktif';
      case QuestionStatus.revisionRequired:
        return 'Revisi Diperlukan';
    }
  }

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return AppColors.warningYellow;
      case QuestionStatus.published:
        return AppColors.successGreen;
      case QuestionStatus.rejected:
        return AppColors.errorRed;
      case QuestionStatus.archived:
      case QuestionStatus.inactive:
        return AppColors.textGrey;
      case QuestionStatus.revisionRequired:
        return AppColors.warningYellow;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Kelola Soal'),
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
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Statistik Header ───────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Aktif',
                                  style: AppTextStyles.small
                                      .copyWith(color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalActive Soal',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.borderGrey,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Diarsipkan',
                                  style: AppTextStyles.small
                                      .copyWith(color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalArchived Soal',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Filter Bar ─────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Status filter
                          _buildStatusFilterChip('Semua',
                              QuestionStatusFilter.all),
                          const SizedBox(width: 6),
                          _buildStatusFilterChip(
                              'Dipublikasikan', QuestionStatusFilter.published),
                          const SizedBox(width: 6),
                          _buildStatusFilterChip(
                              'Pending', QuestionStatusFilter.pending),
                          const SizedBox(width: 6),
                          _buildStatusFilterChip(
                              'Ditolak', QuestionStatusFilter.rejected),
                          const SizedBox(width: 6),
                          _buildStatusFilterChip(
                              'Diarsipkan', QuestionStatusFilter.archived),
                          const SizedBox(width: 16),
                          // Kategori filter
                          _buildCategoryFilterChip(null, 'Semua Kategori'),
                          ..._categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildCategoryFilterChip(
                                  cat.id, cat.nama),
                            );
                          }),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ── Tabel Soal ────────────────────────────────────
                    Expanded(
                      child: _filteredQuestions.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.quiz_outlined,
                              title: 'Tidak ada soal',
                              subtitle:
                                  'Coba ubah filter atau refresh halaman.',
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 12,
                                horizontalMargin: 16,
                                headingRowColor: MaterialStateColor.resolveWith(
                                  (_) => AppColors.bgWhite,
                                ),
                                columns: const [
                                  DataColumn(label: Text('No')),
                                  DataColumn(label: Text('Pertanyaan')),
                                  DataColumn(label: Text('Kategori')),
                                  DataColumn(label: Text('Tingkat')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Aksi')),
                                ],
                                rows: _filteredQuestions
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final i = entry.key;
                                  final question = entry.value;

                                  return DataRow(
                                    cells: [
                                      // No
                                      DataCell(
                                        Text(
                                          '${i + 1}',
                                          style: AppTextStyles.bodySemibold,
                                        ),
                                      ),
                                      // Pertanyaan
                                      DataCell(
                                        SizedBox(
                                          width: 250,
                                          child: Text(
                                            question.pertanyaan,
                                            style: AppTextStyles.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Kategori
                                      DataCell(
                                        Text(
                                          question.kategoriNama,
                                          style: AppTextStyles.small,
                                        ),
                                      ),
                                      // Tingkat Kesulitan
                                      DataCell(
                                        AppBadge.difficulty(
                                          question.tingkatKesulitan.name,
                                        ),
                                      ),
                                      // Status
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    question.status)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                AppRadius.pill,
                                          ),
                                          child: Text(
                                            _getStatusLabel(question.status),
                                            style: AppTextStyles.smallSemibold
                                                .copyWith(
                                              color: _getStatusColor(
                                                  question.status),
                                            ),
                                          ),
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
                                                  if (value == 'archive') {
                                                    _showConfirmDialog(
                                                      title: 'Arsipkan Soal',
                                                      message:
                                                          'Soal ini akan dipindahkan ke arsip dan tidak tampil di bank soal.',
                                                      buttonColor:
                                                          AppColors.warningYellow,
                                                      onConfirm: () =>
                                                          _updateQuestionStatus(
                                                        question,
                                                        QuestionStatus.archived,
                                                      ),
                                                    );
                                                  } else if (value ==
                                                      'inactive') {
                                                    _showConfirmDialog(
                                                      title: 'Nonaktifkan Soal',
                                                      message:
                                                          'Soal ini akan dinonaktifkan dan tidak dapat diakses oleh pengguna.',
                                                      buttonColor:
                                                          AppColors.errorRed,
                                                      onConfirm: () =>
                                                          _updateQuestionStatus(
                                                        question,
                                                        QuestionStatus.inactive,
                                                      ),
                                                    );
                                                  } else if (value ==
                                                      'activate') {
                                                    _showConfirmDialog(
                                                      title: 'Aktifkan Soal',
                                                      message:
                                                          'Soal ini akan diaktifkan kembali.',
                                                      onConfirm: () =>
                                                          _updateQuestionStatus(
                                                        question,
                                                        QuestionStatus.published,
                                                      ),
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) {
                                                  final items = 
                                                      <PopupMenuEntry<String>>[];

                                                  if (question.status !=
                                                      QuestionStatus
                                                          .archived) {
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'archive',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .archive_outlined,
                                                              size: 18,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text('Arsipkan'),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  if (question.status !=
                                                      QuestionStatus
                                                          .inactive) {
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'inactive',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .pause_circle_outline,
                                                              size: 18,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text('Nonaktifkan'),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  if (question.status ==
                                                          QuestionStatus
                                                              .archived ||
                                                      question.status ==
                                                          QuestionStatus
                                                              .inactive) {
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'activate',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .play_circle_outline,
                                                              size: 18,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text('Aktifkan'),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  return items;
                                                },
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

  Widget _buildStatusFilterChip(
    String label,
    QuestionStatusFilter filter,
  ) {
    final isSelected = _statusFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = filter;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1)
              : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.borderGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String? categoryId, String label) {
    final isSelected = _categoryIdFilter == categoryId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoryIdFilter = categoryId;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1)
              : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.borderGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}