// lib/features/auth/screens/splash_screen.dart
// PIC: Seruni Libertina Islami (SL)
// Sprint 1: Splash screen & onboarding sesuai Figma
//
// ALUR:
//   1. Tampilkan splash (logo + nama app) minimal 2 detik
//   2. Cek sesi login → jika ada, redirect ke dashboard sesuai role
//   3. Jika belum login → tampilkan onboarding (swipeable PageView)
//   4. Onboarding selesai → navigasi ke halaman Login

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ────────────────────────────────────────────────────────────────
  bool _showOnboarding = false;
  int _currentPage     = 0;
  final PageController _pageController = PageController();

  // ─── Konten Onboarding (sesuai Figma) ────────────────────────────────────
  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'BANKSOS',
      subtitle: 'Belajar Cerdas, Kumpulkan Poin,\nBuka Soal Premium',
    ),
    _OnboardingData(
      title: 'Offline First',
      subtitle: 'Kerjakan soal kapan saja,\nbahkan tanpa koneksi internet.',
    ),
    _OnboardingData(
      title: 'Kontribusi',
      subtitle: 'Ajukan soal dan bantu\nteman-teman belajar bersama.',
    ),
  ];

  // ─── Animasi splash ───────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _initSplash();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Logika Splash ────────────────────────────────────────────────────────

  Future<void> _initSplash() async {
    // Tampilkan splash minimal 2 detik
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final session = SessionService.instance;

    if (session.isLoggedIn) {
      _redirectByRole(session.role);
    } else {
      // Tampilkan onboarding
      if (mounted) setState(() => _showOnboarding = true);
    }
  }

  void _redirectByRole(String? role) {
    if (!mounted) return;
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardAdmin);
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardReviewer);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardMahasiswa);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: _showOnboarding ? _buildOnboarding() : _buildSplash(),
    );
  }

  // ─── Widget: Splash Screen ────────────────────────────────────────────────
  // Sesuai halaman "Splash & Onboarding" di Figma

  Widget _buildSplash() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo BS
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: AppRadius.xlAll,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'BS',
                  style: AppTextStyles.appBarTitle.copyWith(
                    fontSize: 32,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacings.xxl),

            // Nama Aplikasi
            Text(
              'BANKSOS',
              style: AppTextStyles.h1.copyWith(
                fontSize: 28,
                color: AppColors.primaryBlue,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacings.sm),

            // Tagline sesuai Figma
            Text(
              'Belajar Cerdas, Kumpulkan Poin, Buka\nSoal Premium',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGrey,
                height: 1.6,
              ),
            ),

            const SizedBox(height: AppSpacings.xxxl),

            // Dots loading indicator
            const _LoadingDots(),
          ],
        ),
      ),
    );
  }

  // ─── Widget: Onboarding ───────────────────────────────────────────────────

  Widget _buildOnboarding() {
    return SafeArea(
      child: Column(
        children: [
          // PageView konten
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
            ),
          ),

          // Dot indicator
          const SizedBox(height: AppSpacings.lg),
          _buildDots(),
          const SizedBox(height: AppSpacings.xxxl),

          // Tombol Lanjut / Mulai
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacings.xl),
            child: ElevatedButton(
              onPressed: _onNext,
              child: Text(
                _currentPage < _pages.length - 1 ? 'Lanjut' : 'Mulai',
              ),
            ),
          ),

          // Tombol Skip
          TextButton(
            onPressed: _goToLogin,
            child: Text(
              'Lewati',
              style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
            ),
          ),

          const SizedBox(height: AppSpacings.lg),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacings.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue
                : AppColors.primaryBlue.withOpacity(0.25),
            borderRadius: AppRadius.pill,
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET PENDUKUNG
// ══════════════════════════════════════════════════════════════════════════════

/// Data model satu halaman onboarding.
class _OnboardingData {
  final String title;
  final String subtitle;
  const _OnboardingData({required this.title, required this.subtitle});
}

/// Satu halaman onboarding dengan animasi fade + slide.
class _OnboardingPage extends StatefulWidget {
  final _OnboardingData data;
  const _OnboardingPage({super.key, required this.data});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: AppSpacings.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: AppRadius.xlAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'BS',
                    style: AppTextStyles.appBarTitle.copyWith(
                      fontSize: 30,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacings.xxxl),

              Text(
                widget.data.title,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  color: AppColors.primaryBlue,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: AppSpacings.lg),

              Text(
                widget.data.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiga titik animasi loading untuk splash screen.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Tiap dot punya delay berbeda
            final delay  = i / 3.0;
            final value  = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}