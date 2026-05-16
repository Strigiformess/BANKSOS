// lib/core/theme/app_theme.dart
//
// BANKSOS Design System — Theme utama
// Gunakan AppTheme.lightTheme / darkTheme di MaterialApp
// Gunakan AppColors.* untuk warna langsung di widget
// Gunakan AppTextStyles.* untuk teks
// Gunakan AppSpacings.* untuk padding/gap
// Gunakan AppDecorations.* untuk BoxDecoration siap pakai

import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WARNA — sesuai Figma mockup
// ══════════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ─── Biru utama ───────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF1F5C99); // tombol, appbar, link
  static const Color accentBlue    = Color(0xFF2E7DD1); // hover, highlight
  static const Color lightBlue     = Color(0xFFD6E8F7); // chip bg, avatar bg
  static const Color bgBlue        = Color(0xFFEBF4FD); // section bg ringan

  // ─── Background ──────────────────────────────────────────────────────────
  static const Color bgLight       = Color(0xFFF5F8FC); // scaffold background
  static const Color bgWhite       = Color(0xFFFFFFFF); // card, input
  static const Color bgDark        = Color(0xFF0D1B2A); // dark scaffold
  static const Color bgCardDark    = Color(0xFF1A2744); // dark card

  // ─── Teks ─────────────────────────────────────────────────────────────────
  static const Color textDark      = Color(0xFF1A1A2E); // heading
  static const Color textGrey      = Color(0xFF6B7280); // placeholder, subtitle
  static const Color textLight     = Color(0xFFFFFFFF); // teks di atas biru

  // ─── Border ──────────────────────────────────────────────────────────────
  static const Color borderGrey    = Color(0xFFD1D5DB); // border input/card normal
  static const Color borderFocus   = primaryBlue;        // border saat fokus

  // ─── Semantik ─────────────────────────────────────────────────────────────
  static const Color successGreen  = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed      = Color(0xFFEF4444);
  static const Color infoBlue      = primaryBlue;
  static const Color purple        = Color(0xFF8B5CF6); // streak, premium
  static const Color orange        = Color(0xFFF97316); // notif, fire icon

  // ─── Badge kesulitan soal ─────────────────────────────────────────────────
  static const Color easyGreen     = Color(0xFF22C55E);
  static const Color easyBg        = Color(0xFFDCFCE7);
  static const Color easyText      = Color(0xFF166534);

  static const Color mediumAmber   = Color(0xFFF59E0B);
  static const Color mediumBg      = Color(0xFFFEF9C3);
  static const Color mediumText    = Color(0xFF854D0E);

  static const Color hardRed       = Color(0xFFEF4444);
  static const Color hardBg        = Color(0xFFFEE2E2);
  static const Color hardText      = Color(0xFF991B1B);

  // ─── Badge status soal ────────────────────────────────────────────────────
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
// TIPOGRAFI — konsisten di seluruh app
// ══════════════════════════════════════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._();

  // ─── Heading ──────────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.35,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle bodySemibold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // ─── Small / Label ────────────────────────────────────────────────────────
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.4,
  );

  static const TextStyle smallSemibold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textGrey,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.4,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textGrey,
    letterSpacing: 0.3,
  );

  // ─── Varian warna khusus ──────────────────────────────────────────────────
  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue,
  );

  static const TextStyle bodyOnPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  static const TextStyle bodyError = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.errorRed,
  );

  // ─── Tombol ───────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  // ─── Placeholder jawaban ──────────────────────────────────────────────────
  static const TextStyle answerPlaceholder = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 2.0,
  );

  // ─── AppBar title ─────────────────────────────────────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    letterSpacing: 1.5,
  );

  // ─── Navigation bar label ─────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SPACING — jangan hardcode angka di widget, pakai ini
// ══════════════════════════════════════════════════════════════════════════════
class AppSpacings {
  AppSpacings._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Padding standar halaman
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  // Padding card
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  // Padding list item
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// BORDER RADIUS
// ══════════════════════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 12.0;
  static const double xl   = 16.0;
  static const double full = 99.0; // pill / circle

  static const BorderRadius smAll  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll  = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill   = BorderRadius.all(Radius.circular(full));
}

// ══════════════════════════════════════════════════════════════════════════════
// DEKORASI SIAP PAKAI — tinggal pakai di Container/decoration
// ══════════════════════════════════════════════════════════════════════════════
class AppDecorations {
  AppDecorations._();

  // ─── Card standar ─────────────────────────────────────────────────────────
  static const BoxDecoration card = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.lgAll,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.borderGrey, width: 0.5),
    ),
  );

  // ─── Card dengan shadow ringan ────────────────────────────────────────────
  static BoxDecoration cardElevated = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.lgAll,
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // ─── Input normal ─────────────────────────────────────────────────────────
  static const BoxDecoration input = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.borderGrey),
    ),
  );

  // ─── Input fokus ──────────────────────────────────────────────────────────
  static const BoxDecoration inputFocused = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
  );

  // ─── Input error ──────────────────────────────────────────────────────────
  static const BoxDecoration inputError = BoxDecoration(
    color: AppColors.bgWhite,
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.errorRed),
    ),
  );

  // ─── Banner info ──────────────────────────────────────────────────────────
  static const BoxDecoration bannerInfo = BoxDecoration(
    color: Color(0xFFEFF6FF),
    border: Border(left: BorderSide(color: AppColors.primaryBlue, width: 3)),
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
  );

  static const BoxDecoration bannerSuccess = BoxDecoration(
    color: Color(0xFFF0FDF4),
    border: Border(left: BorderSide(color: AppColors.successGreen, width: 3)),
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
  );

  static const BoxDecoration bannerWarning = BoxDecoration(
    color: Color(0xFFFFFBEB),
    border: Border(left: BorderSide(color: AppColors.warningYellow, width: 3)),
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
  );

  static const BoxDecoration bannerError = BoxDecoration(
    color: Color(0xFFFEF2F2),
    border: Border(left: BorderSide(color: AppColors.errorRed, width: 3)),
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
  );

  // ─── Highlight biru muda (soal terpilih, item aktif) ─────────────────────
  static const BoxDecoration highlightBlue = BoxDecoration(
    color: AppColors.bgBlue,
    borderRadius: AppRadius.mdAll,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER BADGE — warna badge berdasarkan data
// ══════════════════════════════════════════════════════════════════════════════
class AppBadgeStyle {
  AppBadgeStyle._();

  // Kembalikan warna bg & text untuk badge kesulitan soal
  static ({Color bg, Color text}) difficulty(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return (bg: AppColors.easyBg, text: AppColors.easyText);
      case 'medium':
        return (bg: AppColors.mediumBg, text: AppColors.mediumText);
      case 'hard':
        return (bg: AppColors.hardBg, text: AppColors.hardText);
      default:
        return (bg: AppColors.archivedBg, text: AppColors.archivedText);
    }
  }

  // Kembalikan warna bg & text untuk badge status soal
  static ({Color bg, Color text}) questionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (bg: AppColors.pendingBg, text: AppColors.pendingText);
      case 'published':
        return (bg: AppColors.publishedBg, text: AppColors.publishedText);
      case 'rejected':
        return (bg: AppColors.rejectedBg, text: AppColors.rejectedText);
      case 'archived':
      case 'inactive':
      default:
        return (bg: AppColors.archivedBg, text: AppColors.archivedText);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME DATA — pakai di MaterialApp
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

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: AppColors.textLight),
        actionsIconTheme: IconThemeData(color: AppColors.textLight),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.borderGrey,
          disabledForegroundColor: Colors.white60,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primaryBlue),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTextStyles.bodyPrimary,
        ),
      ),

      // ── Input ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        errorStyle: AppTextStyles.bodyError,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textGrey.withOpacity(0.6)),
        labelStyle: AppTextStyles.small.copyWith(color: AppColors.textGrey),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgWhite,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: AppColors.borderGrey, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // ── Chip (FilterChip) ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgWhite,
        selectedColor: AppColors.lightBlue,
        checkmarkColor: AppColors.primaryBlue,
        labelStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: const BorderSide(color: AppColors.borderGrey),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGrey,
        thickness: 0.5,
        space: 0,
      ),

      // ── BottomNavigationBar ──────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGrey,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: const Color(0xFF4A90D9),
        secondary: AppColors.lightBlue,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1B2A),
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: Color(0xFF2D3748), width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1B2A),
        selectedItemColor: Color(0xFF4A90D9),
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ─── Warna (alias untuk backward-compatibility dengan kode lama) ──────────
  static const Color primaryBlue    = AppColors.primaryBlue;
  static const Color lightBlue      = AppColors.lightBlue;
  static const Color bgLight        = AppColors.bgLight;
  static const Color textDark       = AppColors.textDark;
  static const Color textGrey       = AppColors.textGrey;
  static const Color borderGrey     = AppColors.borderGrey;
  static const Color errorRed       = AppColors.errorRed;
  static const Color successGreen   = AppColors.successGreen;
  static const Color warningYellow  = AppColors.warningYellow;
  static const Color easyGreen      = AppColors.easyGreen;
  static const Color mediumYellow   = AppColors.mediumAmber;
  static const Color hardRed        = AppColors.hardRed;
}