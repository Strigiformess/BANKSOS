// lib/core/theme/app_theme_extensions.dart
// Sprint 6 — Revaldi (RP): Dark Mode Implementation
//
// Semua warna yang konteks-spesifik (berbeda antara light & dark) didefinisikan
// di sini sebagai ThemeExtension agar tidak ada warna hardcoded di widget.
//
// Cara pakai di widget:
//   final colors = Theme.of(context).extension<AppAdaptiveColors>()!;
//   Container(color: colors.cardBg)
//
// JANGAN pakai AppColors.* langsung di widget jika warnanya perlu berbeda
// antara light & dark mode. Gunakan AppAdaptiveColors via ThemeExtension.

import 'package:flutter/material.dart';
import 'app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ADAPTIVE COLORS — berubah antara light & dark
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class AppAdaptiveColors extends ThemeExtension<AppAdaptiveColors> {
  const AppAdaptiveColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.inputBg,
    required this.sidebarBg,
    required this.bottomNavBg,
    required this.dividerColor,
    required this.primaryText,
    required this.secondaryText,
    required this.hintText,
    required this.borderColor,
    required this.chipBg,
    required this.chipSelectedBg,
    required this.bannerInfoBg,
    required this.bannerSuccessBg,
    required this.bannerWarningBg,
    required this.bannerErrorBg,
    required this.rankCardBg,          // latar card rank di dashboard
    required this.categoryItemBg,       // item sidebar kategori terpilih
    required this.questionCardBg,       // card soal
    required this.correctAnswerBg,      // background hijau saat jawaban benar
    required this.wrongAnswerBg,        // background merah saat salah
    required this.offlineBannerBg,      // banner offline
    required this.avatarBg,
    required this.statCardBg,
  });

  final Color scaffoldBg;
  final Color cardBg;
  final Color inputBg;
  final Color sidebarBg;
  final Color bottomNavBg;
  final Color dividerColor;
  final Color primaryText;
  final Color secondaryText;
  final Color hintText;
  final Color borderColor;
  final Color chipBg;
  final Color chipSelectedBg;
  final Color bannerInfoBg;
  final Color bannerSuccessBg;
  final Color bannerWarningBg;
  final Color bannerErrorBg;
  final Color rankCardBg;
  final Color categoryItemBg;
  final Color questionCardBg;
  final Color correctAnswerBg;
  final Color wrongAnswerBg;
  final Color offlineBannerBg;
  final Color avatarBg;
  final Color statCardBg;

  // ─── Light ────────────────────────────────────────────────────────────────
  static const light = AppAdaptiveColors(
    scaffoldBg:      AppColors.bgLight,
    cardBg:          AppColors.bgWhite,
    inputBg:         AppColors.bgWhite,
    sidebarBg:       AppColors.bgLight,
    bottomNavBg:     AppColors.bgWhite,
    dividerColor:    AppColors.borderGrey,
    primaryText:     AppColors.textDark,
    secondaryText:   AppColors.textGrey,
    hintText:        Color(0xFFB0B7C0),
    borderColor:     AppColors.borderGrey,
    chipBg:          AppColors.bgWhite,
    chipSelectedBg:  AppColors.lightBlue,
    bannerInfoBg:    Color(0xFFEFF6FF),
    bannerSuccessBg: Color(0xFFF0FDF4),
    bannerWarningBg: Color(0xFFFFFBEB),
    bannerErrorBg:   Color(0xFFFEF2F2),
    rankCardBg:      AppColors.primaryBlue,
    categoryItemBg:  Color(0x141F5C99),   // primaryBlue 8% opacity
    questionCardBg:  AppColors.bgWhite,
    correctAnswerBg: AppColors.easyBg,
    wrongAnswerBg:   AppColors.hardBg,
    offlineBannerBg: Color(0x1FF59E0B),   // warningYellow 12%
    avatarBg:        AppColors.lightBlue,
    statCardBg:      AppColors.bgWhite,
  );

  // ─── Dark ─────────────────────────────────────────────────────────────────
  static const dark = AppAdaptiveColors(
    scaffoldBg:      Color(0xFF0D1B2A),
    cardBg:          Color(0xFF1A2744),
    inputBg:         Color(0xFF1E2E45),
    sidebarBg:       Color(0xFF111E30),
    bottomNavBg:     Color(0xFF0D1B2A),
    dividerColor:    Color(0xFF2D3748),
    primaryText:     Color(0xFFE8EDF5),
    secondaryText:   Color(0xFF8A9BB0),
    hintText:        Color(0xFF5A6A80),
    borderColor:     Color(0xFF2D3748),
    chipBg:          Color(0xFF1A2744),
    chipSelectedBg:  Color(0xFF1E3A5F),
    bannerInfoBg:    Color(0xFF0D1F35),
    bannerSuccessBg: Color(0xFF0D2218),
    bannerWarningBg: Color(0xFF2A1F08),
    bannerErrorBg:   Color(0xFF2A0D0D),
    rankCardBg:      Color(0xFF1A3460),
    categoryItemBg:  Color(0xFF1E3A5F),
    questionCardBg:  Color(0xFF1A2744),
    correctAnswerBg: Color(0xFF0D2218),
    wrongAnswerBg:   Color(0xFF2A0D0D),
    offlineBannerBg: Color(0xFF2A1F08),
    avatarBg:        Color(0xFF1E3A5F),
    statCardBg:      Color(0xFF1A2744),
  );

  @override
  AppAdaptiveColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? inputBg,
    Color? sidebarBg,
    Color? bottomNavBg,
    Color? dividerColor,
    Color? primaryText,
    Color? secondaryText,
    Color? hintText,
    Color? borderColor,
    Color? chipBg,
    Color? chipSelectedBg,
    Color? bannerInfoBg,
    Color? bannerSuccessBg,
    Color? bannerWarningBg,
    Color? bannerErrorBg,
    Color? rankCardBg,
    Color? categoryItemBg,
    Color? questionCardBg,
    Color? correctAnswerBg,
    Color? wrongAnswerBg,
    Color? offlineBannerBg,
    Color? avatarBg,
    Color? statCardBg,
  }) {
    return AppAdaptiveColors(
      scaffoldBg:      scaffoldBg      ?? this.scaffoldBg,
      cardBg:          cardBg          ?? this.cardBg,
      inputBg:         inputBg         ?? this.inputBg,
      sidebarBg:       sidebarBg       ?? this.sidebarBg,
      bottomNavBg:     bottomNavBg     ?? this.bottomNavBg,
      dividerColor:    dividerColor    ?? this.dividerColor,
      primaryText:     primaryText     ?? this.primaryText,
      secondaryText:   secondaryText   ?? this.secondaryText,
      hintText:        hintText        ?? this.hintText,
      borderColor:     borderColor     ?? this.borderColor,
      chipBg:          chipBg          ?? this.chipBg,
      chipSelectedBg:  chipSelectedBg  ?? this.chipSelectedBg,
      bannerInfoBg:    bannerInfoBg    ?? this.bannerInfoBg,
      bannerSuccessBg: bannerSuccessBg ?? this.bannerSuccessBg,
      bannerWarningBg: bannerWarningBg ?? this.bannerWarningBg,
      bannerErrorBg:   bannerErrorBg   ?? this.bannerErrorBg,
      rankCardBg:      rankCardBg      ?? this.rankCardBg,
      categoryItemBg:  categoryItemBg  ?? this.categoryItemBg,
      questionCardBg:  questionCardBg  ?? this.questionCardBg,
      correctAnswerBg: correctAnswerBg ?? this.correctAnswerBg,
      wrongAnswerBg:   wrongAnswerBg   ?? this.wrongAnswerBg,
      offlineBannerBg: offlineBannerBg ?? this.offlineBannerBg,
      avatarBg:        avatarBg        ?? this.avatarBg,
      statCardBg:      statCardBg      ?? this.statCardBg,
    );
  }

  @override
  AppAdaptiveColors lerp(AppAdaptiveColors? other, double t) {
    if (other == null) return this;
    return AppAdaptiveColors(
      scaffoldBg:      Color.lerp(scaffoldBg,      other.scaffoldBg,      t)!,
      cardBg:          Color.lerp(cardBg,          other.cardBg,          t)!,
      inputBg:         Color.lerp(inputBg,         other.inputBg,         t)!,
      sidebarBg:       Color.lerp(sidebarBg,       other.sidebarBg,       t)!,
      bottomNavBg:     Color.lerp(bottomNavBg,     other.bottomNavBg,     t)!,
      dividerColor:    Color.lerp(dividerColor,    other.dividerColor,    t)!,
      primaryText:     Color.lerp(primaryText,     other.primaryText,     t)!,
      secondaryText:   Color.lerp(secondaryText,   other.secondaryText,   t)!,
      hintText:        Color.lerp(hintText,        other.hintText,        t)!,
      borderColor:     Color.lerp(borderColor,     other.borderColor,     t)!,
      chipBg:          Color.lerp(chipBg,          other.chipBg,          t)!,
      chipSelectedBg:  Color.lerp(chipSelectedBg,  other.chipSelectedBg,  t)!,
      bannerInfoBg:    Color.lerp(bannerInfoBg,    other.bannerInfoBg,    t)!,
      bannerSuccessBg: Color.lerp(bannerSuccessBg, other.bannerSuccessBg, t)!,
      bannerWarningBg: Color.lerp(bannerWarningBg, other.bannerWarningBg, t)!,
      bannerErrorBg:   Color.lerp(bannerErrorBg,   other.bannerErrorBg,   t)!,
      rankCardBg:      Color.lerp(rankCardBg,      other.rankCardBg,      t)!,
      categoryItemBg:  Color.lerp(categoryItemBg,  other.categoryItemBg,  t)!,
      questionCardBg:  Color.lerp(questionCardBg,  other.questionCardBg,  t)!,
      correctAnswerBg: Color.lerp(correctAnswerBg, other.correctAnswerBg, t)!,
      wrongAnswerBg:   Color.lerp(wrongAnswerBg,   other.wrongAnswerBg,   t)!,
      offlineBannerBg: Color.lerp(offlineBannerBg, other.offlineBannerBg, t)!,
      avatarBg:        Color.lerp(avatarBg,        other.avatarBg,        t)!,
      statCardBg:      Color.lerp(statCardBg,      other.statCardBg,      t)!,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER EXTENSION — akses cepat dari BuildContext
// ══════════════════════════════════════════════════════════════════════════════

extension AppThemeX on BuildContext {
  /// Akses adaptive colors dari context.
  /// Contoh: `context.colors.cardBg`
  AppAdaptiveColors get colors =>
      Theme.of(this).extension<AppAdaptiveColors>() ??
      AppAdaptiveColors.light;

  /// Cek apakah mode gelap aktif.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}