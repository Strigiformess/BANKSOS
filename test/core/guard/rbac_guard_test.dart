// test/core/guard/rbac_guard_test.dart
//
// Unit test untuk RbacGuard — business logic RBAC di controller level.
// Test ini menggunakan SessionService dengan Hive in-memory agar
// bisa mensimulasikan berbagai role tanpa mock framework eksternal.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:banksos/core/constants/hive_boxes.dart';
import 'package:banksos/core/guard/rbac_guard.dart';
import 'package:banksos/core/services/session_service.dart';

const _testHivePath = 'test/hive_rbac_test_db';

// ─── Helper: set sesi dengan role tertentu ────────────────────────────────────

Future<void> _loginAs(String role) async {
  await SessionService.instance.saveSession(
    userId: 'user_$role',
    email: '$role@polban.ac.id',
    nama: 'User $role',
    role: role,
    status: 'active',
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() async {
    Hive.init(_testHivePath);
    await Hive.openBox(HiveBoxes.session);
  });

  tearDown(() async {
    await Hive.box(HiveBoxes.session).clear();
    await Hive.close();
  });

  // ─── Group: requireReviewer ───────────────────────────────────────────────

  group('RbacGuard.requireReviewer()', () {
    test('tidak throw jika user adalah reviewer yang login', () async {
      await _loginAs('reviewer');

      expect(
        () => RbacGuard.requireReviewer(SessionService.instance),
        returnsNormally,
      );
    });

    test('throw RbacException jika user adalah mahasiswa', () async {
      await _loginAs('mahasiswa');

      expect(
        () => RbacGuard.requireReviewer(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });

    test('throw RbacException jika user adalah admin', () async {
      await _loginAs('admin');

      expect(
        () => RbacGuard.requireReviewer(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });

    test('throw RbacException jika belum login (sesi kosong)', () async {
      // Tidak memanggil _loginAs() — sesi kosong

      expect(
        () => RbacGuard.requireReviewer(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });

    test('pesan RbacException mengandung kata "reviewer"', () async {
      await _loginAs('mahasiswa');

      try {
        RbacGuard.requireReviewer(SessionService.instance);
        fail('Seharusnya melempar RbacException');
      } on RbacException catch (e) {
        expect(e.message.toLowerCase(), contains('reviewer'));
      }
    });
  });

  // ─── Group: requireAdmin ──────────────────────────────────────────────────

  group('RbacGuard.requireAdmin()', () {
    test('tidak throw jika user adalah admin yang login', () async {
      await _loginAs('admin');

      expect(
        () => RbacGuard.requireAdmin(SessionService.instance),
        returnsNormally,
      );
    });

    test('throw RbacException jika user adalah reviewer', () async {
      await _loginAs('reviewer');

      expect(
        () => RbacGuard.requireAdmin(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });

    test('throw RbacException jika user adalah mahasiswa', () async {
      await _loginAs('mahasiswa');

      expect(
        () => RbacGuard.requireAdmin(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });
  });

  // ─── Group: requireMahasiswa ──────────────────────────────────────────────

  group('RbacGuard.requireMahasiswa()', () {
    test('tidak throw jika user adalah mahasiswa yang login', () async {
      await _loginAs('mahasiswa');

      expect(
        () => RbacGuard.requireMahasiswa(SessionService.instance),
        returnsNormally,
      );
    });

    test('throw RbacException jika user adalah reviewer', () async {
      await _loginAs('reviewer');

      expect(
        () => RbacGuard.requireMahasiswa(SessionService.instance),
        throwsA(isA<RbacException>()),
      );
    });
  });

  // ─── Group: requireAnyRole ────────────────────────────────────────────────

  group('RbacGuard.requireAnyRole()', () {
    test('tidak throw jika role ada di daftar allowedRoles', () async {
      await _loginAs('reviewer');

      expect(
        () => RbacGuard.requireAnyRole(
          SessionService.instance,
          ['reviewer', 'admin'],
        ),
        returnsNormally,
      );
    });

    test('tidak throw untuk admin jika admin ada di allowedRoles', () async {
      await _loginAs('admin');

      expect(
        () => RbacGuard.requireAnyRole(
          SessionService.instance,
          ['reviewer', 'admin'],
        ),
        returnsNormally,
      );
    });

    test('throw RbacException jika role tidak ada di daftar', () async {
      await _loginAs('mahasiswa');

      expect(
        () => RbacGuard.requireAnyRole(
          SessionService.instance,
          ['reviewer', 'admin'],
        ),
        throwsA(isA<RbacException>()),
      );
    });
  });

  // ─── Group: isReviewer / isAdmin / isMahasiswa (boolean check) ───────────

  group('RbacGuard bool checks', () {
    test('isReviewer() true hanya jika logged in sebagai reviewer', () async {
      await _loginAs('reviewer');
      expect(RbacGuard.isReviewer(SessionService.instance), isTrue);
      expect(RbacGuard.isAdmin(SessionService.instance), isFalse);
      expect(RbacGuard.isMahasiswa(SessionService.instance), isFalse);
    });

    test('isAdmin() true hanya jika logged in sebagai admin', () async {
      await _loginAs('admin');
      expect(RbacGuard.isAdmin(SessionService.instance), isTrue);
      expect(RbacGuard.isReviewer(SessionService.instance), isFalse);
      expect(RbacGuard.isMahasiswa(SessionService.instance), isFalse);
    });

    test('isMahasiswa() true hanya jika logged in sebagai mahasiswa', () async {
      await _loginAs('mahasiswa');
      expect(RbacGuard.isMahasiswa(SessionService.instance), isTrue);
      expect(RbacGuard.isReviewer(SessionService.instance), isFalse);
      expect(RbacGuard.isAdmin(SessionService.instance), isFalse);
    });

    test('semua boolean check false jika belum login', () {
      // Sesi kosong — tidak memanggil _loginAs()
      expect(RbacGuard.isReviewer(SessionService.instance), isFalse);
      expect(RbacGuard.isAdmin(SessionService.instance), isFalse);
      expect(RbacGuard.isMahasiswa(SessionService.instance), isFalse);
    });

    test('hasAnyRole() true jika role ada di list', () async {
      await _loginAs('reviewer');
      expect(
        RbacGuard.hasAnyRole(SessionService.instance, ['reviewer', 'admin']),
        isTrue,
      );
    });

    test('hasAnyRole() false jika role tidak ada di list', () async {
      await _loginAs('mahasiswa');
      expect(
        RbacGuard.hasAnyRole(SessionService.instance, ['reviewer', 'admin']),
        isFalse,
      );
    });
  });
}
