// lib/features/submit/screens/submit_soal_screen.dart
// Sprint 4 — Seruni: Form Submit Soal
// Task: textarea pertanyaan, input jawaban (preview lowercase),
//       dropdown kategori, tambah hint dinamis, validasi semua field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class SubmitSoalScreen extends ConsumerStatefulWidget {
  const SubmitSoalScreen({super.key});

  @override
  ConsumerState<SubmitSoalScreen> createState() => _SubmitSoalScreenState();
}

class _SubmitSoalScreenState extends ConsumerState<SubmitSoalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _pertanyaanCtrl = TextEditingController();
  final _jawabanCtrl = TextEditingController();

  // State
  String _jawabanPreview = '';
  CategoryModel? _selectedKategori;
  List<CategoryModel> _kategoriList = [];
  final List<TextEditingController> _hintControllers = [];
  bool _isLoading = false;
  bool _isLoadingKategori = true;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _jawabanCtrl.addListener(() {
      setState(() {
        _jawabanPreview = _jawabanCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _jawabanCtrl.dispose();
    for (final c in _hintControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Load Kategori dari Hive atau MongoDB ─────────────────────────────────

  Future<void> _loadKategori() async {
    setState(() => _isLoadingKategori = true);

    // Coba dari Hive dulu
    final hiveBox = HiveService.instance.categoriesBox;
    if (hiveBox.isNotEmpty) {
      setState(() {
        _kategoriList = hiveBox.values.where((c) => c.isActive).toList();
        _isLoadingKategori = false;
      });
      return;
    }

    // Kalau Hive kosong, fetch dari MongoDB
    try {
      final isOnline = await ConnectivityService.instance.isOnline;
      if (!isOnline) {
        setState(() => _isLoadingKategori = false);
        return;
      }

      final db = MongoDBService.instance;
      if (!db.isConnected) {
        setState(() => _isLoadingKategori = false);
        return;
      }

      final raw = await db.categories
          .find({'is_active': true})
          .toList();

      final categories = raw.map((m) => CategoryModel.fromMap(m)).toList();

      // Simpan ke Hive
      for (final cat in categories) {
        await hiveBox.put(cat.id, cat);
      }

      setState(() {
        _kategoriList = categories;
        _isLoadingKategori = false;
      });
    } catch (e) {
      setState(() => _isLoadingKategori = false);
    }
  }

  // ─── Tambah / Hapus Hint ──────────────────────────────────────────────────

  void _tambahHint() {
    if (_hintControllers.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 hint per soal'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _hintControllers.add(TextEditingController());
    });
  }

  void _hapusHint(int index) {
    setState(() {
      _hintControllers[index].dispose();
      _hintControllers.removeAt(index);
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih mata kuliah terlebih dahulu'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Wajib online untuk submit
    final isOnline = await ConnectivityService.instance.isOnline;
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan soal membutuhkan koneksi internet'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SessionService.instance.userId ?? '';
      final db = MongoDBService.instance;

      if (!db.isConnected) {
        throw Exception('Tidak dapat terhubung ke server');
      }

      final hints = _hintControllers
          .map((c) => c.text.trim())
          .where((h) => h.isNotEmpty)
          .toList();

      final now = DateTime.now().toIso8601String();

      // Strip format ObjectId("...") sebelum parse
      String toHex(String raw) {
        final m = RegExp(r'''ObjectId\(["\']?([0-9a-fA-F]{24})["\']?\)''',
                caseSensitive: false)
            .firstMatch(raw);
        if (m != null) return m.group(1)!;
        if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(raw)) return raw;
        final any = RegExp(r'([0-9a-fA-F]{24})').firstMatch(raw);
        return any != null ? any.group(1)! : raw;
      }

      final doc = {
        '_id': ObjectId(),
        'pertanyaan': _pertanyaanCtrl.text.trim(),
        'jawaban': _jawabanCtrl.text.trim().toLowerCase(),
        'kategori_id': ObjectId.parse(toHex(_selectedKategori!.id)),
        'kategori_nama': _selectedKategori!.nama,
        'tingkat_kesulitan': 'easy', // akan diset reviewer saat approve
        'status': 'pending',
        'hints': hints,
        'submitted_by': ObjectId.parse(toHex(userId)),
        'reviewed_by': null,
        'rejection_reason': null,
        'solve_count': 0,
        'created_at': now,
        'updated_at': now,
      };

      final result = await db.questions.insertOne(doc);

      if (!result.isSuccess) {
        throw Exception('Gagal mengirim soal ke server');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil diajukan! Menunggu review.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // true = ada soal baru
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Ajukan Soal Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacings.pagePadding,
          children: [
            // ── Info Banner ─────────────────────────────────────────────
            const AppMessageBanner(
              type: BannerType.info,
              message:
                  'Soal yang kamu ajukan akan direview oleh tim reviewer sebelum dipublikasikan.',
            ),

            const SizedBox(height: AppSpacings.xxl),

            // ── Mata Kuliah / Kategori ──────────────────────────────────
            _buildLabel('Mata Kuliah', isRequired: true),
            const SizedBox(height: AppSpacings.xs),
            _buildKategoriDropdown(),

            const SizedBox(height: AppSpacings.lg),

            // ── Pertanyaan ──────────────────────────────────────────────
            _buildLabel('Pertanyaan', isRequired: true),
            const SizedBox(height: AppSpacings.xs),
            TextFormField(
              controller: _pertanyaanCtrl,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Tulis pertanyaan soal di sini...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pertanyaan tidak boleh kosong';
                }
                if (value.trim().length < 10) {
                  return 'Pertanyaan terlalu singkat (min. 10 karakter)';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacings.lg),

            // ── Jawaban ─────────────────────────────────────────────────
            _buildLabel('Jawaban', isRequired: true),
            const SizedBox(height: AppSpacings.xs),
            TextFormField(
              controller: _jawabanCtrl,
              style: AppTextStyles.body,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Tulis jawaban singkat (akan otomatis lowercase)',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.textGrey,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jawaban tidak boleh kosong';
                }
                return null;
              },
            ),

            // Preview jawaban lowercase
            if (_jawabanPreview.isNotEmpty) ...[
              const SizedBox(height: AppSpacings.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.bgBlue,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Preview: ',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryBlue),
                    ),
                    Expanded(
                      child: Text(
                        _jawabanPreview,
                        style: AppTextStyles.smallSemibold.copyWith(
                          color: AppColors.primaryBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacings.lg),

            // ── Hints (opsional, dinamis) ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Hints', isRequired: false),
                TextButton.icon(
                  onPressed: _tambahHint,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Tambah Hint'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    textStyle: AppTextStyles.small
                        .copyWith(fontWeight: FontWeight.w600),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            if (_hintControllers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacings.xs, bottom: AppSpacings.xs),
                child: Text(
                  'Opsional — tambahkan petunjuk untuk membantu mahasiswa.',
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.textGrey),
                ),
              ),

            ...List.generate(_hintControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacings.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 12, right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.captionBold
                            .copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _hintControllers[index],
                        style: AppTextStyles.body,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Tulis hint ${index + 1}...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _hapusHint(index),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.errorRed, size: 20),
                      tooltip: 'Hapus hint',
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacings.xxxl),

            // ── Tombol Submit ────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _onSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Kirim untuk Direview'),
            ),

            const SizedBox(height: AppSpacings.lg),
          ],
        ),
      ),
    );
  }

  // ─── Widget Helpers ───────────────────────────────────────────────────────

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: AppTextStyles.small.copyWith(color: AppColors.errorRed),
          ),
      ],
    );
  }

  Widget _buildKategoriDropdown() {
    if (_isLoadingKategori) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.borderGrey),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_kategoriList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacings.md),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                color: AppColors.warningYellow, size: 16),
            const SizedBox(width: 8),
            Text(
              'Kategori tidak tersedia — butuh koneksi internet',
              style: AppTextStyles.small
                  .copyWith(color: AppColors.warningYellow),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CategoryModel>(
      initialValue: _selectedKategori,
      decoration: const InputDecoration(
        hintText: 'Pilih mata kuliah',
        prefixIcon: Icon(
          Icons.folder_outlined,
          color: AppColors.textGrey,
          size: 20,
        ),
      ),
      style: AppTextStyles.body.copyWith(color: AppColors.textDark),
      dropdownColor: AppColors.bgWhite,
      icon: const Icon(Icons.expand_more, color: AppColors.textGrey),
      isExpanded: true,
      items: _kategoriList.map((cat) {
        return DropdownMenuItem<CategoryModel>(
          value: cat,
          child: Text(cat.nama, style: AppTextStyles.body),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedKategori = val),
      validator: (val) {
        if (val == null) return 'Pilih mata kuliah';
        return null;
      },
    );
  }
}