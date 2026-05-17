// test/data/local/question_box_test.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:banksos/core/constants/hive_boxes.dart';
import 'package:banksos/core/services/offline_question_service.dart';
import 'package:banksos/data/local/boxes/category_box.dart';
import 'package:banksos/data/local/boxes/question_box.dart';
import 'package:banksos/data/models/category_model.dart';
import 'package:banksos/data/models/question_model.dart';

// ─── Data dummy ──────────────────────────────────────────────────────────────

CategoryModel _dummyKategori({String id = 'kat1', String nama = 'Basis Data'}) {
  return CategoryModel(
    id: id,
    nama: nama,
    deskripsi: 'Deskripsi $nama',
    isActive: true,
  );
}

QuestionModel _dummySoal({
  String id = 'soal1',
  String kategoriId = 'kat1',
  DifficultyLevel tingkat = DifficultyLevel.easy,
}) {
  return QuestionModel(
    id: id,
    pertanyaan: 'Pertanyaan $id',
    jawaban: 'jawaban $id',
    kategoriId: kategoriId,
    kategoriNama: 'Basis Data',
    tingkatKesulitan: tingkat,
    status: QuestionStatus.published,
    hints: ['Hint 1', 'Hint 2'],
    submittedBy: 'user1',
    reviewedBy: 'reviewer1',
    rejectionReason: '',
    solveCount: 0,
    createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    updatedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const _testHivePath = 'test/hive_test_db';

// Mock connectivity channel — selalu offline di unit test
const MethodChannel _connectivityChannel =
    MethodChannel('dev.fluttercommunity.plus/connectivity');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock connectivity_plus supaya tidak MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_connectivityChannel, (call) async {
      if (call.method == 'check') return ['none']; // simulasi offline
      return null;
    });

    await Directory(_testHivePath).create(recursive: true);
    Hive.init(_testHivePath);

    // Daftarkan adapter berdasarkan adapter.typeId agar tidak bergantung
    // pada angka hardcoded yang mungkin berubah di kode generated.
    final diffAdapter = DifficultyLevelAdapter();
    if (!Hive.isAdapterRegistered(diffAdapter.typeId)) {
      Hive.registerAdapter(diffAdapter);
    }

    final statusAdapter = QuestionStatusAdapter();
    if (!Hive.isAdapterRegistered(statusAdapter.typeId)) {
      Hive.registerAdapter(statusAdapter);
    }

    final questionAdapter = QuestionModelAdapter();
    if (!Hive.isAdapterRegistered(questionAdapter.typeId)) {
      Hive.registerAdapter(questionAdapter);
    }

    // CategoryModel adapter (typeId bisa berbeda tergantung generated file)
    final categoryAdapter = CategoryModelAdapter();
    if (!Hive.isAdapterRegistered(categoryAdapter.typeId)) {
      Hive.registerAdapter(categoryAdapter);
    }

    await Hive.openBox<QuestionModel>(HiveBoxes.questions);
    await Hive.openBox<CategoryModel>(HiveBoxes.categories);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_connectivityChannel, null);

    if (Hive.isBoxOpen(HiveBoxes.questions)) {
      await Hive.box<QuestionModel>(HiveBoxes.questions).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.categories)) {
      await Hive.box<CategoryModel>(HiveBoxes.categories).clear();
    }
    await Hive.close();

    final dir = Directory(_testHivePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  // ─── Group: QuestionBox ───────────────────────────────────────────────────

  group('QuestionBox', () {
    test('save() menyimpan satu soal dengan benar', () async {
      await QuestionBox.instance.save(_dummySoal());

      final result = QuestionBox.instance.getById('soal1');
      expect(result, isNotNull);
      expect(result!.pertanyaan, equals('Pertanyaan soal1'));
    });

    test('saveAll() menyimpan banyak soal sekaligus', () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1'),
        _dummySoal(id: 'soal2'),
        _dummySoal(id: 'soal3'),
      ]);
      expect(QuestionBox.instance.getAll().length, equals(3));
    });

    test('getByKategori() hanya mengembalikan soal dari kategori yang benar',
        () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1', kategoriId: 'kat1'),
        _dummySoal(id: 'soal2', kategoriId: 'kat1'),
        _dummySoal(id: 'soal3', kategoriId: 'kat2'),
      ]);

      final result = QuestionBox.instance.getByKategori('kat1');
      expect(result.length, equals(2));
      expect(result.every((q) => q.kategoriId == 'kat1'), isTrue);
    });

    test('getByKategoriDanKesulitan() filter kombinasi benar', () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1', kategoriId: 'kat1', tingkat: DifficultyLevel.easy),
        _dummySoal(id: 'soal2', kategoriId: 'kat1', tingkat: DifficultyLevel.hard),
        _dummySoal(id: 'soal3', kategoriId: 'kat1', tingkat: DifficultyLevel.easy),
      ]);

      final result = QuestionBox.instance.getByKategoriDanKesulitan(
        kategoriId: 'kat1',
        tingkatKesulitan: 'easy',
      );
      expect(result.length, equals(2));
      expect(
        result.every((q) => q.tingkatKesulitan == DifficultyLevel.easy),
        isTrue,
      );
    });

    test('isDownloaded() true jika soal ada, false jika tidak', () async {
      await QuestionBox.instance.save(_dummySoal(id: 'soal1'));

      expect(QuestionBox.instance.isDownloaded('soal1'), isTrue);
      expect(QuestionBox.instance.isDownloaded('soal_tidak_ada'), isFalse);
    });

    test('isKategoriDownloaded() true jika ada soal dari kategori itu',
        () async {
      await QuestionBox.instance.save(_dummySoal(kategoriId: 'kat1'));

      expect(QuestionBox.instance.isKategoriDownloaded('kat1'), isTrue);
      expect(QuestionBox.instance.isKategoriDownloaded('kat_kosong'), isFalse);
    });

    test('deleteById() menghapus satu soal', () async {
      await QuestionBox.instance.save(_dummySoal(id: 'soal1'));
      await QuestionBox.instance.deleteById('soal1');

      expect(QuestionBox.instance.getById('soal1'), isNull);
    });

    test('deleteByKategori() hanya hapus soal dari kategori tersebut',
        () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1', kategoriId: 'kat1'),
        _dummySoal(id: 'soal2', kategoriId: 'kat1'),
        _dummySoal(id: 'soal3', kategoriId: 'kat2'),
      ]);

      await QuestionBox.instance.deleteByKategori('kat1');

      expect(QuestionBox.instance.getByKategori('kat1'), isEmpty);
      expect(QuestionBox.instance.getByKategori('kat2').length, equals(1));
    });

    test('clearAll() mengosongkan seluruh box', () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1'),
        _dummySoal(id: 'soal2'),
      ]);
      await QuestionBox.instance.clearAll();

      expect(QuestionBox.instance.getAll(), isEmpty);
    });
  });

  // ─── Group: CategoryBox ───────────────────────────────────────────────────

  group('CategoryBox', () {
    test('saveAll() dan getAll() berjalan benar', () async {
      await CategoryBox.instance.saveAll([
        _dummyKategori(id: 'kat1', nama: 'Basis Data'),
        _dummyKategori(id: 'kat2', nama: 'Sistem Operasi'),
      ]);
      expect(CategoryBox.instance.getAll().length, equals(2));
    });

    test('getById() mengembalikan kategori yang benar', () async {
      await CategoryBox.instance.save(_dummyKategori(id: 'kat1'));

      final result = CategoryBox.instance.getById('kat1');
      expect(result, isNotNull);
      expect(result!.nama, equals('Basis Data'));
    });

    test('hasData false sebelum ada data, true setelahnya', () async {
      expect(CategoryBox.instance.hasData, isFalse);

      await CategoryBox.instance.save(_dummyKategori());
      expect(CategoryBox.instance.hasData, isTrue);
    });
  });

  // ─── Group: OfflineQuestionService ───────────────────────────────────────

  group('OfflineQuestionService — offline fallback', () {
    test('load dari Hive berhasil jika soal sudah diunduh dan sedang offline',
        () async {
      await QuestionBox.instance.saveAll([
        _dummySoal(id: 'soal1', kategoriId: 'kat1'),
        _dummySoal(id: 'soal2', kategoriId: 'kat1'),
      ]);

      final result = await OfflineQuestionService.instance.loadByKategori(
        kategoriId: 'kat1',
        fetchFromRemote: (_) async =>
            throw Exception('Tidak ada koneksi internet'),
      );

      expect(result.isFromCache, isTrue);
      expect(result.questions.length, equals(2));
    });

    test('kembalikan error jika offline dan soal belum diunduh', () async {
      final result = await OfflineQuestionService.instance.loadByKategori(
        kategoriId: 'kat_belum_diunduh',
        fetchFromRemote: (_) async =>
            throw Exception('Tidak ada koneksi internet'),
      );

      expect(result.isEmpty, isTrue);
      expect(result.hasError, isTrue);
      expect(result.errorMessage, contains('belum diunduh'));
    });

    test('isAvailableOffline() sesuai dengan isi Hive', () async {
      await QuestionBox.instance.save(_dummySoal(kategoriId: 'kat1'));

      expect(
        OfflineQuestionService.instance.isAvailableOffline('kat1'),
        isTrue,
      );
      expect(
        OfflineQuestionService.instance.isAvailableOffline('kat_kosong'),
        isFalse,
      );
    });
  });
}