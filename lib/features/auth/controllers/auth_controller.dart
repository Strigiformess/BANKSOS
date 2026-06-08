// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Helper pembersih ID
  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }

  /// Login — mengembalikan role user jika berhasil, null jika gagal.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final isOnline = await ConnectivityService.instance.isOnline;

      // Jika offline dan sudah ada sesi tersimpan, coba login lokal
      if (!isOnline && SessionService.instance.isLoggedIn) {
        // Pastikan email yang diminta sama dengan sesi yang tersimpan
        final cachedEmail = SessionService.instance.email?.toLowerCase().trim();
        if (cachedEmail == email.toLowerCase().trim()) {
          final role = SessionService.instance.role;
          state = state.copyWith(isLoading: false, isSuccess: true, errorMessage: null);
          return role;
        } else {
          throw Exception('Offline dan tidak ada sesi yang cocok untuk akun ini.');
        }
      }

      // Normal online flow
      final user = await _repository.login(email, password);

      // Buat token offline panjang agar dapat login kembali tanpa internet
      final cleanUserId = _cleanId(user.id);

      // Simpan sesi ke Hive
      await SessionService.instance.saveSession(
        userId: cleanUserId,
        email: user.email,
        nama: user.namaLengkap,
        role: user.role.name,
        status: user.status.name,
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