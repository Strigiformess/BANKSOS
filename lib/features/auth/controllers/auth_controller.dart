// lib/features/auth/controllers/auth_controller.dart
// PIC: Revaldi (RP) — Auth Feature
// State management login/register: loading state, success state, error state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/session_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../repositories/auth_repository.dart';
import '../states/auth_state.dart';

// ─── Provider global (dipakai oleh LoginScreen & RegisterScreen) ─────────────
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(AuthRepository());
});

// ─── Controller ───────────────────────────────────────────────────────────────
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.initial);

  final AuthRepository _repository;

  /// Login — mengembalikan role user jika berhasil, null jika gagal.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final isOnline = await ConnectivityService.instance.isOnline;

      // Jika offline, gunakan token offline + password hash lokal
      if (!isOnline && SessionService.instance.isLoggedIn) {
        final cachedEmail = SessionService.instance.email?.toLowerCase().trim();
        if (cachedEmail != email.toLowerCase().trim()) {
          throw Exception('Offline dan tidak ada sesi yang cocok untuk akun ini.');
        }

        if (!SessionService.instance.isOfflineTokenValid) {
          throw Exception('Offline token sudah kadaluwarsa. Silakan login lagi saat online.');
        }

        if (!SessionService.instance.verifyOfflinePassword(password)) {
          throw Exception('Email atau kata sandi salah.');
        }

        final role = SessionService.instance.role;
        state = state.copyWith(isLoading: false, isSuccess: true, errorMessage: null);
        return role;
      }

      // Normal online flow
      final user = await _repository.login(email, password);

      // Buat token offline panjang agar dapat login kembali tanpa internet
      final offlineToken = const Uuid().v4();
      final offlineTokenExpiry = DateTime.now().add(const Duration(days: 30));
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Simpan sesi ke Hive
      await SessionService.instance.saveSession(
        userId: user.id,
        email: user.email,
        nama: user.namaLengkap,
        role: user.role.name,
        status: user.status.name,
        offlineToken: offlineToken,
        offlineTokenExpiry: offlineTokenExpiry,
        passwordHash: hashedPassword,
      );

      state = state.copyWith(isLoading: false, isSuccess: true, errorMessage: null);
      return user.role.name; // 'mahasiswa' | 'reviewer' | 'admin'
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Register — mengembalikan true jika berhasil.
  Future<bool> register({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      await _repository.register(
        namaLengkap: namaLengkap,
        nim: nim,
        email: email,
        password: password,
      );

      state = state.copyWith(isLoading: false, isSuccess: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset error — dipanggil saat berpindah halaman agar error lama hilang.
  void clearError() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }
}