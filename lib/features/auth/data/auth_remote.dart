import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../../../data/models/user_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class AuthRemote {
  final _db = MongoDBService.instance;

  /// LOGIN USER
  /// Cari user berdasarkan email + verifikasi bcrypt.
  Future<UserModel> loginUser(String email, String password) async {
    // Pastikan MongoDB sudah connect (Validasi Offline)
    if (!_db.isConnected) {
      throw Exception('Tidak dapat masuk. Pastikan Anda terhubung ke internet.');
    }

    final col = _db.users;
    final normalizedEmail = email.toLowerCase().trim();

    // 1. Cari user berdasarkan email saja
    final result = await col.findOne(where.eq('email', normalizedEmail));

    // Jika user tidak ditemukan
    if (result == null) {
      throw Exception('Email atau kata sandi salah.');
    }

    // 2. Verifikasi Password Hash menggunakan Bcrypt
    final String storedHash = result['password_hash'] as String;
    final bool isMatch = BCrypt.checkpw(password, storedHash);
    
    if (!isMatch) {
      throw Exception('Email atau kata sandi salah.');
    }

    // Convert MongoDB document → UserModel
    final user = UserModel.fromMap(result);

    // Cek status akun
    if (user.status == UserStatus.inactive) {
      throw Exception('Akun kamu dinonaktifkan. Hubungi admin.');
    }

    return user;
  }

  /// REGISTER USER
  /// Membuat akun mahasiswa baru dengan Bcrypt.
  Future<UserModel> registerUser({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    // Pastikan MongoDB sudah connect (Validasi Offline)
    if (!_db.isConnected) {
      throw Exception('Pendaftaran membutuhkan koneksi internet.');
    }

    final col = _db.users;
    final normalizedEmail = email.toLowerCase().trim();

    // 1. Cek apakah email sudah dipakai
    final existing = await col.findOne(where.eq('email', normalizedEmail));
    if (existing != null) {
      throw Exception('Email sudah terdaftar. Silakan login.');
    }

    // 2. Hash password menggunakan Bcrypt (Sesuai SRS Document)
    final String hashedPw = BCrypt.hashpw(password, BCrypt.gensalt());

    final now = DateTime.now();

    // 3. Data document MongoDB
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

    // 4. Insert ke MongoDB
    final result = await col.insertOne(doc);

    if (!result.isSuccess) {
      throw Exception('Gagal mendaftar. Coba beberapa saat lagi.');
    }

    // 5. Kembalikan data yang baru di-insert sebagai UserModel
    return UserModel.fromMap(doc);
  }
}