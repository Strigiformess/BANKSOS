// lib/features/question/screens/question_detail_screen.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Tambahan untuk UI Reactive

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/question_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../repositories/progress_repository.dart';
import '../services/hint_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;
  final IProgressRepository? progressRepository;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.progressRepository,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();

  // ─── State UI ────────────────────────────────────────────────────────────
  late final HintService _hintService;
  bool _isCorrect = false;
  bool _hasSubmitted = false;
  bool _isShaking = false;
  bool _isSavingProgress = false;

  late final IProgressRepository _progressRepository;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _hintService = HintService();
    _progressRepository = widget.progressRepository ?? ProgressRepository();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeController.reverse();
    });

    _checkExistingProgress();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Integrasi Progress Checking ──────────────────────────────────────────
  void _checkExistingProgress() {
    final solved = _progressRepository.isSolved(widget.question.id);
    if (solved) {
      setState(() {
        _isCorrect = true;
        _hasSubmitted = true;
        _answerController.text = widget.question.jawaban; 
      });
    }
  }

  // ─── Simpan Progress ─────────────────────────────────────────────────────
  Future<void> _saveProgress({required bool isCorrect}) async {
    await _progressRepository.recordAttempt(
      questionId: widget.question.id,
      categoryId: widget.question.kategoriId,
      isCorrect: isCorrect,
    );
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  String _buildAnswerPlaceholder() {
    final words = widget.question.jawaban.trim().split(' ');
    return words.map((word) => '_' * word.length).join(' ');
  }

  Color _getDifficultyColor() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:
        return AppColors.easyGreen;
      case DifficultyLevel.medium:
        return AppColors.mediumAmber;
      case DifficultyLevel.hard:
        return AppColors.hardRed;
    }
  }

  String _getDifficultyLabel() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:
        return 'Mudah';
      case DifficultyLevel.medium:
        return 'Sedang';
      case DifficultyLevel.hard:
        return 'Sulit';
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submitAnswer() async {
    if (_isSavingProgress) return;

    final userAnswer = _answerController.text;
    if (userAnswer.trim().isEmpty) return;

    final correct = widget.question.checkAnswer(userAnswer);

    if (correct) {
      setState(() {
        _isCorrect = true;
        _hasSubmitted = true;
        _isSavingProgress = true;
      });
    } else {
      setState(() {
        _isCorrect = false;
        _hasSubmitted = true;
        _isShaking = true;
        _isSavingProgress = true;
      });
      _shakeController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isShaking = false);
      });
    }

    try {
      await _saveProgress(isCorrect: correct);
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
      if (mounted) {
        setState(() => _isSavingProgress = false);
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 1. Ekstrak & Bersihkan User ID
    final rawUserId = SessionService.instance.userId ?? '';
    String cleanId(String id) {
      final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
      return match != null ? match.group(1)! : id;
    }
    final currentUserId = rawUserId.isNotEmpty ? cleanId(rawUserId) : '';

    return Scaffold(
      backgroundColor:
          _hasSubmitted && _isCorrect ? AppColors.easyBg : AppColors.bgWhite,
      appBar: AppBar(
        title: Text(
          widget.question.kategoriNama,
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
        ),
        // ─── Bagian AppBar di file question_detail_screen.dart (Cari bagian "actions: [") ───

        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              borderRadius: AppRadius.pill,
            ),
            child: Text(_getDifficultyLabel(), style: AppTextStyles.buttonSmall),
          ),

          // Bookmark Toggle Dalam Soal
          ValueListenableBuilder<Box<BookmarkModel>>(
            valueListenable: HiveService.instance.bookmarksBox.listenable(),
            builder: (context, box, _) {
              final isBookmarked = box.values.any((b) =>
                  cleanId(b.questionId) == cleanId(widget.question.id) &&
                  cleanId(b.userId) == currentUserId);

              return IconButton(
                tooltip: isBookmarked ? 'Hapus Bookmark' : 'Simpan Soal',
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.amberAccent : AppColors.textLight,
                ),
                onPressed: () async {
                  if (currentUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesi tidak valid.'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  
                  final isNowSaved = await SyncService.instance.toggleBookmark(
                    userId: currentUserId,
                    questionId: widget.question.id,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isNowSaved ? 'Soal disimpan ke Bookmark' : 'Bookmark dihapus'),
                        backgroundColor: isNowSaved ? AppColors.successGreen : AppColors.textGrey,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
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
                    ? snapshot.data.toString().contains('none')
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
                color: AppColors.lightBlue,
                borderRadius: AppRadius.lgAll,
              ),
              child: Text(
                widget.question.pertanyaan,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primaryBlue,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Placeholder Jawaban
            Text('Petunjuk panjang jawaban:', style: AppTextStyles.small),
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
                onTap: () => setState(() => _hintService.toggleHints()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBg,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                        color: AppColors.mediumAmber.withOpacity(0.4)),
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
                      if (!_hintService.hasBeenViewed)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mediumAmber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Baru',
                              style: AppTextStyles.small
                                  .copyWith(color: Colors.white)),
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
                    color: AppColors.mediumBg,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                        color: AppColors.mediumAmber.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _hintService
                        .getHints(widget.question)
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ',
                                  style: AppTextStyles.bodySemibold
                                      .copyWith(color: AppColors.mediumText),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.mediumText),
                                  ),
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

            // ── Input Jawaban + Shake
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_isShaking ? _shakeAnimation.value : 0, 0),
                child: child,
              ),
              child: TextField(
                controller: _answerController,
                enabled: !(_hasSubmitted && _isCorrect),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAnswer(),
                decoration: InputDecoration(
                  hintText: 'Ketik jawabanmu di sini...',
                  filled: true,
                  fillColor: _hasSubmitted && !_isCorrect
                      ? AppColors.hardBg
                      : AppColors.bgLight,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed)
                          : AppColors.borderGrey,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed)
                          : AppColors.borderGrey,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Feedback Benar ────────────────────────────────────────────
            if (_hasSubmitted && _isCorrect)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.easyBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.successGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Benar! Progres disimpan.',
                      style: AppTextStyles.bodySemibold
                          .copyWith(color: AppColors.easyText),
                    ),
                  ],
                ),
              ),

            // ── Feedback Salah ────────────────────────────────────────────
            if (_hasSubmitted && !_isCorrect)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.hardBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: AppColors.errorRed),
                    const SizedBox(width: 8),
                    Text(
                      'Jawaban salah, coba lagi.',
                      style: AppTextStyles.bodySemibold
                          .copyWith(color: AppColors.hardText),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ── Tombol Kirim / Kembali ────────────────────────────────────
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