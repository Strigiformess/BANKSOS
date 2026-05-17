// lib/features/question/screens/question_detail_screen.dart
// Sprint 3: Tambah bookmark toggle (Seruni) + save progress ke Hive

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../controllers/question_controller.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;

  const QuestionDetailScreen({
    super.key,
    required this.question,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  late final QuestionController _controller;

  // ─── State UI ────────────────────────────────────────────────────────────
  bool _showHints    = false;
  bool _isCorrect    = false;
  bool _hasSubmitted = false;
  bool _isShaking    = false;

  // ─── State Sprint 3 ───────────────────────────────────────────────────────
  bool _isBookmarked      = false;
  bool _isTogglingBookmark = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = QuestionController();

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

    // Cek status bookmark saat halaman dibuka
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Bookmark ─────────────────────────────────────────────────────────────

  void _checkBookmarkStatus() {
    final userId = SessionService.instance.userId ?? '';
    if (userId.isEmpty) return;

    final box = HiveService.instance.bookmarksBox;
    final exists = box.values.any(
      (b) => b.questionId == widget.question.id && b.userId == userId,
    );

    setState(() => _isBookmarked = exists);
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;
    setState(() => _isTogglingBookmark = true);

    final userId = SessionService.instance.userId ?? '';
    if (userId.isEmpty) {
      setState(() => _isTogglingBookmark = false);
      return;
    }

    final box = HiveService.instance.bookmarksBox;

    if (_isBookmarked) {
      // ── Hapus bookmark ─────────────────────────────────────────────────
      final toDelete = box.values
          .where((b) =>
              b.questionId == widget.question.id && b.userId == userId)
          .toList();
      for (final b in toDelete) {
        await box.delete(b.key);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark dihapus'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // ── Tambah bookmark ────────────────────────────────────────────────
      const uuid = Uuid();
      final bookmark = BookmarkModel(
        id: uuid.v4(),
        userId: userId,
        questionId: widget.question.id,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      await box.put(bookmark.id, bookmark);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal disimpan ke Bookmark'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    setState(() {
      _isBookmarked = !_isBookmarked;
      _isTogglingBookmark = false;
    });
  }

  // ─── Simpan Progress ke Hive ─────────────────────────────────────────────

  Future<void> _saveProgress({required bool isCorrect}) async {
    final userId = SessionService.instance.userId ?? '';
    if (userId.isEmpty) return;

    final box = HiveService.instance.userProgressBox;

    // Cari progress yang sudah ada untuk soal ini
    final existing = box.values
        .where((p) =>
            p.questionId == widget.question.id && p.userId == userId)
        .toList();

    if (existing.isNotEmpty) {
      final p = existing.first;
      final updated = p.copyWith(
        isSolved: p.isSolved || isCorrect,
        solvedAt: (isCorrect && p.solvedAt == null) ? DateTime.now() : p.solvedAt,
        attemptCount: p.attemptCount + 1,
        isSynced: false, // akan di-sync oleh SyncManager (Sprint 5)
      );
      await box.put(p.key, updated);
    } else {
      const uuid = Uuid();
      final progress = UserProgressModel(
        id: uuid.v4(),
        userId: userId,
        questionId: widget.question.id,
        isSolved: isCorrect,
        solvedAt: isCorrect ? DateTime.now() : null,
        attemptCount: 1,
        isSynced: false,
      );
      await box.put(progress.id, progress);
    }
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

  void _submitAnswer() {
    final userAnswer = _answerController.text;
    if (userAnswer.trim().isEmpty) return;

    final correct = widget.question.checkAnswer(userAnswer);

    // Simpan progress ke Hive (Sprint 3)
    _saveProgress(isCorrect: correct);

    if (correct) {
      setState(() {
        _isCorrect    = true;
        _hasSubmitted = true;
      });
    } else {
      setState(() {
        _isCorrect    = false;
        _hasSubmitted = true;
        _isShaking    = true;
      });
      _shakeController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isShaking = false);
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hasSubmitted && _isCorrect
          ? AppColors.easyBg
          : AppColors.bgWhite,
      appBar: AppBar(
        title: Text(
          widget.question.kategoriNama,
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
        ),
        actions: [
          // ── Badge Kesulitan ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              borderRadius: AppRadius.pill,
            ),
            child: Text(_getDifficultyLabel(), style: AppTextStyles.buttonSmall),
          ),

          // ── Bookmark Toggle ──────────────────────────────────────────
          _isTogglingBookmark
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textLight,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: _isBookmarked ? 'Hapus Bookmark' : 'Simpan Soal',
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
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
            // ── Kotak Pertanyaan ──────────────────────────────────────────
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

            // ── Placeholder Jawaban ───────────────────────────────────────
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

            // ── Panel Hint ────────────────────────────────────────────────
            if (widget.question.hints.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _showHints = !_showHints),
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
                        'Lihat Hint (${widget.question.hints.length})',
                        style: AppTextStyles.bodySemibold
                            .copyWith(color: AppColors.mediumText),
                      ),
                      const Spacer(),
                      Icon(
                        _showHints ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.mediumAmber,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showHints) ...[
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
                    children: widget.question.hints
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

            // ── Input Jawaban + Shake ────────────────────────────────────
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
                    : _submitAnswer,
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