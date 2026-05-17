// lib/features/question/screens/question_detail_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/widgets/app_widgets.dart';
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

  bool _showHints   = false;
  bool _isCorrect   = false;
  bool _hasSubmitted = false;
  bool _isShaking   = false;

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
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _buildAnswerPlaceholder() {
    final words = widget.question.jawaban.trim().split(' ');
    return words.map((word) => '_' * word.length).join(' ');
  }

  /// Warna badge kesulitan dari AppColors ─ tidak hardcode lagi.
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
        title: Text(widget.question.kategoriNama,
            style: AppTextStyles.appBarTitle.copyWith(fontSize: 16)),
        actions: [
          // Badge kesulitan di AppBar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              _getDifficultyLabel(),
              style: AppTextStyles.buttonSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO Sprint 3: implementasi bookmark
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacings.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner offline — tampilkan saat tidak ada koneksi
            StreamBuilder<ConnectivityResult>(
              stream: ConnectivityService.instance.onConnectivityChanged,
              builder: (context, snapshot) {
                final isOffline = snapshot.hasData
                    ? (snapshot.data == ConnectivityResult.none)
                    : false;
                return isOffline ? const OfflineBanner() : const SizedBox.shrink();
              },
            ),

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

            // ── Placeholder Panjang Jawaban ───────────────────────────────
            Text(
              'Petunjuk panjang jawaban:',
              style: AppTextStyles.small,
            ),
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
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBg,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.mediumAmber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.mediumAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lihat Hint',
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
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mediumText),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // ── Input Jawaban dengan shake animation ──────────────────────
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
                      'Benar!',
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