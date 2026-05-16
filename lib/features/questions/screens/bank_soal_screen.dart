// lib/features/questions/screens/bank_soal_screen.dart
// PIC: Seruni (SL) — Sprint 2
// Senin  : Halaman bank soal, sidebar kategori toggle-able, card soal, badge kesulitan
// Selasa : Chip filter tingkat kesulitan (Semua / Easy / Medium / Hard)
// Rabu   : Tombol "Unduh untuk Offline" + progress indicator

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart'; 
import '../../../shared/widgets/app_widgets.dart'; 

import '../../../core/services/connectivity_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../features/auth/data/category_remote.dart';
import '../../../features/auth/data/question_remote.dart';

// ─── Provider: Daftar kategori ────────────────────────────────────────────────
// Offline-first: coba Hive dulu, jika kosong ambil dari server.
final categoryProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final hive = HiveService.instance.categoriesBox;

  // Coba ambil dari Hive dulu
  if (hive.isNotEmpty) {
    return hive.values.where((c) => c.isActive).toList();
  }

  // Jika Hive kosong, ambil dari server
  final isOnline = await ConnectivityService.instance.isOnline;
  if (!isOnline) return [];

  final rawList = await CategoryRemote().getActiveCategories();
  final categories =
      rawList.map((m) => CategoryModel.fromMap(m)).toList();

  // Simpan ke Hive untuk akses offline berikutnya
  for (final cat in categories) {
    await hive.put(cat.id, cat);
  }

  return categories;
});

// ─── Provider: Soal berdasarkan kategori yang dipilih ────────────────────────
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final questionProvider =
    FutureProvider.autoDispose<List<QuestionModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final hive = HiveService.instance.questionsBox;

  List<QuestionModel> all = hive.values.toList();

  // Jika belum ada soal di Hive, coba fetch dari server
  if (all.isEmpty && categoryId != null) {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (isOnline) {
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);
      final fetched =
          rawList.map((m) => QuestionModel.fromMap(m)).toList();
      for (final q in fetched) {
        await hive.put(q.id, q);
      }
      all = fetched;
    }
  }

  // Filter berdasarkan kategori yang dipilih
  if (categoryId != null) {
    all = all
        .where((q) =>
            q.kategoriId == categoryId &&
            q.status == QuestionStatus.published)
        .toList();
  } else {
    all = all.where((q) => q.status == QuestionStatus.published).toList();
  }

  return all;
});

// ─── Provider: Status online/offline ─────────────────────────────────────────
final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return ConnectivityService.instance.onConnectivityChanged;
});

// ─── Screen Utama ─────────────────────────────────────────────────────────────
class BankSoalScreen extends ConsumerStatefulWidget {
  const BankSoalScreen({super.key});

  @override
  ConsumerState<BankSoalScreen> createState() => _BankSoalScreenState();
}

class _BankSoalScreenState extends ConsumerState<BankSoalScreen> {
  // Sidebar toggle
  bool _isSidebarOpen = true;

  // Filter kesulitan — null = semua
  DifficultyLevel? _selectedDifficulty;

  // Search
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // State unduh
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _downloadStatus = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Proses unduh soal untuk offline ───────────────────────────────────────
  Future<void> _downloadForOffline(String categoryId, String categoryName) async {
    final isOnline = await ConnectivityService.instance.isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada koneksi internet. Unduh gagal.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = 'Mengambil soal $categoryName...';
    });

    try {
      // Step 1: Fetch dari server
      setState(() => _downloadProgress = 0.3);
      final rawList = await QuestionRemote()
          .getPublishedQuestionsByCategory(categoryId);

      setState(() {
        _downloadProgress = 0.6;
        _downloadStatus = 'Menyimpan ${rawList.length} soal...';
      });

      // Step 2: Simpan ke Hive
      final hive = HiveService.instance.questionsBox;
      for (final raw in rawList) {
        final question = QuestionModel.fromMap(raw);
        await hive.put(question.id, question);
      }

      setState(() => _downloadProgress = 1.0);

      // Refresh tampilan soal
      ref.invalidate(questionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${rawList.length} soal $categoryName berhasil diunduh untuk offline.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
          _downloadStatus = '';
        });
      }
    }
  }

  // ─── Filter soal berdasarkan kesulitan & search ──────────────────────────
  List<QuestionModel> _applyFilters(List<QuestionModel> questions) {
    var filtered = questions;

    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((q) => q.tingkatKesulitan == _selectedDifficulty)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((q) => q.pertanyaan
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final questionsAsync = ref.watch(questionProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    // Deteksi offline
    final isOffline = connectivityAsync.when(
      data: (results) =>
          results.contains(ConnectivityResult.none) || results.isEmpty,
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Soal'),
        leading: IconButton(
          icon: Icon(
            _isSidebarOpen
                ? Icons.menu_open_outlined
                : Icons.menu_outlined,
          ),
          tooltip: _isSidebarOpen ? 'Tutup Kategori' : 'Buka Kategori',
          onPressed: () =>
              setState(() => _isSidebarOpen = !_isSidebarOpen),
        ),
        actions: [
          // Tombol Unduh untuk Offline
          if (selectedCategoryId != null)
            categoriesAsync.when(
              data: (categories) {
                final selected = categories
                    .where((c) => c.id == selectedCategoryId)
                    .toList();
                final categoryName =
                    selected.isNotEmpty ? selected.first.nama : 'Soal';
                return IconButton(
                  icon: _isDownloading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: _downloadProgress,
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_outlined),
                  tooltip: 'Unduh untuk Offline',
                  onPressed: _isDownloading
                      ? null
                      : () => _downloadForOffline(
                            selectedCategoryId,
                            categoryName,
                          ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner Offline ──────────────────────────────────────────────
          if (isOffline)
            Container(
              width: double.infinity,
              color: AppTheme.warningYellow.withOpacity(0.15),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_outlined,
                      size: 16, color: AppTheme.warningYellow),
                  const SizedBox(width: 8),
                  const Text(
                    'Mode Offline — Menampilkan soal tersimpan',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.warningYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── Progress Bar Unduh ──────────────────────────────────────────
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppTheme.lightBlue,
              color: AppTheme.primaryBlue,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _downloadStatus,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textGrey),
                  ),
                  const Spacer(),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          // ── Konten Utama: Sidebar + Daftar Soal ────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sidebar Kategori (toggle-able) ──────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarOpen ? 150 : 0,
                  child: _isSidebarOpen
                      ? _buildSidebar(categoriesAsync, selectedCategoryId)
                      : const SizedBox.shrink(),
                ),

                // ── Divider antara sidebar dan konten ───────────────────
                if (_isSidebarOpen)
                  const VerticalDivider(width: 1, thickness: 1),

                // ── Kolom Kanan: Filter + Daftar Soal ──────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari soal...',
                            isDense: true,
                            prefixIcon: const Icon(Icons.search_outlined,
                                size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
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

                      // Filter Chip Kesulitan (TASK SELASA)
                      _buildFilterChips(),

                      const Divider(height: 1),

                      // Daftar Soal
                      Expanded(
                        child: questionsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => _buildError(e.toString()),
                          data: (questions) {
                            final filtered = _applyFilters(questions);
                            if (filtered.isEmpty) {
                              return _buildEmpty(selectedCategoryId);
                            }
                            return _buildQuestionList(filtered);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar Kategori ─────────────────────────────────────────────────────
  Widget _buildSidebar(
    AsyncValue<List<CategoryModel>> categoriesAsync,
    String? selectedCategoryId,
  ) {
    return Container(
      color: AppTheme.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              'Mata Kuliah',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Item "Semua"
          _buildCategoryItem(
            id: null,
            label: 'Semua',
            icon: Icons.grid_view_outlined,
            isSelected: selectedCategoryId == null,
          ),
          const Divider(height: 8, indent: 12, endIndent: 12),
          // Daftar kategori dari server/hive
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Gagal memuat kategori',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.errorRed),
                ),
              ),
              data: (categories) => ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  return _buildCategoryItem(
                    id: cat.id,
                    label: cat.nama,
                    icon: Icons.book_outlined,
                    isSelected: selectedCategoryId == cat.id,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String? id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(selectedCategoryIdProvider.notifier).state = id;
        // Reset filter saat ganti kategori
        setState(() {
          _selectedDifficulty = null;
          _searchCtrl.clear();
          _searchQuery = '';
        });
        ref.invalidate(questionProvider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.08)
              : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips Kesulitan (TASK SELASA) ─────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildChip(label: 'Semua', difficulty: null),
          const SizedBox(width: 6),
          _buildChip(label: 'Mudah', difficulty: DifficultyLevel.easy),
          const SizedBox(width: 6),
          _buildChip(label: 'Sedang', difficulty: DifficultyLevel.medium),
          const SizedBox(width: 6),
          _buildChip(label: 'Sulit', difficulty: DifficultyLevel.hard),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required DifficultyLevel? difficulty,
  }) {
    final isSelected = _selectedDifficulty == difficulty;

    Color chipColor = AppTheme.primaryBlue;
    if (difficulty == DifficultyLevel.easy) chipColor = AppTheme.easyGreen;
    if (difficulty == DifficultyLevel.medium) chipColor = AppTheme.mediumYellow;
    if (difficulty == DifficultyLevel.hard) chipColor = AppTheme.hardRed;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          setState(() => _selectedDifficulty = difficulty),
      selectedColor: chipColor.withOpacity(0.15),
      checkmarkColor: chipColor,
      side: BorderSide(
        color: isSelected ? chipColor : AppTheme.borderGrey,
        width: isSelected ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? chipColor : AppTheme.textGrey,
        fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  // ─── Daftar Soal ─────────────────────────────────────────────────────────
  Widget _buildQuestionList(List<QuestionModel> questions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _QuestionCard(
          question: questions[index],
          nomor: index + 1,
        );
      },
    );
  }

  // ─── Empty & Error State ──────────────────────────────────────────────────
  Widget _buildEmpty(String? categoryId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            categoryId == null
                ? Icons.menu_book_outlined
                : Icons.inbox_outlined,
            size: 56,
            color: AppTheme.textGrey.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Soal tidak ditemukan'
                : categoryId == null
                    ? 'Pilih mata kuliah di sidebar'
                    : 'Belum ada soal.\nCoba unduh terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Hapus pencarian'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Soal ────────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int nomor;

  const _QuestionCard({required this.question, required this.nomor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Sprint 2 Kamis — Revaldi yang handle KerjakanSoalScreen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur kerjakan soal dalam pengerjaan...'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: nomor + badge kesulitan + bookmark
              Row(
                children: [
                  // Nomor soal
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$nomor',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge kesulitan (TASK SENIN)
                  _DifficultyBadge(level: question.tingkatKesulitan),

                  const Spacer(),

                  // Ikon hint
                  if (question.hints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 14, color: AppTheme.warningYellow),
                          const SizedBox(width: 2),
                          Text(
                            '${question.hints.length}',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),

                  // Ikon bookmark placeholder (Sprint 3 — Seruni Selasa)
                  Icon(
                    Icons.bookmark_border_outlined,
                    size: 18,
                    color: AppTheme.textGrey.withOpacity(0.5),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Pertanyaan
              Text(
                question.pertanyaan,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Placeholder jawaban: _____ _____
              Text(
                _buildPlaceholder(question.jawaban),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              // Mata kuliah + kategori
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 13, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    question.kategoriNama,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Buat placeholder seperti: _____ _____
  /// Sesuai spesifikasi BANKSOS: panjang underscore = panjang kata jawaban.
  String _buildPlaceholder(String answer) {
    return answer
        .trim()
        .split(' ')
        .map((word) => '_' * word.length)
        .join(' ');
  }
}

// ─── Badge Kesulitan ──────────────────────────────────────────────────────────
class _DifficultyBadge extends StatelessWidget {
  final DifficultyLevel level;
  const _DifficultyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (level) {
      case DifficultyLevel.easy:
        color = AppTheme.easyGreen;
        label = 'Mudah';
        break;
      case DifficultyLevel.medium:
        color = AppTheme.mediumYellow;
        label = 'Sedang';
        break;
      case DifficultyLevel.hard:
        color = AppTheme.hardRed;
        label = 'Sulit';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}