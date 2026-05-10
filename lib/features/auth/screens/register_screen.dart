// lib/features/auth/screens/register_screen.dart
// PIC: Seruni (SL) — UI Layer
// Sprint 1 Rabu + Kamis: Halaman Register dengan real-time validator, connect ke auth_controller.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _namaCtrl      = TextEditingController();
  final _nimCtrl       = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _konfirmasiCtrl= TextEditingController();

  bool _obscurePassword     = true;
  bool _obscureKonfirmasi   = true;

  // Untuk real-time validation — tiap field punya error string sendiri
  String? _namaError;
  String? _nimError;
  String? _emailError;
  String? _passwordError;
  String? _konfirmasiError;

  // Tombol Daftar hanya aktif jika semua field sudah valid
  bool get _isFormValid =>
      _namaError == null && _namaCtrl.text.isNotEmpty &&
      _nimError == null && _nimCtrl.text.isNotEmpty &&
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

  // ─── Validators real-time ─────────────────────────────────────────────────

  void _validateNama(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _namaError = 'Nama lengkap tidak boleh kosong';
      } else if (value.trim().length < 3) {
        _namaError = 'Nama minimal 3 karakter';
      } else {
        _namaError = null;
      }
    });
  }

  void _validateNim(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _nimError = 'NIM tidak boleh kosong';
      } else if (!RegExp(r'^\d{9}$').hasMatch(value.trim())) {
        _nimError = 'NIM harus 9 digit angka';
      } else {
        _nimError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'Email tidak boleh kosong';
      } else if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$')
          .hasMatch(value.trim())) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Kata sandi tidak boleh kosong';
      } else if (value.length < 8) {
        _passwordError = 'Kata sandi minimal 8 karakter';
      } else if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
        _passwordError = 'Kata sandi harus mengandung huruf dan angka';
      } else {
        _passwordError = null;
      }
      // Re-validate konfirmasi jika sudah diisi
      if (_konfirmasiCtrl.text.isNotEmpty) {
        _validateKonfirmasi(_konfirmasiCtrl.text);
      }
    });
  }

  void _validateKonfirmasi(String value) {
    setState(() {
      if (value.isEmpty) {
        _konfirmasiError = 'Konfirmasi kata sandi tidak boleh kosong';
      } else if (value != _passwordCtrl.text) {
        _konfirmasiError = 'Kata sandi tidak cocok';
      } else {
        _konfirmasiError = null;
      }
    });
  }

  // ─── Submit register ──────────────────────────────────────────────────────
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
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Kembali ke LoginScreen
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subjudul
              Text(
                'Isi data diri kamu untuk mulai belajar bersama BANKSOS.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Error dari server ──────────────────────────────────────────
              if (authState.errorMessage != null) ...[
                _buildErrorBanner(authState.errorMessage!),
                const SizedBox(height: 16),
              ],

              // ── Nama Lengkap ───────────────────────────────────────────────
              _buildField(
                controller: _namaCtrl,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap kamu',
                icon: Icons.person_outline,
                errorText: _namaError,
                onChanged: _validateNama,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              // ── NIM ────────────────────────────────────────────────────────
              _buildField(
                controller: _nimCtrl,
                label: 'NIM',
                hint: '241511xxx',
                icon: Icons.badge_outlined,
                errorText: _nimError,
                onChanged: _validateNim,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              // ── Email ──────────────────────────────────────────────────────
              _buildField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'email@student.polban.ac.id',
                icon: Icons.email_outlined,
                errorText: _emailError,
                onChanged: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              // ── Kata Sandi ─────────────────────────────────────────────────
              _buildPasswordField(
                controller: _passwordCtrl,
                label: 'Kata Sandi',
                hint: 'Min. 8 karakter, huruf + angka',
                errorText: _passwordError,
                obscure: _obscurePassword,
                onChanged: _validatePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              // ── Konfirmasi Kata Sandi ──────────────────────────────────────
              _buildPasswordField(
                controller: _konfirmasiCtrl,
                label: 'Konfirmasi Kata Sandi',
                hint: 'Ulangi kata sandi kamu',
                errorText: _konfirmasiError,
                obscure: _obscureKonfirmasi,
                onChanged: _validateKonfirmasi,
                onToggleObscure: () =>
                    setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onRegister(),
              ),

              const SizedBox(height: 28),

              // ── Tombol Daftar ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: (!_isFormValid || authState.isLoading)
                    ? null
                    : _onRegister,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Daftar'),
              ),

              const SizedBox(height: 20),

              // ── Link ke Login ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(authControllerProvider.notifier).clearError();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget helper ────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? errorText,
    required bool obscure,
    required ValueChanged<String> onChanged,
    required VoidCallback onToggleObscure,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.textGrey,
          ),
          onPressed: onToggleObscure,
        ),
      ),
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
}