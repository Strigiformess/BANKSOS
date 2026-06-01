// lib/core/theme/app_theme.dart
// PIC: Seruni Libertina Islami & Revaldi Ardhi
// Sprint 1: Setup tema dasar, warna, tipografi, spacing
// Sprint 3: Penambahan warna status & badge
// Sprint 6: Integrasi AppAdaptiveColors ke lightTheme & darkTheme
//
// FILE INI ADALAH SUMBER KEBENARAN TUNGGAL UNTUK:
//   - Warna statis (AppColors)
//   - Tipografi (AppTextStyles)
//   - Spacing & radius (AppSpacings, AppRadius)
//   - Dekorasi box (AppDecorations)
//   - Badge style helper (AppBadgeStyle)
//   - ThemeData light & dark (AppTheme)
//
// ATURAN PENGGUNAAN:
//   - Warna TIDAK berubah antar mode → pakai AppColors.*
//   - Warna BERUBAH antar mode       → pakai context.colors.* (AppAdaptiveColors)

import 'package:flutter/material.dart';
import 'app_theme_extensions.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1. WARNA STATIK
// ══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Brand
  static const Color primaryBlue   = Color(0xFF1F5C99);
  static const Color accentBlue    = Color(0xFF2E7DD1);
  static const Color lightBlue     = Color(0xFFD6E8F7);
  static const Color bgBlue        = Color(0xFFEBF4FD);

  // Background
  static const Color bgLight       = Color(0xFFF5F8FC);
  static const Color bgWhite       = Color(0xFFFFFFFF);
  static const Color bgDark        = Color(0xFF0D1B2A);
  static const Color bgCardDark    = Color(0xFF1A2744);

  // Text
  static const Color textDark      = Color(0xFF1A1A2E);
  static const Color textGrey      = Color(0xFF6B7280);
  static const Color textLight     = Color(0xFFFFFFFF);

  // Border
  static const Color borderGrey    = Color(0xFFD1D5DB);
  static const Color borderFocus   = primaryBlue;

  // Semantic
  static const Color successGreen  = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed      = Color(0xFFEF4444);
  static const Color infoBlue      = primaryBlue;
  static const Color purple        = Color(0xFF8B5CF6);
  static const Color orange        = Color(0xFFF97316);

  // Difficulty — Easy
  static const Color easyGreen     = Color(0xFF22C55E);
  static const Color easyBg        = Color(0xFFDCFCE7);
  static const Color easyText      = Color(0xFF166534);

  // Difficulty — Medium
  static const Color mediumAmber   = Color(0xFFF59E0B);
  static const Color mediumBg      = Color(0xFFFEF9C3);
  static const Color mediumText    = Color(0xFF854D0E);

  // Difficulty — Hard
  static const Color hardRed       = Color(0xFFEF4444);
  static const Color hardBg        = Color(0xFFFEE2E2);
  static const Color hardText      = Color(0xFF991B1B);

  // Status badge
  static const Color pendingBg     = Color(0xFFFEF3C7);
  static const Color pendingText   = Color(0xFF92400E);
  static const Color publishedBg   = Color(0xFFD1FAE5);
  static const Color publishedText = Color(0xFF065F46);
  static const Color rejectedBg    = Color(0xFFFEE2E2);
  static const Color rejectedText  = Color(0xFF991B1B);
  static const Color archivedBg    = Color(0xFFF3F4F6);
  static const Color archivedText  = Color(0xFF374151);
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. TIPOGRAFI
// ══════════════════════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  // Heading
  static const TextStyle h1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.3);
  static const TextStyle h2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.35);
  static const TextStyle h3 = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.4);

  // Body
  static const TextStyle bodyLarge    = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark, height: 1.5);
  static const TextStyle body         = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark, height: 1.5);
  static const TextStyle bodySemibold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static const TextStyle bodyPrimary  = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryBlue);
  static const TextStyle bodyOnPrimary = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLight);
  static const TextStyle bodyError    = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.errorRed);

  // Small / Caption
  static const TextStyle small         = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textGrey, height: 1.4);
  static const TextStyle smallSemibold = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey);
  static const TextStyle caption       = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textGrey, height: 1.4);
  static const TextStyle captionBold   = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.3);

  // Button
  static const TextStyle button      = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.3);
  static const TextStyle buttonSmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight);

  // Special
  static const TextStyle answerPlaceholder = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textGrey, letterSpacing: 2.0);
  static const TextStyle appBarTitle       = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 1.5);
  static const TextStyle navLabel          = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. SPACING & RADIUS
// ══════════════════════════════════════════════════════════════════════════════

class AppSpacings {
  AppSpacings._();

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;

  static const EdgeInsets pagePadding     = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding     = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

class AppRadius {
  AppRadius._();

  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 12.0;
  static const double xl   = 16.0;
  static const double full = 99.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill  = BorderRadius.all(Radius.circular(full));
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. DEKORASI BOX STATIK
// ══════════════════════════════════════════════════════════════════════════════

class AppDecorations {
  AppDecorations._();

  static const BoxDecoration card = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.lgAll,
    border: Border.fromBorderSide(BorderSide(color: AppColors.borderGrey, width: 0.5)),
  );

  static BoxDecoration cardElevated = const BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.lgAll,
    boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
  );

  static const BoxDecoration input = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(BorderSide(color: AppColors.borderGrey)),
  );

  static const BoxDecoration inputFocused = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(BorderSide(color: AppColors.primaryBlue, width: 2)),
  );

  // Banner Info
  static const BoxDecoration bannerInfo = BoxDecoration(
    color: Color(0xFFEFF6FF),
    border: Border(left: BorderSide(color: AppColors.primaryBlue, width: 3)),
    borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
  );

  static const BoxDecoration bannerSuccess = BoxDecoration(
    color: Color(0xFFF0FDF4),
    border: Border(left: BorderSide(color: AppColors.successGreen, width: 3)),
    borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
  );

  static const BoxDecoration bannerWarning = BoxDecoration(
    color: Color(0xFFFFFBEB),
    border: Border(left: BorderSide(color: AppColors.warningYellow, width: 3)),
    borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
  );

  static const BoxDecoration bannerError = BoxDecoration(
    color: Color(0xFFFEF2F2),
    border: Border(left: BorderSide(color: AppColors.errorRed, width: 3)),
    borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
  );

  static const BoxDecoration highlightBlue = BoxDecoration(
    color: AppColors.bgBlue,
    borderRadius: AppRadius.mdAll,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. BADGE STYLE HELPER
// ══════════════════════════════════════════════════════════════════════════════

class AppBadgeStyle {
  AppBadgeStyle._();

  static ({Color bg, Color text}) difficulty(String level) {
    switch (level.toLowerCase()) {
      case 'easy':   return (bg: AppColors.easyBg,    text: AppColors.easyText);
      case 'medium': return (bg: AppColors.mediumBg,  text: AppColors.mediumText);
      case 'hard':   return (bg: AppColors.hardBg,    text: AppColors.hardText);
      default:       return (bg: AppColors.archivedBg, text: AppColors.archivedText);
    }
  }

  static ({Color bg, Color text}) questionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return (bg: AppColors.pendingBg,   text: AppColors.pendingText);
      case 'published': return (bg: AppColors.publishedBg, text: AppColors.publishedText);
      case 'rejected':  return (bg: AppColors.rejectedBg,  text: AppColors.rejectedText);
      default:          return (bg: AppColors.archivedBg,  text: AppColors.archivedText);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. THEME DATA
// ══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.lightBlue,
        error: AppColors.errorRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,

      extensions: const <ThemeExtension<dynamic>>[
        AppAdaptiveColors.light,
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: AppColors.textLight),
        actionsIconTheme: IconThemeData(color: AppColors.textLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.borderGrey,
          disabledForegroundColor: Colors.white60,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primaryBlue),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTextStyles.bodyPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.borderGrey)),
        enabledBorder:      const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.borderGrey)),
        focusedBorder:      const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.primaryBlue, width: 2)),
        errorBorder:        const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.errorRed)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.errorRed, width: 2)),
        errorStyle: AppTextStyles.bodyError,
        hintStyle:  AppTextStyles.body.copyWith(color: AppColors.textGrey.withValues(alpha:0.6)),
        labelStyle: AppTextStyles.small.copyWith(color: AppColors.textGrey),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.bgWhite,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.borderGrey, width: 0.5),
        ),
        margin: EdgeInsets.symmetric(vertical: 4),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgWhite,
        selectedColor: AppColors.lightBlue,
        checkmarkColor: AppColors.primaryBlue,
        labelStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: const BorderSide(color: AppColors.borderGrey),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderGrey,
        thickness: 0.5,
        space: 0,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGrey,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF4A90D9);
    const darkBg      = Color(0xFF0D1B2A);
    const darkCard    = Color(0xFF1A2744);
    const darkBorder  = Color(0xFF2D3748);
    const darkText    = Color(0xFFE8EDF5);
    const darkSubtext = Color(0xFF8A9BB0);
    const darkInput   = Color(0xFF1E2E45);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: const Color(0xFF1E3A5F),
        error: AppColors.errorRed,
        surface: darkCard,
      ),
      scaffoldBackgroundColor: darkBg,

      extensions: const <ThemeExtension<dynamic>>[
        AppAdaptiveColors.dark,
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: darkText),
        actionsIconTheme: IconThemeData(color: darkText),
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: darkBorder,
          disabledForegroundColor: Colors.white30,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: AppTextStyles.bodyPrimary.copyWith(color: darkPrimary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: darkBorder)),
        enabledBorder:      const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: darkBorder)),
        focusedBorder:      const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: darkPrimary, width: 2)),
        errorBorder:        const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.errorRed)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.errorRed, width: 2)),
        errorStyle: AppTextStyles.bodyError,
        hintStyle:  AppTextStyles.body.copyWith(color: darkSubtext),
        labelStyle: AppTextStyles.small.copyWith(color: darkSubtext),
        prefixIconColor: darkSubtext,
        suffixIconColor: darkSubtext,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: darkBorder, width: 0.5),
        ),
        margin: EdgeInsets.symmetric(vertical: 4),
        surfaceTintColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: const Color(0xFF1E3A5F),
        checkmarkColor: darkPrimary,
        labelStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w500, color: darkText),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: const BorderSide(color: darkBorder),
      ),

      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 0.5, space: 0),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkSubtext,
        selectedLabelStyle: AppTextStyles.navLabel.copyWith(color: darkPrimary),
        unselectedLabelStyle: AppTextStyles.navLabel.copyWith(color: darkSubtext),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF263550),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentTextStyle: AppTextStyles.body.copyWith(color: darkText),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: darkText,
        iconColor: darkSubtext,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: AppTextStyles.h2.copyWith(color: darkText),
        contentTextStyle: AppTextStyles.body.copyWith(color: darkSubtext),
      ),

      iconTheme: const IconThemeData(color: darkSubtext),
      primaryIconTheme: const IconThemeData(color: darkText),
    );
  }

  // ─── Alias backward-compatibility ─────────────────────────────────────────
  // Dipertahankan agar tidak ada perubahan di file lain
  static const Color primaryBlue   = AppColors.primaryBlue;
  static const Color lightBlue     = AppColors.lightBlue;
  static const Color bgLight       = AppColors.bgLight;
  static const Color textDark      = AppColors.textDark;
  static const Color textGrey      = AppColors.textGrey;
  static const Color borderGrey    = AppColors.borderGrey;
  static const Color errorRed      = AppColors.errorRed;
  static const Color successGreen  = AppColors.successGreen;
  static const Color warningYellow = AppColors.warningYellow;
  static const Color easyGreen     = AppColors.easyGreen;
  static const Color mediumYellow  = AppColors.mediumAmber;
  static const Color hardRed       = AppColors.hardRed;
}

