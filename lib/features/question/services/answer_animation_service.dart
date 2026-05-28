// lib/features/question/services/answer_animation_service.dart
// Sprint 6 — Revaldi (RP): Animasi jawaban benar & salah
//
// Menyediakan:
//   - AnswerAnimationController : controller stateful untuk animasi di widget
//   - CorrectAnswerCard         : card hijau animasi saat jawaban benar
//   - ShakeWidget               : wrapper shake animation saat jawaban salah
//
// Cara pakai di QuestionDetailScreen (ganti widget yang sudah ada):
//
//   // Di State, deklarasikan:
//   late final AnswerAnimationController _animCtrl;
//
//   // Di initState:
//   _animCtrl = AnswerAnimationController(vsync: this);
//
//   // Di dispose:
//   _animCtrl.dispose();
//
//   // Saat jawaban dikirim:
//   if (benar) {
//     await _animCtrl.playCorrect();
//   } else {
//     await _animCtrl.playWrong();
//   }
//
//   // Di build, bungkus input field dengan ShakeWidget:
//   ShakeWidget(controller: _animCtrl, child: TextField(...))
//
//   // Ganti card feedback dengan:
//   if (_hasSubmitted) CorrectAnswerCard(visible: _isCorrect)

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATION CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

/// Controller tunggal yang mengelola dua animasi:
///   1. _shakeCtrl   — shake animation saat jawaban salah
///   2. _correctCtrl — fade+scale animation saat jawaban benar
///
/// Harus di-dispose bersama widget State-nya.
class AnswerAnimationController {
  AnswerAnimationController({required TickerProvider vsync})
      : _shakeCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 450),
        ),
        _correctCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 500),
        ) {
    // Shake: bergerak kiri-kanan-kiri menggunakan elasticIn
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Correct: fade in + scale up dari 0.85 ke 1.0
    _correctFade = CurvedAnimation(
        parent: _correctCtrl, curve: Curves.easeOut);
    _correctScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _correctCtrl, curve: Curves.easeOutBack),
    );
  }

  final AnimationController _shakeCtrl;
  final AnimationController _correctCtrl;

  late final Animation<double> _shakeAnim;
  late final Animation<double> _correctFade;
  late final Animation<double> _correctScale;

  Animation<double> get shakeAnim   => _shakeAnim;
  Animation<double> get correctFade => _correctFade;
  Animation<double> get correctScale => _correctScale;

  bool get isShaking => _shakeCtrl.isAnimating;

  /// Mainkan animasi BENAR (fade in + scale).
  Future<void> playCorrect() async {
    _shakeCtrl.reset();
    _correctCtrl.reset();
    await _correctCtrl.forward();
  }

  /// Mainkan animasi SALAH (shake kiri-kanan).
  Future<void> playWrong() async {
    _correctCtrl.reset();
    _shakeCtrl.reset();
    await _shakeCtrl.forward();
  }

  void dispose() {
    _shakeCtrl.dispose();
    _correctCtrl.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHAKE WIDGET — bungkus widget yang goyang saat jawaban salah
// ══════════════════════════════════════════════════════════════════════════════

/// Widget yang menerapkan shake animation pada child-nya.
/// Dipakai untuk membungkus TextField input jawaban.
///
/// Amplitude menghasilkan gerakan: 0 → +12 → -12 → +6 → -6 → 0 px
class ShakeWidget extends AnimatedWidget {
  ShakeWidget({
    super.key,
    required AnswerAnimationController controller,
    required this.child,
    this.amplitudePx = 12.0,
  }) : super(listenable: controller._shakeAnim);

  final Widget child;
  final double amplitudePx;

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    // Menggunakan sin wave agar gerakan bolak-balik terasa natural
    final offset = amplitudePx *
        _sin(anim.value * 3.14159 * 4) *
        (1 - anim.value); // memudar seiring animasi selesai
    return Transform.translate(
      offset: Offset(offset, 0),
      child: child,
    );
  }

  // Aproksimasi sin sederhana tanpa import dart:math
  static double _sin(double x) {
    // Taylor series: sin(x) ≈ x - x³/6 + x⁵/120
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CORRECT ANSWER CARD — card hijau animasi saat jawaban benar
// ══════════════════════════════════════════════════════════════════════════════

/// Card konfirmasi jawaban benar dengan animasi fade-in + scale-up.
/// Gantikan card feedback statis yang sebelumnya dipakai.
///
/// [visible]    — true jika jawaban benar & sudah di-submit
/// [controller] — AnswerAnimationController milik screen
/// [message]    — pesan yang ditampilkan, default 'Benar! Progres disimpan.'
class CorrectAnswerCard extends AnimatedWidget {
  CorrectAnswerCard({
    super.key,
    required AnswerAnimationController controller,
    required this.visible,
    this.message = 'Benar! Progres disimpan.',
  }) : super(listenable: controller._correctFade);

  final bool visible;
  final String message;

  // Simpan referensi scale dari controller — diakses via listenable parent
  // Tidak bisa diakses langsung karena AnimatedWidget menyimpan satu listenable.
  // Kita gunakan workaround: buat widget composite terpisah di bawah.

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final opacity = (listenable as Animation<double>).value;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.easyBg,
          borderRadius: AppRadius.mdAll,
          border:
              Border.all(color: AppColors.successGreen.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.successGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySemibold
                    .copyWith(color: AppColors.easyText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versi lengkap CorrectAnswerCard yang juga menerapkan scale animation.
/// Gunakan ini jika ingin efek pop yang lebih hidup.
class CorrectAnswerCardAnimated extends StatelessWidget {
  const CorrectAnswerCardAnimated({
    super.key,
    required this.controller,
    required this.visible,
    this.message = 'Benar! Progres disimpan.',
  });

  final AnswerAnimationController controller;
  final bool visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge(
          [controller._correctFade, controller._correctScale]),
      builder: (context, _) {
        return Opacity(
          opacity: controller.correctFade.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: controller.correctScale.value,
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.easyBg,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                    color: AppColors.successGreen.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successGreen.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ikon dengan pulse effect kecil
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.successGreen, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jawaban Benar!',
                          style: AppTextStyles.bodySemibold
                              .copyWith(color: AppColors.easyText),
                        ),
                        Text(
                          message,
                          style: AppTextStyles.small
                              .copyWith(color: AppColors.easyText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WRONG ANSWER BANNER — banner merah animasi saat jawaban salah
// ══════════════════════════════════════════════════════════════════════════════

/// Banner tipis merah di bawah input yang muncul saat jawaban salah.
/// Menggantikan container feedback statis.
class WrongAnswerBanner extends StatelessWidget {
  const WrongAnswerBanner({
    super.key,
    required this.controller,
    required this.visible,
  });

  final AnswerAnimationController controller;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.hardBg,
          borderRadius: AppRadius.mdAll,
          border:
              Border.all(color: AppColors.errorRed.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded,
                color: AppColors.errorRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'Jawaban salah, coba lagi.',
              style: AppTextStyles.bodySemibold
                  .copyWith(color: AppColors.hardText),
            ),
          ],
        ),
      ),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
    );
  }
}