// lib/features/question/screens/question_detail_screen.dart
// Sprint 6 UPDATE — Revaldi (RP): Integrasi AnswerAnimationController
// Update: Label Kesulitan & Bookmark dipindahkan ke dalam kartu pertanyaan sesuai mockup

import 'package:banksos/features/question/repositories/bookmark_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Tambahan untuk UI Reactive

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../data/models/question_model.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../repositories/progress_repository.dart';
import '../services/answer_animation_service.dart';
import '../services/hint_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;
  final IProgressRepository? progressRepository;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.progressRepository,
  });
  
  get bookmarkRepository => null;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();

  // ─── State 
  late final HintService _hintService;
  bool _isCorrect = false;
  bool _hasSubmitted = false;
  bool _isSavingProgress = false;

  // ─── Sprint 3: Bookmark 
  bool _isBookmarked = false;
  bool _isTogglingBookmark = false;
  late final BookmarkRepository _bookmarkRepository;
  late final IProgressRepository _progressRepository;

  // ─── Sprint 6: Animasi (Revaldi) 
  late final AnswerAnimationController _animCtrl;

  @override
  void initState() {
    super.initState();

    _hintService = HintService();
    _bookmarkRepository = widget.bookmarkRepository ?? BookmarkRepository();
    _progressRepository = widget.progressRepository ?? ProgressRepository();

    _animCtrl = AnswerAnimationController(vsync: this);

    _checkBookmarkStatus();
    _checkExistingProgress();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Progress 
  void _checkExistingProgress() {
    final solved = _progressRepository.isSolved(widget.question.id);
    if (solved) {
      setState(() {
        _isCorrect = true;
        _hasSubmitted = true;
        _answerController.text = widget.question.jawaban;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animCtrl.playCorrect();
      });
    }
  }

  // ─── Bookmark 
  void _checkBookmarkStatus() {
    setState(() {
      _isBookmarked = _bookmarkRepository.isBookmarked(widget.question.id);
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;
    setState(() => _isTogglingBookmark = true);

    final result = await _bookmarkRepository.toggleBookmark(widget.question);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ??
              (result.isNowBookmarked
                  ? 'Soal disimpan ke Bookmark'
                  : 'Bookmark dihapus')),
          backgroundColor: result.isNowBookmarked ? AppColors.successGreen : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _isBookmarked = result.isNowBookmarked;
        _isTogglingBookmark = false;
      });
    }
  }

  // ─── Submit jawaban 
  Future<void> _submitAnswer() async {
    if (_isSavingProgress) return;

    final userAnswer = _answerController.text;
    if (userAnswer.trim().isEmpty) return;

    final correct = widget.question.checkAnswer(userAnswer);

    setState(() {
      _isCorrect = correct;
      _hasSubmitted = true;
      _isSavingProgress = true;
    });

    if (correct) {
      await _animCtrl.playCorrect();
    } else {
      await _animCtrl.playWrong();
    }

    try {
      await _progressRepository.recordAttempt(
        questionId: widget.question.id,
        categoryId: widget.question.kategoriId,
        isCorrect: correct,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress belum berhasil disimpan. Coba lagi nanti.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProgress = false);
    }
  }

  // ─── Pop Up Hint
  void _showHintDialog(BuildContext context, int currentNum, String hintContent, int totalHints) {
    showDialog(
      context: context,
      barrierDismissible: true, // Pengguna bisa menutup pop-up dengan mengetuk area luar
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Sudut melengkung kotak pop-up
          ),
          backgroundColor: context.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDF0FF), // Warna sesuai mockup hint Anda
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar tinggi pop-up fleksibel mengikuti panjang teks
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Judul Pop-up (HINT X dan Indikator Angka X/Y)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFF005B24), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'HINT $currentNum',
                          style: const TextStyle(
                            color: Color(0xFF005B24),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$currentNum/$totalHints',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const Divider(color: Colors.black12, height: 24, thickness: 1),
                
                // Isi teks bantuan dari database
                Text(
                  hintContent,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Tombol Oke / Tutup di bagian bawah pop-up tengah
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: Color(0xFF004D80),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helper 
  String _buildAnswerPlaceholder() {
    return widget.question.jawaban
        .trim()
        .split(' ')
        .map((w) => '_' * w.length)
        .join(' ');
  }

  Color _getDifficultyColor() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:   return AppColors.easyGreen;
      case DifficultyLevel.medium: return AppColors.mediumAmber;
      case DifficultyLevel.hard:   return AppColors.hardRed;
    }
  }

  String _getDifficultyLabel() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:   return 'Mudah';
      case DifficultyLevel.medium: return 'Sedang';
      case DifficultyLevel.hard:   return 'Sulit';
    }
  }

  // ─── Build 
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: _hasSubmitted && _isCorrect
          ? colors.correctAnswerBg
          : colors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Home',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboardMahasiswa,
            (route) => false,
          ),
        ),
        title: Text(
          widget.question.kategoriNama,
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacings.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner offline — KEBAL TERHADAP BUG KONEKSI
            StreamBuilder<ConnectivityResult>(
              stream: ConnectivityService.instance.onConnectivityChanged,
              builder: (context, snapshot) {
                final isOffline = snapshot.hasData
                    ? snapshot.data == ConnectivityResult.none
                    : false;
                return isOffline ? const OfflineBanner() : const SizedBox.shrink();
              },
            ),

            // ── Kotak Pertanyaan Baru (Sesuai Gambar Mockup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.primaryBlue.withOpacity(0.15)
                    : AppColors.lightBlue,
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color: context.isDark ? Colors.transparent : Colors.blue.shade100, // sesuaikan kecerahan mockup
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Atas: Label Kesulitan & Bookmark Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Kesulitan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withOpacity(0.2), // dibikin soft seperti mockup
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: _getDifficultyColor()),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 6),
                            Text(
                              _getDifficultyLabel(),
                              style: AppTextStyles.buttonSmall.copyWith(
                                color: _getDifficultyColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Bookmark toggle di sisi kanan atas kartu
                      _isTogglingBookmark
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue, strokeWidth: 2),
                            )
                          : IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: _isBookmarked ? 'Hapus Bookmark' : 'Simpan Soal',
                              icon: Icon(
                                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: _isBookmarked ? Colors.amberAccent : colors.primaryText,
                                size: 28,
                              ),
                              onPressed: _toggleBookmark,
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Teks Pertanyaan Utama
                  Text(
                    widget.question.pertanyaan,
                    style: AppTextStyles.h2.copyWith(
                      color: context.isDark ? const Color(0xFF90C4F0) : AppColors.primaryBlue,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ── Panel Hint 
            if (_hintService.hasHints(widget.question)) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Utama HINT Statis di Atas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDark 
                          ? AppColors.primaryBlue.withOpacity(0.2) 
                          : const Color(0xFFD9E7F5), // Warna soft blue latar tombol HINT
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline, 
                          color: context.isDark ? Colors.amber : AppColors.primaryBlue, 
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HINT',
                          style: AppTextStyles.bodySemibold.copyWith(
                            color: context.isDark ? Colors.white : AppColors.primaryBlue,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Daftar Angka Hint Horizontal Berdasarkan Data Database
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _hintService.getHints(widget.question).asMap().entries.map((entry) {
                        final index = entry.key;
                        final hintText = entry.value;
                        final hintNumber = index + 1;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () {
                              // Menandai hint telah dilihat secara sistem
                              _hintService.toggleHints(); 
                              // Munculkan Pop-up Modalnya
                              _showHintDialog(context, hintNumber, hintText, _hintService.hintCount(widget.question));
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF004D80), // Warna biru tua sesuai mockup nomor Anda
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$hintNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic, 
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ── Input Jawaban + Sprint 6 ShakeWidget 
            ShakeWidget(
              controller: _animCtrl,
              child: TextField(
                controller: _answerController,
                enabled: !(_hasSubmitted && _isCorrect),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAnswer(),
                style: AppTextStyles.body.copyWith(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: _buildAnswerPlaceholder(),
                  suffixIcon: Icon(
                    Icons.edit,
                    color: _hasSubmitted 
                        ? (_isCorrect ? AppColors.successGreen : AppColors.errorRed)
                        : colors.primaryText.withOpacity(0.5), 
                      ),
                    enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect ? AppColors.successGreen : AppColors.errorRed)
                          : colors.borderColor,
                      width: _hasSubmitted ? 1.5 : 1.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  filled: true,
                  fillColor: _hasSubmitted && !_isCorrect
                      ? colors.wrongAnswerBg
                      : colors.inputBg,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Tuliskan jawaban Anda secara singkat dan tepat sesuai konteks pertanyaan.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 10),
        color: _hasSubmitted && _isCorrect ? colors.correctAnswerBg : colors.scaffoldBg,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Penting: Agar ukuran mengikuti tinggi total komponen di dalamnya
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Sprint 6: Animasi Benar (Sekarang berada tepat di atas tombol)
            CorrectAnswerCardAnimated(
              controller: _animCtrl,
              visible: _hasSubmitted && _isCorrect,
              message: 'Progres disimpan.',
            ),

            // ── Sprint 6: Animasi Salah (Sekarang berada tepat di atas tombol)
            WrongAnswerBanner(
              controller: _animCtrl,
              visible: _hasSubmitted && !_isCorrect,
            ),

            // Berikan sedikit jarak dinamis antara banner (jika muncul) dengan tombol submit
            if (_hasSubmitted) const SizedBox(height: 12),

            // Tombol Utama Submit / Kembali
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasSubmitted && _isCorrect
                    ? () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.dashboardMahasiswa,
                          (route) => false,
                        )
                    : (_isSavingProgress ? null : _submitAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasSubmitted && _isCorrect
                      ? AppColors.successGreen
                      : AppColors.primaryBlue,
                ),
                child: Text(
                  _hasSubmitted && _isCorrect
                      ? 'Kembali ke Home'
                      : 'Kirim Jawaban',
                  _hasSubmitted && _isCorrect ? 'Kembali ke Bank Soal' : 'Submit Jawaban',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}