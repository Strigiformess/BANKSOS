// lib/features/auth/screens/splash_screen.dart
// PIC: Seruni (SL) — Splash & Onboarding
// Tampilan sesuai mockup Figma, fully pakai AppColors/AppTextStyles/AppSpacings/AppRadius

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Isi konten tiap halaman onboarding
  final List<String> _subtitles = [
    'Belajar Cerdas, Kumpulkan Poin, Buka\nSoal Premium',
    'Kerjakan soal kapan saja, bahkan\ntanpa koneksi internet.',
    'Berkontribusi soal dan bantu\nteman-teman belajar bersama.',
  ];

  @override
  void initState() {
    super.initState();
    // Kalau user sudah pernah login, lewati onboarding langsung ke dashboard
    _checkSession();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Tampilkan splash minimal 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = SessionService.instance;
    if (session.isLoggedIn) {
      _redirectByRole(session.role);
    }
    // Kalau belum login, biarkan di onboarding, user swipe sendiri
  }

  void _redirectByRole(String? role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardAdmin);
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardReviewer);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.shell);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _onNext() {
    if (_currentPage < _subtitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Konten Onboarding (swipeable) ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: _subtitles.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(subtitle: _subtitles[index]);
                },
              ),
            ),

            // ── Dot Indicator ────────────────────────────────────────────
            const SizedBox(height: AppSpacings.xxl),
            _buildDots(),
            const SizedBox(height: AppSpacings.xxxl),

            // ── Tombol: Lanjut / Mulai ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacings.xl),
              child: ElevatedButton(
                onPressed: _onNext,
                child: Text(
                  _currentPage < _subtitles.length - 1
                      ? 'Lanjut'
                      : 'Mulai',
                ),
              ),
            ),

            // ── Skip ─────────────────────────────────────────────────────
            TextButton(
              onPressed: _goToLogin,
              child: Text(
                'Lewati',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ),

            const SizedBox(height: AppSpacings.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _subtitles.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacings.xs),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            // Pakai AppColors dari app_theme.dart
            color: _currentPage == index
                ? AppColors.primaryBlue
                : AppColors.primaryBlue.withOpacity(0.25),
            borderRadius: AppRadius.pill,
          ),
        ),
      ),
    );
  }
}

// ─── Halaman Onboarding ───────────────────────────────────────────────────

class _OnboardingPage extends StatefulWidget {
  final String subtitle;

  const _OnboardingPage({required this.subtitle});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: AppSpacings.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo BS ────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  // Pakai AppColors.primaryBlue dari app_theme.dart
                  color: AppColors.primaryBlue,
                  // Pakai AppRadius.xl dari app_theme.dart
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

              // ── App Name ───────────────────────────────────────────────
              Text(
                'BANKSOS',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28,
                  color: AppColors.primaryBlue,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: AppSpacings.lg),

              // ── Subtitle ───────────────────────────────────────────────
              Text(
                widget.subtitle,
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