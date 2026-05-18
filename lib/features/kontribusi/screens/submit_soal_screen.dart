import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class SubmitSoalScreen extends StatefulWidget {
  const SubmitSoalScreen({super.key});

  @override
  State<SubmitSoalScreen> createState() => _SubmitSoalScreenState();
}

class _SubmitSoalScreenState extends State<SubmitSoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pertanyaanCtrl = TextEditingController();
  final _jawabanCtrl = TextEditingController();
  
  String? _selectedKategori;
  String _jawabanPreview = '';
  final List<TextEditingController> _hintControllers = [];

  final List<String> _kategoriDummy = ['Pemrograman Web', 'Struktur Data', 'Jaringan Komputer'];

  void _addHint() {
    setState(() {
      _hintControllers.add(TextEditingController());
    });
  }

  void _removeHint(int index) {
    setState(() {
      _hintControllers[index].dispose();
      _hintControllers.removeAt(index);
    });
  }

  void _submitSoal() {
    if (_formKey.currentState!.validate()) {
      // TODO: Handle post data ke question_submit_repository
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soal berhasil diajukan dan menunggu review!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _jawabanCtrl.dispose();
    for (var ctrl in _hintControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Soal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacings.pagePadding,
          children: [
            const AppMessageBanner(
              type: BannerType.info,
              message: 'Soal yang diajukan akan melalui tahap review sebelum dipublish.',
            ),
            const SizedBox(height: AppSpacings.xl),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kategori'),
              value: _selectedKategori,
              items: _kategoriDummy.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedKategori = val),
              validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
            ),
            const SizedBox(height: AppSpacings.lg),

            TextFormField(
              controller: _pertanyaanCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Pertanyaan', alignLabelWithHint: true),
              validator: (val) => val == null || val.isEmpty ? 'Pertanyaan wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacings.lg),

            TextFormField(
              controller: _jawabanCtrl,
              decoration: const InputDecoration(labelText: 'Jawaban Benar'),
              onChanged: (val) {
                setState(() {
                  _jawabanPreview = val.toLowerCase();
                });
              },
              validator: (val) => val == null || val.isEmpty ? 'Jawaban wajib diisi' : null,
            ),
            if (_jawabanPreview.isNotEmpty) ...[
              const SizedBox(height: AppSpacings.sm),
              Text('Sistem akan mengecek: "$_jawabanPreview"', style: AppTextStyles.caption),
            ],
            const SizedBox(height: AppSpacings.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hints (Opsional)', style: AppTextStyles.h2),
                TextButton.icon(
                  onPressed: _addHint,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Hint'),
                )
              ],
            ),
            ...List.generate(_hintControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacings.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hintControllers[index],
                        decoration: InputDecoration(labelText: 'Hint ${index + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                      onPressed: () => _removeHint(index),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacings.xxl),

            ElevatedButton(
              onPressed: _submitSoal,
              child: const Text('Kirim Soal'),
            )
          ],
        ),
      ),
    );
  }
}