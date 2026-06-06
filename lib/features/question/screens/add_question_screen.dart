// lib/features/question/screens/add_question_screen.dart
// Sprint 4 — Form Tambah Soal
// Terhubung ke QuestionController untuk save data real ke database.
// Kategori dimuat dari Hive/Database, bukan static list dummy.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banksos/features/question/controllers/question_controller.dart';
import 'package:banksos/data/local/hive/hive_service.dart';

// ─── Enum tipe jawaban ─────────────────────────────────────────────────────
enum AnswerType { pengaturan, pilihanGanda, isianSingkat }

// ─── Screen ───────────────────────────────────────────────────────────────────
class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  // Form state
  String? _kategori; // Diinisialisasi null sampai kategori dimuat
  String _difficulty = 'medium'; // 'easy' | 'medium' | 'hard'
  AnswerType _answerType = AnswerType.isianSingkat;
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingKategori = true;
  List<String> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  /// Load kategori dari Hive (local cache) atau MongoDB
  Future<void> _loadKategori() async {
    try {
      final hive = HiveService.instance.categoriesBox;
      final categories =
          hive.values.where((c) => c.isActive).map((c) => c.nama).toList();

      setState(() {
        _kategoriList = categories.isNotEmpty
            ? categories
            : [
                'Matematika Diskrit',
                'Struktur Data',
                'Elektronika Digital',
              ];
        _kategori = _kategoriList.first;
        _isLoadingKategori = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _kategoriList = [
            'Matematika Diskrit',
            'Struktur Data',
            'Elektronika Digital',
          ];
          _kategori = _kategoriList.first;
          _isLoadingKategori = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  // ─── Validate & Save ────────────────────────────────────────────────────
  Future<void> _simpan({bool asDraft = false}) async {
    if (_questionCtrl.text.trim().isEmpty) {
      _showSnackBar('Pertanyaan tidak boleh kosong.', isError: true);
      return;
    }
    if (_answerCtrl.text.trim().isEmpty && !asDraft) {
      _showSnackBar('Jawaban benar tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = context.read<QuestionController>();
      final result = await controller.tambahSoal(
        pertanyaan: _questionCtrl.text.trim(),
        jawaban: asDraft ? '' : _answerCtrl.text.trim(),
        kategoriNama: _kategori ?? 'Umum',
      );

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(
          asDraft ? 'Soal disimpan sebagai draf.' : 'Soal berhasil disimpan!',
        );
        Navigator.pop(context);
      } else {
        _showSnackBar(result.errorMessage ?? 'Gagal menyimpan soal.',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Soal',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827)),
        ),
        actions: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
                color: Color(0xFF1A6FDF), shape: BoxShape.circle),
            child: const Center(
              child: Text('R',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: _isLoadingKategori
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memuat kategori dari database...',
                      style: TextStyle(color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Kategori ──────────────────────────────────────────────────
                  _SectionLabel('Kategori Akademik'),
                  const SizedBox(height: 6),
                  _buildDropdown(),

                  const SizedBox(height: 14),

                  // ── Tingkat Kesulitan ──────────────────────────────────────────
                  _SectionLabel('Tingkat Kesulitan'),
                  const SizedBox(height: 6),
                  _buildDifficultyChips(),

                  const SizedBox(height: 14),

                  // ── Teks Soal ──────────────────────────────────────────────────
                  _SectionLabel('Teks Soal'),
                  const SizedBox(height: 6),
                  _buildFormatBar(),
                  TextField(
                    controller: _questionCtrl,
                    maxLines: 5,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Ketik pertanyaan di sini...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        borderSide: BorderSide(color: Color(0xFF1A6FDF)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Pengaturan Jawaban ─────────────────────────────────────────
                  _SectionLabel('Pengaturan Jawaban'),
                  const SizedBox(height: 6),
                  _buildAnswerTypeTabs(),

                  const SizedBox(height: 14),

                  // ── Jawaban Benar ──────────────────────────────────────────────
                  _SectionLabel('Jawaban Benar'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _answerCtrl,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jawaban benar...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF)),
                      suffixIcon: _answerCtrl.text.isNotEmpty
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF16A34A), size: 20)
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF1A6FDF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Sistem akan melakukan pencocokan teks secara tepat (case-sensitive) dengan input siswa.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF), height: 1.4),
                  ),

                  const SizedBox(height: 14),

                  // ── Gambar Referensi ───────────────────────────────────────────
                  _SectionLabel('Gambar Referensi'),
                  const SizedBox(height: 6),
                  _buildImageUpload(),

                  const SizedBox(height: 24),

                  // ── Buttons ────────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _simpan(),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Soal',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6FDF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => _simpan(asDraft: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A6FDF),
                        side: const BorderSide(color: Color(0xFF1A6FDF)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan sebagai Draf',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildDropdown() => _isLoadingKategori
      ? const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      : DropdownButtonFormField<String>(
          value: _kategori,
          items: _kategoriList
              .map((k) => DropdownMenuItem(
                  value: k,
                  child: Text(k, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) => setState(() => _kategori = v!),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF1A6FDF)),
            ),
          ),
        );

  Widget _buildDifficultyChips() => Row(
        children: [
          _DiffChip(
            label: 'Mudah',
            value: 'easy',
            selected: _difficulty == 'easy',
            activeColor: const Color(0xFF16A34A),
            activeBg: const Color(0xFFDCFCE7),
            onTap: () => setState(() => _difficulty = 'easy'),
          ),
          const SizedBox(width: 8),
          _DiffChip(
            label: 'Sedang',
            value: 'medium',
            selected: _difficulty == 'medium',
            activeColor: const Color(0xFFD97706),
            activeBg: const Color(0xFFFEF3C7),
            onTap: () => setState(() => _difficulty = 'medium'),
          ),
          const SizedBox(width: 8),
          _DiffChip(
            label: 'Sulit',
            value: 'hard',
            selected: _difficulty == 'hard',
            activeColor: const Color(0xFFDC2626),
            activeBg: const Color(0xFFFEE2E2),
            onTap: () => setState(() => _difficulty = 'hard'),
          ),
        ],
      );

  Widget _buildFormatBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB)),
            left: BorderSide(color: Color(0xFFE5E7EB)),
            right: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
        child: Row(
          children: [
            _FmtBtn(label: 'B', bold: true, onTap: () {}),
            _FmtBtn(label: 'I', italic: true, onTap: () {}),
            _FmtBtn(label: 'U', underline: true, onTap: () {}),
            const SizedBox(width: 4),
            _FmtIconBtn(icon: Icons.format_list_bulleted, onTap: () {}),
            _FmtIconBtn(icon: Icons.functions, onTap: () {}),
            _FmtIconBtn(icon: Icons.link, onTap: () {}),
          ],
        ),
      );

  Widget _buildAnswerTypeTabs() => Row(
        children: AnswerType.values.map((t) {
          final labels = [
            'Pengaturan Jawaban',
            'Pilihan Ganda',
            'Isian Singkat'
          ];
          final idx = t.index;
          final active = _answerType == t;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _answerType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1A6FDF) : Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.horizontal(
                    left: idx == 0 ? const Radius.circular(6) : Radius.zero,
                    right: idx == 2 ? const Radius.circular(6) : Radius.zero,
                  ),
                ),
                child: Text(
                  labels[idx],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildImageUpload() => InkWell(
        onTap: () {
          _showSnackBar('Fitur unggah gambar segera hadir.');
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: const [
              Icon(Icons.image_outlined, size: 32, color: Color(0xFF9CA3AF)),
              SizedBox(height: 8),
              Text(
                'Klik untuk unggah atau seret gambar ke sini',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2),
              Text(
                'PNG, JPG (Max 5MB)',
                style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
              ),
            ],
          ),
        ),
      );
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827)),
      );
}

class _DiffChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final Color activeColor, activeBg;
  final VoidCallback onTap;

  const _DiffChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? activeBg : Colors.white,
              border: Border.all(
                  color: selected ? activeColor : const Color(0xFFE5E7EB),
                  width: selected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      );
}

class _FmtBtn extends StatelessWidget {
  final String label;
  final bool bold, italic, underline;
  final VoidCallback onTap;

  const _FmtBtn({
    required this.label,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              decoration: underline ? TextDecoration.underline : null,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      );
}

class _FmtIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FmtIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF374151)),
        ),
      );
}
