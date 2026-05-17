// lib/features/auth/screens/login_screen.dart
// PIC: Seruni (SL) — UI Layer
// Tampilan sesuai mockup Figma, fully pakai AppColors/AppTextStyles/AppSpacings/AppRadius

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final role = await ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (role != null && mounted) _navigateByRole(role);
  }

  void _navigateByRole(String role) {
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

  void _goToRegister() {
    ref.read(authControllerProvider.notifier).clearError();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacings.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacings.lg),

                // ── Tab Toggle: Login | Register ──────────────────────────
                _buildTabToggle(),

                const SizedBox(height: AppSpacings.xxxl),

                // ── Header ────────────────────────────────────────────────
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 26,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacings.sm),
                Text(
                  'Log in to continue your academic journey.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),

                const SizedBox(height: AppSpacings.xxxl),

                // ── Error Banner ──────────────────────────────────────────
                if (authState.errorMessage != null) ...[
                  AppMessageBanner(
                    type: BannerType.error,
                    message: authState.errorMessage!,
                  ),
                  const SizedBox(height: AppSpacings.lg),
                ],

                // ── Email Address ─────────────────────────────────────────
                Text(
                  'Email Address',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacings.xs),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'name@university.ac.id',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    final emailRegex =
                        RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacings.lg),

                // ── Password label + Forgot ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: forgot password
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacings.xs),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLogin(),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacings.xxl),

                // ── Tombol Masuk ──────────────────────────────────────────
                // Pakai ElevatedButton dari AppTheme.lightTheme (auto-styled)
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _onLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Masuk'),
                ),

                const SizedBox(height: AppSpacings.xl),

                // ── Divider: or continue with ─────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacings.md),
                      child: Text(
                        'or continue with',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppSpacings.lg),

                // ── Google Button ─────────────────────────────────────────
                // Pakai OutlinedButton dari AppTheme.lightTheme (auto-styled)
                OutlinedButton(
                  onPressed: () {
                    // TODO: Google Sign In
                  },
                  // Override foreground color agar teks tetap gelap
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(
                        color: AppColors.borderGrey, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleIcon(),
                      const SizedBox(width: AppSpacings.sm),
                      Text(
                        'Google Account',
                        style: AppTextStyles.bodySemibold.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacings.xxl),

                // ── Link Register ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey),
                    ),
                    GestureDetector(
                      onTap: _goToRegister,
                      child: Text(
                        'Daftar sekarang',
                        style: AppTextStyles.bodyPrimary.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacings.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tab Toggle ───────────────────────────────────────────────────────────

  Widget _buildTabToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        // Pakai warna dari AppColors
        color: AppColors.borderGrey.withOpacity(0.35),
        borderRadius: AppRadius.pill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Tab Login — aktif
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: Text(
                'Login',
                style: AppTextStyles.bodySemibold.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
          // Tab Register — tidak aktif
          Expanded(
            child: GestureDetector(
              onTap: _goToRegister,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Register',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Icon ──────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}