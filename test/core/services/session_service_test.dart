// test/core/services/session_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:banksos/core/constants/hive_boxes.dart';
import 'package:banksos/core/services/session_service.dart';

void main() {
  // ─── Setup & teardown ──────────────────────────────────────────────────────

  setUp(() async {
    // Hive di test environment tidak butuh path Flutter,
    // cukup init biasa lalu buka box session
    Hive.init('test/hive_test_db');
    await Hive.openBox(HiveBoxes.session);
  });

  tearDown(() async {
    // Bersihkan dan tutup semua box setelah tiap test
    await Hive.box(HiveBoxes.session).clear();
    await Hive.close();
  });

  // ─── Group: saveSession ────────────────────────────────────────────────────

  group('saveSession()', () {
    test('menyimpan semua field dengan benar', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      expect(SessionService.instance.userId, equals('user123'));
      expect(SessionService.instance.email,
          equals('fathi@student.polban.ac.id'));
      expect(SessionService.instance.nama,
          equals('Mohammad Jibril Fathi'));
      expect(SessionService.instance.nim, equals('241511050'));
      expect(SessionService.instance.role, equals('mahasiswa'));
      expect(SessionService.instance.status, equals('active'));
    });

    test('loginAt diisi otomatis dan tidak null', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      expect(SessionService.instance.loginAt, isNotNull);

      // Pastikan formatnya ISO 8601 yang valid
      final parsed =
          DateTime.tryParse(SessionService.instance.loginAt!);
      expect(parsed, isNotNull);
    });

    test('overwrite sesi lama jika saveSession dipanggil lagi', () async {
      await SessionService.instance.saveSession(
        userId: 'user_lama',
        email: 'lama@student.polban.ac.id',
        nama: 'User Lama',
        nim: '000000000',
        role: 'mahasiswa',
        status: 'active',
      );

      await SessionService.instance.saveSession(
        userId: 'user_baru',
        email: 'baru@student.polban.ac.id',
        nama: 'User Baru',
        nim: '111111111',
        role: 'reviewer',
        status: 'active',
      );

      expect(SessionService.instance.userId, equals('user_baru'));
      expect(SessionService.instance.role, equals('reviewer'));
    });
  });

  // ─── Group: isLoggedIn ─────────────────────────────────────────────────────

  group('isLoggedIn', () {
    test('false jika belum ada sesi', () {
      expect(SessionService.instance.isLoggedIn, isFalse);
    });

    test('true setelah saveSession berhasil', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      expect(SessionService.instance.isLoggedIn, isTrue);
    });

    test('false kembali setelah clearSession', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      await SessionService.instance.clearSession();

      expect(SessionService.instance.isLoggedIn, isFalse);
    });
  });

  // ─── Group: helper role ────────────────────────────────────────────────────

  group('helper role', () {
    test('isMahasiswa true jika role mahasiswa', () async {
      await SessionService.instance.saveSession(
        userId: 'u1',
        email: 'a@a.com',
        nama: 'A',
        nim: '9999',
        role: 'mahasiswa',
        status: 'active',
      );
      expect(SessionService.instance.isMahasiswa, isTrue);
      expect(SessionService.instance.isReviewer, isFalse);
      expect(SessionService.instance.isAdmin, isFalse);
    });

    test('isReviewer true jika role reviewer', () async {
      await SessionService.instance.saveSession(
        userId: 'u2',
        email: 'b@b.com',
        nama: 'B',
        nim: '8888',
        role: 'reviewer',
        status: 'active',
      );
      expect(SessionService.instance.isReviewer, isTrue);
      expect(SessionService.instance.isMahasiswa, isFalse);
    });

    test('isAdmin true jika role admin', () async {
      await SessionService.instance.saveSession(
        userId: 'u3',
        email: 'c@c.com',
        nama: 'C',
        nim: '6666',
        role: 'admin',
        status: 'active',
      );
      expect(SessionService.instance.isAdmin, isTrue);
    });

    test('isActive true jika status active', () async {
      await SessionService.instance.saveSession(
        userId: 'u4',
        email: 'd@d.com',
        nama: 'D',
        nim: '7777',
        role: 'mahasiswa',
        status: 'active',
      );
      expect(SessionService.instance.isActive, isTrue);
    });

    test('isActive false jika status inactive', () async {
      await SessionService.instance.saveSession(
        userId: 'u5',
        email: 'e@e.com',
        nama: 'E',
        nim: '5555',
        role: 'mahasiswa',
        status: 'inactive',
      );
      expect(SessionService.instance.isActive, isFalse);
    });
  });

  // ─── Group: getSessionData ─────────────────────────────────────────────────

  group('getSessionData()', () {
    test('mengembalikan Map dengan semua key yang benar', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      final data = SessionService.instance.getSessionData();

      expect(data.containsKey('userId'), isTrue);
      expect(data.containsKey('email'), isTrue);
      expect(data.containsKey('nama'), isTrue);
      expect(data.containsKey('nim'), isTrue);
      expect(data.containsKey('role'), isTrue);
      expect(data.containsKey('status'), isTrue);
      expect(data.containsKey('loginAt'), isTrue);
      expect(data['userId'], equals('user123'));
    });

    test('semua value null jika belum ada sesi', () {
      final data = SessionService.instance.getSessionData();
      expect(data['userId'], isNull);
      expect(data['role'], isNull);
    });
  });

  // ─── Group: clearSession ───────────────────────────────────────────────────

  group('clearSession()', () {
    test('menghapus semua field dari box', () async {
      await SessionService.instance.saveSession(
        userId: 'user123',
        email: 'fathi@student.polban.ac.id',
        nama: 'Mohammad Jibril Fathi',
        nim: '241511050',
        role: 'mahasiswa',
        status: 'active',
      );

      await SessionService.instance.clearSession();

      expect(SessionService.instance.userId, isNull);
      expect(SessionService.instance.email, isNull);
      expect(SessionService.instance.nama, isNull);
      expect(SessionService.instance.nim, isNull);
      expect(SessionService.instance.role, isNull);
      expect(SessionService.instance.status, isNull);
      expect(SessionService.instance.loginAt, isNull);
    });

    test('aman dipanggil berkali-kali tanpa error', () async {
      await expectLater(
        SessionService.instance.clearSession(),
        completes,
      );
      await expectLater(
        SessionService.instance.clearSession(),
        completes,
      );
    });
  });
}