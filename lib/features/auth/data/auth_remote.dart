// lib/features/auth/data/auth_remote.dart
// PIC: Adjie (AA) — Database
// Seruni cukup tahu interface-nya untuk dihubungkan ke controller.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../../../data/models/user_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

class AuthRemote {
  final _db = MongoDBService.instance;

  /// Hash password menggunakan SHA-256.
  /// NOTE:
  /// Production sebaiknya pakai bcrypt/argon2.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// LOGIN USER
  /// Cari user berdasarkan email + password hash.
  Future<UserModel> loginUser(String email, String password) async {
    // Pastikan MongoDB sudah connect
    if (!_db.isConnected) {
      throw Exception('MongoDB belum terhubung.');
    }

    final col = _db.users;

    // Hash password input user
    final hashedPw = _hashPassword(password);

    // Cari user berdasarkan email + password hash
    final result = await col.findOne(
      where
          .eq('email', email.toLowerCase().trim())
          .eq('password_hash', hashedPw),
    );

    // Jika user tidak ditemukan
    if (result == null) {
      throw Exception('Email atau kata sandi salah.');
    }

    // Convert MongoDB document → UserModel
    final user = UserModel.fromMap(result);

    // Cek status akun
    if (user.status == UserStatus.inactive) {
      throw Exception('Akun kamu dinonaktifkan.');
    }

    return user;
  }

  /// REGISTER USER
  /// Membuat akun mahasiswa baru.
  Future<UserModel> registerUser({
    required String namaLengkap,
    required String nim,
    required String email,
    required String password,
  }) async {
    // Pastikan MongoDB sudah connect
    if (!_db.isConnected) {
      throw Exception(
        'Tidak ada koneksi database. Pendaftaran membutuhkan internet.',
      );
    }

    final col = _db.users;

    final normalizedEmail = email.toLowerCase().trim();

    // Cek apakah email sudah dipakai
    final existing = await col.findOne(
      where.eq('email', normalizedEmail),
    );

    if (existing != null) {
      throw Exception('Email sudah terdaftar. Silakan login.');
    }

    // Hash password
    final hashedPw = _hashPassword(password);

    final now = DateTime.now();

    // Data document MongoDB
    final doc = {
      'nama_lengkap': namaLengkap.trim(),
      'nim': nim.trim(),
      'email': normalizedEmail,
      'password_hash': hashedPw,
      'role': 'mahasiswa',
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    // Insert ke MongoDB
    final result = await col.insertOne(doc);

    // Jika gagal insert
    if (!result.isSuccess) {
      throw Exception('Gagal mendaftar. Coba beberapa saat lagi.');
    }

    // Ambil data user yang baru dibuat
    final inserted = await col.findOne(
      where.id(result.id!),
    );

    return UserModel.fromMap(inserted!);
  }
}