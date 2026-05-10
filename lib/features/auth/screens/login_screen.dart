// lib/features/auth/screens/login_screen.dart
// PIC: Seruni (SL) — UI Layer
// Sprint 1 Selasa + Kamis: Halaman Login dengan inline error, connect ke auth_controller.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Submit login ─────────────────────────────────────────────────────────
  Future<void> _onLogin() async {
    // Validasi form klien-side dulu
    if (!_formKey.currentState!.validate()) return;

    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final role = await ref
        .read(authControllerProvider.notifier)
        .login(email, password);

    if (role != null && mounted) {
      _navigateByRole(role);
    }
    // Jika null, error ditampilkan otomatis oleh ref.listen di bawah
  }

  // ─── Routing berdasarkan role setelah login berhasil ─────────────────────
  void _navigateByRole(String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardAdmin);
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardReviewer);
        break;
      default: // mahasiswa
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardMahasiswa);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // ── Logo & Judul ────────────────────────────────────────────
                _buildHeader(),

                const SizedBox(height: 40),

                // ── Error umum dari server ──────────────────────────────────
                if (authState.errorMessage != null) ...[
                  _buildErrorBanner(authState.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── Field Email ─────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'email@student.polban.ac.id',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Field Kata Sandi ────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLogin(),
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textGrey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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

                const SizedBox(height: 28),

                // ── Tombol Masuk ────────────────────────────────────────────
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

                const SizedBox(height: 20),

                // ── Link ke Register ────────────────────────────────────────
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widget helper ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo placeholder — ganti dengan Image.asset('assets/logo_banksos.png')
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'BS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'BANKSOS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bank Soal Kolaboratif POLBAN',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textGrey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            ref.read(authControllerProvider.notifier).clearError();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: const Text(
            'Daftar di sini',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}