// lib/features/auth/screens/register_screen.dart
// PIC: Seruni Libertina Islami (SL)
// Sprint 1: Halaman registrasi sesuai Figma "Login & Registration"
//
// FITUR:
//   - Tab toggle Login | Register
//   - Form: Nama Lengkap, NIM, Email, Password, Konfirmasi Password
//   - Validasi real-time tiap field
//   - Tombol "Daftar" dinonaktifkan jika form belum valid
//   - Error banner dari controller
//   - Link kembali ke halaman Login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final _namaCtrl       = TextEditingController();
  final _nimCtrl        = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();

  // ─── State ────────────────────────────────────────────────────────────────
  bool _obscurePass      = true;
  bool _obscureKonfirmasi = true;

  String? _namaError;
  String? _nimError;
  String? _emailError;
  String? _passwordError;
  String? _konfirmasiError;

  bool get _isFormValid =>
      _namaError == null && _namaCtrl.text.isNotEmpty &&
      _nimError == null  && _nimCtrl.text.isNotEmpty &&
      _emailError == null && _emailCtrl.text.isNotEmpty &&
      _passwordError == null && _passwordCtrl.text.isNotEmpty &&
      _konfirmasiError == null && _konfirmasiCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  // ─── Validasi ─────────────────────────────────────────────────────────────

  void _validateNama(String v) {
    setState(() {
      if (v.trim().isEmpty)      _namaError = 'Nama lengkap tidak boleh kosong';
      else if (v.trim().length < 3) _namaError = 'Nama minimal 3 karakter';
      else                       _namaError = null;
    });
  }

  void _validateNim(String v) {
    setState(() {
      if (v.trim().isEmpty)                           _nimError = 'NIM tidak boleh kosong';
      else if (!RegExp(r'^\d{9}$').hasMatch(v.trim())) _nimError = 'NIM harus 9 digit angka';
      else                                            _nimError = null;
    });
  }

  void _validateEmail(String v) {
    setState(() {
      if (v.trim().isEmpty) {
        _emailError = 'Email tidak boleh kosong';
      } else if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v.trim())) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String v) {
    setState(() {
      if (v.isEmpty)          _passwordError = 'Kata sandi tidak boleh kosong';
      else if (v.length < 8)  _passwordError = 'Kata sandi minimal 8 karakter';
      else if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) {
        _passwordError = 'Harus mengandung huruf dan angka';
      } else {
        _passwordError = null;
      }
      // Validasi ulang konfirmasi jika sudah diisi
      if (_konfirmasiCtrl.text.isNotEmpty) {
        _validateKonfirmasi(_konfirmasiCtrl.text);
      }
    });
  }

  void _validateKonfirmasi(String v) {
    setState(() {
      if (v.isEmpty)                     _konfirmasiError = 'Konfirmasi tidak boleh kosong';
      else if (v != _passwordCtrl.text)  _konfirmasiError = 'Kata sandi tidak cocok';
      else                               _konfirmasiError = null;
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _onRegister() async {
    if (!_isFormValid) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          namaLengkap: _namaCtrl.text.trim(),
          nim: _nimCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan login.'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacings.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacings.lg),

              // ── Tab Toggle ───────────────────────────────────────────────
              _buildTabToggle(),

              const SizedBox(height: AppSpacings.xxxl),

              // ── Header ───────────────────────────────────────────────────
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacings.sm),
              Text(
                'Isi data diri kamu untuk mulai belajar bersama BANKSOS.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
              ),

              const SizedBox(height: AppSpacings.xxl),

              // ── Error Banner ─────────────────────────────────────────────
              if (authState.errorMessage != null) ...[
                AppMessageBanner(
                  type: BannerType.error,
                  message: authState.errorMessage!,
                ),
                const SizedBox(height: AppSpacings.lg),
              ],

              // ── Field: Nama Lengkap ──────────────────────────────────────
              _buildLabel('Nama Lengkap'),
              const SizedBox(height: AppSpacings.xs),
              _buildTextField(
                controller: _namaCtrl,
                hint: 'Masukkan nama lengkap kamu',
                icon: Icons.person_outline,
                errorText: _namaError,
                onChanged: _validateNama,
                action: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacings.md),

              // ── Field: NIM ───────────────────────────────────────────────
              _buildLabel('NIM'),
              const SizedBox(height: AppSpacings.xs),
              _buildTextField(
                controller: _nimCtrl,
                hint: '241511xxx',
                icon: Icons.badge_outlined,
                errorText: _nimError,
                onChanged: _validateNim,
                keyboardType: TextInputType.number,
                action: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacings.md),

              // ── Field: Email ─────────────────────────────────────────────
              _buildLabel('Email Address'),
              const SizedBox(height: AppSpacings.xs),
              _buildTextField(
                controller: _emailCtrl,
                hint: 'name@university.ac.id',
                icon: Icons.email_outlined,
                errorText: _emailError,
                onChanged: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                action: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacings.md),

              // ── Field: Password ──────────────────────────────────────────
              _buildLabel('Password'),
              const SizedBox(height: AppSpacings.xs),
              _buildPasswordField(
                controller: _passwordCtrl,
                hint: 'Min. 8 karakter, huruf + angka',
                errorText: _passwordError,
                obscure: _obscurePass,
                onChanged: _validatePassword,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                action: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacings.md),

              // ── Field: Konfirmasi Password ───────────────────────────────
              _buildLabel('Confirm Password'),
              const SizedBox(height: AppSpacings.xs),
              _buildPasswordField(
                controller: _konfirmasiCtrl,
                hint: 'Ulangi kata sandi kamu',
                errorText: _konfirmasiError,
                obscure: _obscureKonfirmasi,
                onChanged: _validateKonfirmasi,
                onToggle: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                action: TextInputAction.done,
                onSubmitted: (_) => _onRegister(),
              ),

              const SizedBox(height: AppSpacings.xxl),

              // ── Tombol Daftar ────────────────────────────────────────────
              ElevatedButton(
                onPressed: (!_isFormValid || authState.isLoading) ? null : _onRegister,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Daftar'),
              ),

              const SizedBox(height: AppSpacings.xxl),

              // ── Link Login ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(authControllerProvider.notifier).clearError();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Masuk',
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
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Widget _buildTabToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.borderGrey.withOpacity(0.35),
        borderRadius: AppRadius.pill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Tab Login — tidak aktif
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(authControllerProvider.notifier).clearError();
                Navigator.pop(context);
              },
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Login',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
                ),
              ),
            ),
          ),
          // Tab Register — aktif
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: Text(
                'Register',
                style: AppTextStyles.bodySemibold.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.small.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? errorText,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      onChanged: onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required String? errorText,
    required bool obscure,
    required ValueChanged<String> onChanged,
    required VoidCallback onToggle,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textGrey, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textGrey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}