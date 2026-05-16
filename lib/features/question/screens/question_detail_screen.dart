// lib/features/questions/screens/question_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/features/question/controllers/question_controller.dart';

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

  bool _showHints = false;
  bool _isCorrect = false;
  bool _hasSubmitted = false;
  bool _isShaking = false;

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
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _buildAnswerPlaceholder() {
    final words = widget.question.jawaban.trim().split(' ');
    return words.map((word) => '_' * word.length).join(' ');
  }

  Color _getDifficultyColor() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  String _getDifficultyLabel() {
    switch (widget.question.tingkatKesulitan) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  void _submitAnswer() {
    final userAnswer = _answerController.text;

    if (userAnswer.trim().isEmpty) return;

    final correct = widget.question.checkAnswer(userAnswer);

    if (correct) {
      setState(() {
        _isCorrect = true;
        _hasSubmitted = true;
      });
    } else {
      setState(() {
        _isCorrect = false;
        _hasSubmitted = true;
        _isShaking = true;
      });
      _shakeController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isShaking = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hasSubmitted && _isCorrect
          ? Colors.green.shade50
          : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5C99),
        foregroundColor: Colors.white,
        title: Text(
          widget.question.kategoriNama,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getDifficultyLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak pertanyaan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD6E8F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.question.pertanyaan,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F5C99),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Placeholder panjang jawaban
            Text(
              'Petunjuk panjang jawaban:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _buildAnswerPlaceholder(),
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                color: Color(0xFF1F5C99),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Panel Hint
            if (widget.question.hints.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _showHints = !_showHints),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Lihat Hint',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showHints
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.amber,
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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
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
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Field input jawaban dengan shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _isShaking ? _shakeAnimation.value : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: TextField(
                controller: _answerController,
                enabled: !(_hasSubmitted && _isCorrect),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAnswer(),
                decoration: InputDecoration(
                  hintText: 'Ketik jawabanmu di sini...',
                  filled: true,
                  fillColor: _hasSubmitted && !_isCorrect
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Pesan feedback
            if (_hasSubmitted && _isCorrect)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Benar!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            if (_hasSubmitted && !_isCorrect)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Jawaban salah, coba lagi.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tombol Kirim atau Soal Berikutnya
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasSubmitted && _isCorrect
                    ? () => Navigator.pop(context)
                    : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasSubmitted && _isCorrect
                      ? Colors.green
                      : const Color(0xFF1F5C99),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _hasSubmitted && _isCorrect
                      ? 'Kembali ke Bank Soal'
                      : 'Kirim Jawaban',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}