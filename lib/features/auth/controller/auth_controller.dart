import 'package:flutter/foundation.dart';
import '../../../core/services/session_service.dart';
import 'package:banksos/data/repositories/auth_repositories.dart';
import '../../../data/models/user_model.dart';

enum AuthState { idle, loading, success, error }

class AuthController extends ChangeNotifier {
  final IAuthRepository _repository;
  final SessionService _session;

  AuthController({
    IAuthRepository? repository,
    SessionService? session,
  })  : _repository = repository ?? AuthRepository(),
        _session = session ?? SessionService.instance;

  AuthState _state = AuthState.idle;
  String? _errorMessage;
  UserModel? _currentUser;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;

  // ─── Login ───────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    try {
      final user = await _repository.login(email, password);

      if (user == null) {
        _errorMessage = 'Email atau password salah.';
        _setState(AuthState.error);
        return;
      }

      if (user.status == UserStatus.inactive) {
        _errorMessage = 'Akun kamu dinonaktifkan. Hubungi admin.';
        _setState(AuthState.error);
        return;
      }

      // Simpan sesi ke Hive
      await _session.saveSession(
        userId: user.id,
        email: user.email,
        nama: user.namaLengkap,
        role: user.role.name,
        status: user.status.name,
      );

      _currentUser = user;
      _setState(AuthState.success);
    } on Exception catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _setState(AuthState.error);
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<void> register({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    try {
      final user = await _repository.register(
        namaLengkap: namaLengkap,
        nim: nim,
        email: email,
        password: password,
      );

      if (user == null) {
        _errorMessage = 'Registrasi gagal. Coba lagi.';
        _setState(AuthState.error);
        return;
      }

      // Auto-login setelah register berhasil
      await _session.saveSession(
        userId: user.id,
        email: user.email,
        nama: user.namaLengkap,
        role: user.role.name,
        status: user.status.name,
      );

      _currentUser = user;
      _setState(AuthState.success);
    } on Exception catch (e) {
      // Tangkap error duplikat email dari MongoDB
      final msg = e.toString();
      if (msg.contains('duplicate') || msg.contains('E11000')) {
        _errorMessage = 'Email sudah terdaftar. Gunakan email lain.';
      } else {
        _errorMessage = 'Registrasi gagal: $msg';
      }
      _setState(AuthState.error);
    }
  }

  void resetState() {
    _state = AuthState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}