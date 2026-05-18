import 'package:flutter/material.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/features/questions/controllers/question_controller.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/shared/widgets/app_widgets.dart';

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

  // ── State lama (jawaban) ──────────────────────────────────────────────────
  bool _isCorrect = false;
  bool _hasSubmitted = false;
  bool _isShaking = false;

  // ── State baru (hint popup) ───────────────────────────────────────────────
  int _activeHintIndex = 0;
  OverlayEntry? _hintOverlay;

  // ── Animation controllers ─────────────────────────────────────────────────
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
    _removeHintOverlay(); // pastikan overlay dibersihkan saat layar ditutup
    super.dispose();
  }

  void _showHintPopup(int index) {
    setState(() => _activeHintIndex = index);
    _removeHintOverlay();
    _hintOverlay = _buildHintOverlayEntry(index);
    Overlay.of(context).insert(_hintOverlay!);
  }

  void _removeHintOverlay() {
    _hintOverlay?.remove();
    _hintOverlay = null;
  }

  OverlayEntry _buildHintOverlayEntry(int currentIndex) {
    final hints = widget.question.hints;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // ── Area transparan di luar popup
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeHintOverlay,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

            // ── Popup card hint
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).size.height * 0.45,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF4FD),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header popup
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF4FD),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Color(0xFF00447B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HINT ${currentIndex + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00447B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${currentIndex + 1}/${hints.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00447B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Isi hint
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Text(
                          hints[currentIndex],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A2B3C),
                            fontStyle: FontStyle.italic,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF00447B),
          onPressed: () {
            _removeHintOverlay(); // tutup popup kalau masih terbuka
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00447B),
        title: const Text(
          'BANKSOS',
          style: TextStyle(
            fontSize: 28,
            color: Color(0xFF00447B),
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00447B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: Color(0xFF00447B),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  '12:45',
                  style: TextStyle(
                    color: Color(0xFF00447B),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kartu pertanyaan
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // Badge kesulitan
                        AppBadge.difficulty(
                            widget.question.tingkatKesulitan.name),
                        const Spacer(),
                        // Tombol bookmark
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: Color(0xFF1F5C99),
                          ),
                          onPressed: () {
                            // TODO Sprint 3: implementasi bookmark
                          },
                          tooltip: 'Bookmark',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Teks pertanyaan
                    Text(
                      widget.question.pertanyaan,
                      style: AppTextStyles.h2
                          .copyWith(fontWeight: FontWeight.w700),
                    ),

                    // Gambar soal (jika ada imageUrl)
                    if (widget.question.imageUrl != null &&
                        widget.question.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.question.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            height: 160,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Tombol HINT + nomor angka (di luar kartu)
            if (widget.question.hints.isNotEmpty) ...[
              // Baris: tombol HINT di kiri, nomor-nomor di kanannya
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol HINT
                  GestureDetector(
                    onTap: () => _showHintPopup(_activeHintIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00447B)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: Color(0xFF00447B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'HINT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00447B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nomor-nomor hint — jumlah otomatis dari database
                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          widget.question.hints.length,
                          (i) {
                            final bool isActive = i == _activeHintIndex;
                            return GestureDetector(
                              onTap: () => _showHintPopup(i),
                              child: Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.only(right: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00447B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isActive
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00447B)
                                                .withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Placeholder panjang jawaban 
            // Text(
            //   _buildAnswerPlaceholder(),
            //   style: const TextStyle(
            //     fontSize: 20,
            //     letterSpacing: 2,
            //     color: Color(0xFF00447B),
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),

            const SizedBox(height: 20),

            // ── Label input 
            const Text(
              'TULIS JAWABAN',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // ── Field input jawaban dengan shake animation 
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_isShaking ? _shakeAnimation.value : 0, 0),
                  child: child,
                );
              },
              child: TextField(
                controller: _answerController,
                enabled: !(_hasSubmitted && _isCorrect),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAnswer(),
                maxLines: 1,
                decoration: InputDecoration(
                  hintText:
                      _buildAnswerPlaceholder(), // placeholder dengan garis bawah sesuai panjang jawaban
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: _hasSubmitted && !_isCorrect
                      ? Colors.red.shade50
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _hasSubmitted
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF00447B),
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: Icon(
                    Icons.edit_outlined,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Tuliskan jawaban Anda secara singkat dan tepat sesuai konteks pertanyaan.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 12),

            // ── Pesan feedback 
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

            // ── Tombol Submit / Kembali 
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasSubmitted && _isCorrect
                    ? () {
                        _removeHintOverlay();
                        Navigator.pop(context);
                      }
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hasSubmitted && _isCorrect
                          ? 'Kembali ke Bank Soal'
                          : 'Submit Jawaban',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _hasSubmitted && _isCorrect
                          ? Icons.arrow_back
                          : Icons.navigate_next,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _buildAnswerPlaceholder() {
    final words = widget.question.jawaban.trim().split(' ');
    return words.map((word) => '_' * word.length).join(' ');
  }
}
