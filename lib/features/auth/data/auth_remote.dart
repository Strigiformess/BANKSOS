// lib/features/auth/data/auth_remote.dart
import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../../../data/models/user_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class AuthRemote {
  final _db = MongoDBService.instance;

  /// LOGIN USER
  Future<UserModel> loginUser(String email, String password) async {
    if (!_db.isConnected) {
      throw Exception('Tidak dapat masuk. Pastikan Anda terhubung ke internet.');
    }

    try {
      final col = _db.users;
      final normalizedEmail = email.toLowerCase().trim();

      final result = await col.findOne(where.eq('email', normalizedEmail));

      if (result == null) {
        throw Exception('Email atau kata sandi salah.');
      }

      final String storedHash = result['password_hash'] as String;
      final bool isMatch = BCrypt.checkpw(password, storedHash);
      
      if (!isMatch) {
        throw Exception('Email atau kata sandi salah.');
      }

      final user = UserModel.fromMap(result);

      if (user.status == UserStatus.inactive) {
        throw Exception('Akun kamu dinonaktifkan. Hubungi admin.');
      }

      return user;
    } catch (e) {
      // Tangkap error "No master connection" dari MongoDart
      if (e.toString().contains('No master connection') || e.toString().contains('ConnectionException')) {
        throw Exception('Koneksi ke server terputus. Periksa sinyal internet Anda lalu coba lagi.');
      }
      rethrow;
    }
  }

  /// REGISTER USER
  Future<UserModel> registerUser({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    if (!_db.isConnected) {
      throw Exception('Pendaftaran membutuhkan koneksi internet.');
    }

    try {
      final col = _db.users;
      final normalizedEmail = email.toLowerCase().trim();

      final existing = await col.findOne(where.eq('email', normalizedEmail));
      if (existing != null) {
        throw Exception('Email sudah terdaftar. Silakan login.');
      }

      final String hashedPw = BCrypt.hashpw(password, BCrypt.gensalt());
      final now = DateTime.now();

      final doc = {
        '_id': ObjectId(),
        'nama_lengkap': namaLengkap.trim(),
        'nim': nim.trim(),
        'email': normalizedEmail,
        'password_hash': hashedPw,
        'role': 'mahasiswa',
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final result = await col.insertOne(doc);

      if (!result.isSuccess) {
        throw Exception('Gagal mendaftar. Coba beberapa saat lagi.');
      }

      return UserModel.fromMap(doc);
    } catch (e) {
      if (e.toString().contains('No master connection') || e.toString().contains('ConnectionException')) {
        throw Exception('Koneksi ke server terputus. Gagal melakukan registrasi.');
      }
      rethrow;
    }
  }
}