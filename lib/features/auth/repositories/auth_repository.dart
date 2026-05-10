// lib/features/auth/repositories/auth_repository.dart
// PIC: Revaldi (RP) — Auth Feature
// Menghubungkan auth_remote dengan controller (abstraksi clean architecture).

import '../../../data/models/user_model.dart';
import '../data/auth_remote.dart';

class AuthRepository {
  final _remote = AuthRemote();

  Future<UserModel> login(String email, String password) async {
    return await _remote.loginUser(email, password);
  }

  Future<UserModel> register({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    return await _remote.registerUser(
      namaLengkap: namaLengkap,
      nim: nim,
      email: email,
      password: password,
    );
  }
}