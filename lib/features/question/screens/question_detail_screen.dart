// lib/features/question/screens/question_detail_screen.dart
// Sprint 6 UPDATE — Revaldi (RP): Integrasi AnswerAnimationController
//
// Perubahan dari Sprint 3 → Sprint 6:
//   - ShakeWidget menggantikan AnimatedBuilder shake manual
//   - CorrectAnswerCardAnimated menggantikan container hijau statis
//   - WrongAnswerBanner menggantikan container merah statis
//   - Warna background scaffold menggunakan context.colors (dark mode ready)
//   - Input border menggunakan tema, bukan hardcoded color

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../repositories/bookmark_repository.dart';
import '../repositories/progress_repository.dart';
import '../services/answer_animation_service.dart';
import '../services/hint_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;
  final BookmarkRepository? bookmarkRepository;
  final IProgressRepository? progressRepository;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.bookmarkRepository,
    this.progressRepository,
  });

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

    // Inisialisasi animation controller (Sprint 6)
    _animCtrl = AnswerAnimationController(vsync: this);

    _checkBookmarkStatus();
    _checkExistingProgress();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animCtrl.dispose(); // Sprint 6: dispose animation controller
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
      // Langsung mainkan animasi benar jika sudah pernah solved
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

    final result =
        await _bookmarkRepository.toggleBookmark(widget.question);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ??
              (result.isNowBookmarked
                  ? 'Soal disimpan ke Bookmark'
                  : 'Bookmark dihapus')),
          backgroundColor:
              result.isNowBookmarked ? AppColors.successGreen : null,
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

    // ── Sprint 6: Mainkan animasi sesuai hasil 
    if (correct) {
      await _animCtrl.playCorrect();
    } else {
      await _animCtrl.playWrong();
    }

    // Simpan progress
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
            content: Text(
                'Progress belum berhasil disimpan. Coba lagi nanti.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProgress = false);
    }
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
    // Sprint 6: gunakan adaptive colors agar dark mode bekerja
    final colors = context.colors;

    return Scaffold(
      // Sprint 6: tidak hardcode warna, gunakan adaptive
      backgroundColor: _hasSubmitted && _isCorrect
          ? colors.correctAnswerBg
          : colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.question.kategoriNama,
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
        ),
        actions: [
          // Badge kesulitan
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              borderRadius: AppRadius.pill,
            ),
            child: Text(_getDifficultyLabel(),
                style: AppTextStyles.buttonSmall),
          ),

          // Bookmark toggle
          _isTogglingBookmark
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.textLight, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip:
                      _isBookmarked ? 'Hapus Bookmark' : 'Simpan Soal',
                  icon: Icon(
                    _isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _isBookmarked
                        ? Colors.amberAccent
                        : AppColors.textLight,
                  ),
                  onPressed: _toggleBookmark,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacings.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner offline
            StreamBuilder<ConnectivityResult>(
              stream: ConnectivityService.instance.onConnectivityChanged,
              builder: (context, snapshot) {
                final isOffline = snapshot.hasData
                    ? snapshot.data == ConnectivityResult.none
                    : false;
                return isOffline
                    ? const OfflineBanner()
                    : const SizedBox.shrink();
              },
            ),

            // ── Kotak Pertanyaan 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Sprint 6: adaptive, bukan hardcode lightBlue
                color: context.isDark
                    ? AppColors.primaryBlue.withOpacity(0.15)
                    : AppColors.lightBlue,
                borderRadius: AppRadius.lgAll,
              ),
              child: Text(
                widget.question.pertanyaan,
                style: AppTextStyles.h2.copyWith(
                  color: context.isDark
                      ? const Color(0xFF90C4F0)
                      : AppColors.primaryBlue,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Placeholder Jawaban 
            Text('Petunjuk panjang jawaban:',
                style: AppTextStyles.small),
            const SizedBox(height: 4),
            Text(
              _buildAnswerPlaceholder(),
              style: AppTextStyles.answerPlaceholder.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // ── Panel Hint 
            if (_hintService.hasHints(widget.question)) ...[
              GestureDetector(
                onTap: () =>
                    setState(() => _hintService.toggleHints()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF2A2000)
                        : AppColors.mediumBg,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                        color:
                            AppColors.mediumAmber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppColors.mediumAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lihat Hint (${_hintService.hintCount(widget.question)})',
                        style: AppTextStyles.bodySemibold
                            .copyWith(color: AppColors.mediumText),
                      ),
                      const Spacer(),
                      Icon(
                        _hintService.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.mediumAmber,
                      ),
                    ],
                  ),
                ),
              ),
              if (_hintService.isExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF2A2000)
                        : AppColors.mediumBg,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                        color:
                            AppColors.mediumAmber.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _hintService
                        .getHints(widget.question)
                        .asMap()
                        .entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('${e.key + 1}. ',
                                    style: AppTextStyles.bodySemibold
                                        .copyWith(
                                            color:
                                                AppColors.mediumText)),
                                Expanded(
                                  child: Text(e.value,
                                      style: AppTextStyles.body
                                          .copyWith(
                                              color: AppColors
                                                  .mediumText)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // ── Input Jawaban + Sprint 6 ShakeWidget 
            ShakeWidget(
              controller: _animCtrl,
              child: TextField(
                controller: _answerController,
                enabled: !(_hasSubmitted && _isCorrect),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAnswer(),
                style: AppTextStyles.body.copyWith(
                  color: colors.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik jawabanmu di sini...',
                  // Sprint 6: border warna dari tema (tidak hardcode)
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed)
                          : colors.borderColor,
                      width: _hasSubmitted ? 1.5 : 1.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(
                      color: colors.borderColor,
                    ),
                  ),
                  filled: true,
                  fillColor: _hasSubmitted && !_isCorrect
                      ? colors.wrongAnswerBg
                      : colors.inputBg,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Sprint 6: Animasi Benar 
            CorrectAnswerCardAnimated(
              controller: _animCtrl,
              visible: _hasSubmitted && _isCorrect,
              message: 'Progres disimpan.',
            ),

            // ── Sprint 6: Animasi Salah 
            WrongAnswerBanner(
              controller: _animCtrl,
              visible: _hasSubmitted && !_isCorrect,
            ),

            const SizedBox(height: 20),

            // ── Tombol Submit / Kembali 
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasSubmitted && _isCorrect
                    ? () => Navigator.pop(context)
                    : (_isSavingProgress ? null : _submitAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasSubmitted && _isCorrect
                      ? AppColors.successGreen
                      : AppColors.primaryBlue,
                ),
                child: Text(
                  _hasSubmitted && _isCorrect
                      ? 'Kembali ke Bank Soal'
                      : 'Kirim Jawaban',
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