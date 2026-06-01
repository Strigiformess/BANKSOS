// lib/features/auth/screens/splash_screen.dart
// PIC: Seruni Libertina Islami
// Sprint 1: Pemisahan Logic Splash Screen Asli & Onboarding

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _showOnboarding = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // 1. Definisikan list halaman onboarding di sini agar bisa diakses secara global di dalam class
  final List<Map<String, String>> _onboardingPages = [
    {'title': 'BANKSOS', 'desc': 'Belajar Cerdas, Kumpulkan Poin,\nBuka Soal Premium'},
    {'title': 'Offline First', 'desc': 'Kerjakan soal kapan saja,\nbahkan tanpa koneksi internet.'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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

  Future<void> _initSplash() async {
    // 2.5 Detik menampilkan Splash murni
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final session = SessionService.instance;
    if (session.isLoggedIn) {
      _redirectByRole(session.role);
    } else {
      // Mengubah state untuk trigger PageView Onboarding
      setState(() => _showOnboarding = true);
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
        Navigator.pushReplacementNamed(context, AppRoutes.shell);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  // 2. Gunakan _onboardingPages untuk menggantikan _subtitles yang error
  void _onNext() {
    if (_currentPage < _onboardingPages.length - 1) {
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
      body: _showOnboarding ? _buildOnboarding() : _buildSplash(),
    );
  }

  // ─── 1. Splash Screen Asli ──────────────────────────────────────────────
  Widget _buildSplash() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: AppRadius.xlAll,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withValues(alpha:0.3), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: Text('BS', style: AppTextStyles.h1.copyWith(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacings.xxl),
            Text('BANKSOS', style: AppTextStyles.h1.copyWith(fontSize: 32, color: AppColors.primaryBlue, letterSpacing: 5)),
            const SizedBox(height: AppSpacings.md),
            const CircularProgressIndicator(color: AppColors.primaryBlue), // Loading Murni
          ],
        ),
      ),
    );
  }

  // ─── 2. Onboarding Screen ───────────────────────────────────────────────
  Widget _buildOnboarding() {
    // Variabel lokal 'pages' di sini sudah dihapus dan digantikan oleh '_onboardingPages' di atas

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _onboardingPages.length,
              itemBuilder: (ctx, i) => Padding(
                padding: AppSpacings.pagePadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: AppRadius.xlAll),
                      alignment: Alignment.center,
                      child: Text('BS', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32)),
                    ),
                    const SizedBox(height: AppSpacings.xxxl),
                    Text(_onboardingPages[i]['title']!, style: AppTextStyles.h1.copyWith(color: AppColors.primaryBlue)),
                    const SizedBox(height: AppSpacings.lg),
                    Text(_onboardingPages[i]['desc']!, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textGrey, height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
          // Indikator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingPages.length, (i) {
              final active = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8, height: 8,
                decoration: BoxDecoration(color: active ? AppColors.primaryBlue : AppColors.lightBlue, borderRadius: AppRadius.pill),
              );
            }),
          ),
          const SizedBox(height: AppSpacings.xxxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacings.xl),
            child: ElevatedButton(
              onPressed: _onNext, // Gunakan langsung fungsi _onNext yang sudah diperbaiki agar logic tombol lebih rapi
              child: Text(_currentPage < _onboardingPages.length - 1 ? 'Lanjut' : 'Mulai Sekarang'),
            ),
          ),
          const SizedBox(height: AppSpacings.lg),
        ],
      ),
    );
  }
}