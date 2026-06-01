// lib/features/auth/states/auth_state.dart
// PIC: Revaldi (RP)
// Sprint 1: Implementasi state management login/register
// State untuk controller autentikasi (login & register).
// Digunakan oleh AuthController (Riverpod StateNotifier).
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // Pass null secara eksplisit untuk reset error
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Reset state ke kondisi awal (dipakai saat pindah halaman)
  static const initial = AuthState();
}