// test/core/services/sync_manager_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:banksos/core/constants/hive_boxes.dart';
import 'package:banksos/core/services/sync_manager.dart';
import 'package:banksos/data/models/sync_queue_model.dart';
// INFO: Pastikan mengimport HiveService agar kita bisa mengontrol box-nya jika diperlukan
import 'package:banksos/data/local/hive/hive_service.dart';

const _testHivePath = 'test/hive_sync_test_db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory(_testHivePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    
    Hive.init(_testHivePath);

    // Daftarkan SyncTypeAdapter hasil generator build_runner tadi
    if (!Hive.isAdapterRegistered(SyncTypeAdapter().typeId)) {
      Hive.registerAdapter(SyncTypeAdapter());
    }

    // Daftarkan adapter SyncQueueModel
    if (!Hive.isAdapterRegistered(SyncQueueModelAdapter().typeId)) {
      Hive.registerAdapter(SyncQueueModelAdapter());
    }

    await Hive.openBox<SyncQueueModel>(HiveBoxes.syncQueue);
  });

  tearDown(() async {
    // Hapus data dan tutup Hive dengan aman setelah setiap test selesai
    if (Hive.isBoxOpen(HiveBoxes.syncQueue)) {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();
    }
    await Hive.close();

    final dir = Directory(_testHivePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  // ─── Group: enqueue ──────────────────────────────────────────────────────────

  group('enqueue()', () {
    test('menambah item ke Hive syncQueueBox', () async {
      // Pastikan antrian awal adalah 0
      expect(SyncManager.instance.pendingCount, equals(0));

      await SyncManager.instance.enqueueProgress(
        userId: 'user1',
        questionId: 'soal1',
        categoryId: 'kat1',
        isSolved: true,
        attemptCount: 2,
      );

      expect(SyncManager.instance.pendingCount, equals(1));
    });

    test('enqueueBookmark menambah item dengan type bookmark', () async {
      await SyncManager.instance.enqueueBookmark(
        userId: 'user1',
        questionId: 'soal1',
        isAdd: true,
      );

      final box = Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);
      expect(box.length, equals(1));
      expect(box.values.first.type, equals(SyncType.bookmark));
      expect(box.values.first.payload['action'], equals('add'));
    });

    test('enqueue berkali-kali menambah semua item', () async {
      // Membersihkan state box sebelum test case berjalan
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();

      await SyncManager.instance.enqueueProgress(
        userId: 'user1',
        questionId: 'soal1',
        categoryId: 'kat1',
        isSolved: true,
        attemptCount: 1,
      );
      await SyncManager.instance.enqueueProgress(
        userId: 'user1',
        questionId: 'soal2',
        categoryId: 'kat1',
        isSolved: false,
        attemptCount: 3,
      );
      await SyncManager.instance.enqueueBookmark(
        userId: 'user1',
        questionId: 'soal1',
        isAdd: false,
      );

      expect(SyncManager.instance.pendingCount, equals(3));
    });
  });

  // ─── Group: pendingCount ─────────────────────────────────────────────────────

  group('pendingCount', () {
    test('0 saat box kosong', () async {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();
      expect(SyncManager.instance.pendingCount, equals(0));
    });

    test('berkurang setelah item dihapus dari Hive', () async {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();

      await SyncManager.instance.enqueueProgress(
        userId: 'user1',
        questionId: 'soal1',
        categoryId: 'kat1',
        isSolved: true,
        attemptCount: 1,
      );

      expect(SyncManager.instance.pendingCount, equals(1));

      final box = Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);
      final key = box.keys.first;
      await box.delete(key);

      expect(SyncManager.instance.pendingCount, equals(0));
    });
  });

  // ─── Group: payload validation ───────────────────────────────────────────────

  group('payload structure', () {
    test('progress payload mengandung semua field wajib', () async {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();

      await SyncManager.instance.enqueueProgress(
        userId: 'user123',
        questionId: 'soal456',
        categoryId: 'kat789',
        isSolved: true,
        attemptCount: 5,
        solvedAt: DateTime(2025, 6, 1),
      );

      final box = Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);
      final item = box.values.first;

      expect(item.type, equals(SyncType.progress));
      expect(item.payload['user_id'], equals('user123'));
      expect(item.payload['question_id'], equals('soal456'));
      expect(item.payload['category_id'], equals('kat789'));
      expect(item.payload['is_solved'], isTrue);
      expect(item.payload['attempt_count'], equals(5));
      expect(item.payload['solved_at'], isNotNull);
      expect(item.retryCount, equals(0));
    });

    test('bookmark payload mengandung field action', () async {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();

      await SyncManager.instance.enqueueBookmark(
        userId: 'user1',
        questionId: 'soal1',
        isAdd: false,
      );

      final box = Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);
      final item = box.values.first;

      expect(item.payload['action'], equals('remove'));
      expect(item.payload['user_id'], equals('user1'));
      expect(item.payload['question_id'], equals('soal1'));
    });

    test('setiap item punya id unik (uuid)', () async {
      await Hive.box<SyncQueueModel>(HiveBoxes.syncQueue).clear();

      await SyncManager.instance.enqueueProgress(
        userId: 'u1',
        questionId: 'q1',
        categoryId: 'k1',
        isSolved: true,
        attemptCount: 1,
      );
      await SyncManager.instance.enqueueProgress(
        userId: 'u1',
        questionId: 'q2',
        categoryId: 'k1',
        isSolved: false,
        attemptCount: 2,
      );

      final box = Hive.box<SyncQueueModel>(HiveBoxes.syncQueue);
      final ids = box.values.map((e) => e.id).toList();

      expect(ids.toSet().length, equals(ids.length));
    });
  });

  // ─── Group: isSyncing guard ──────────────────────────────────────────────────

  group('isSyncing', () {
    test('false saat idle', () {
      expect(SyncManager.instance.isSyncing, isFalse);
    });
  });
}
