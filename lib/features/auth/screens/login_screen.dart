// // lib/features/auth/screens/login_screen.dart
// // PIC: Seruni Libertina Islami
// // Sprint 1: Halaman login "Login & Registration"
// //
// // FITUR:
// //   - Tab toggle Login | Register
// //   - Form email & password dengan validasi real-time
// //   - Tombol "Masuk" dengan loading state
// //   - Tombol Google Account (placeholder)
// //   - Link ke halaman register
// //   - Error banner dari controller
// //   - Redirect otomatis ke dashboard sesuai role setelah login

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
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool  _obscurePass    = true;

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
                _buildTabToggle(),
                const SizedBox(height: AppSpacings.xxxl),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 26,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacings.sm),
                Text(
                  'Log in to continue your academic journey.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
                ),
                const SizedBox(height: AppSpacings.xxxl),

                if (authState.errorMessage != null) ...[
                  AppMessageBanner(
                    type: BannerType.error,
                    message: authState.errorMessage!,
                  ),
                  const SizedBox(height: AppSpacings.lg),
                ],

                _buildFieldLabel('Email Address'),
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacings.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Password'),
                    GestureDetector(
                      onTap: () {},
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
                  obscureText: _obscurePass,
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
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
                    if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacings.xxl),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _onLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: AppSpacings.xl),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacings.md),
                      child: Text('or continue with', style: AppTextStyles.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacings.lg),

                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.borderGrey),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
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

  Widget _buildTabToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.borderGrey.withValues(alpha: 0.35),
        borderRadius: AppRadius.pill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
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
          Expanded(
            child: GestureDetector(
              onTap: _goToRegister,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Register',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.small.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Google Icon Placeholder ──────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle( // FIX: Menggunakan Const secara otomatis karena block const sebelumnya
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}