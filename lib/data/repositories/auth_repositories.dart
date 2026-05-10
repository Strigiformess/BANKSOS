import 'package:banksos/data/remote/auth_remote.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  });
}

class AuthRepository implements IAuthRepository {
  final AuthRemote _remote;

  AuthRepository({AuthRemote? remote})
      : _remote = remote ?? AuthRemote();

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      // Delegasikan ke auth_remote milik Adjie
      final map = await _remote.loginUser(email: email, password: password);
      if (map == null) return null;
      return UserModel.fromMap(map);
    } catch (e) {
      rethrow; // biarkan controller yang tangkap & tampilkan error
    }
  }

  @override
  Future<UserModel?> register({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    try {
      final map = await _remote.registerUser(
        namaLengkap: namaLengkap,
        nim: nim,
        email: email,
        password: password,
      );
      if (map == null) return null;
      return UserModel.fromMap(map);
    } catch (e) {
      rethrow;
    }
  }
}