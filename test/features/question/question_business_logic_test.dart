// test/features/question/question_business_logic_test.dart
//
// Unit test untuk business logic seputar soal:
//   1. QuestionModel.checkAnswer()           — validasi jawaban di model
//   2. QuestionSubmitRepository._validasi()  — aturan pengajuan soal baru
//   3. Kalkulasi reward points kontribusi    — poin per soal published
//
// Test ini murni Dart — tidak butuh Hive, MongoDB, atau network.

import 'package:flutter_test/flutter_test.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/features/question/repositories/question_submit_repository.dart';

// ─── Helper: buat QuestionModel dummy ─────────────────────────────────────────

QuestionModel _buatSoal({
  String id = 'soal1',
  String pertanyaan = 'Apa itu normalisasi database?',
  String jawaban = 'proses mengurangi redundansi data',
  DifficultyLevel tingkat = DifficultyLevel.easy,
  QuestionStatus status = QuestionStatus.published,
}) {
  return QuestionModel(
    id: id,
    pertanyaan: pertanyaan,
    jawaban: jawaban,
    kategoriId: 'kat1',
    kategoriNama: 'Basis Data',
    tingkatKesulitan: tingkat,
    status: status,
    hints: [],
    submittedBy: 'user1',
    solveCount: 0,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

// ─── Helper: kalkulasi reward points (sama dengan logika di kontribusiProvider) ─

int _hitungRewardPoints(List<QuestionModel> soalUser) {
  const int poinPerPublished = 50;
  return soalUser.where((q) => q.status == QuestionStatus.published).length *
      poinPerPublished;
}

// ─── Helper: akses @visibleForTesting validasi() ──────────────────────────────
// QuestionSubmitRepository.validasi() dipublikasikan via @visibleForTesting
// sehingga bisa diuji langsung tanpa subclass.
// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════════
  // 1. QuestionModel.checkAnswer()
  // ══════════════════════════════════════════════════════════════════════════════

  group('QuestionModel.checkAnswer()', () {
    test('jawaban benar (exact) → true', () {
      final soal = _buatSoal(jawaban: 'entity');
      expect(soal.checkAnswer('entity'), isTrue);
    });

    test('jawaban benar case-insensitive → true', () {
      final soal = _buatSoal(jawaban: 'entity');
      expect(soal.checkAnswer('ENTITY'), isTrue);
      expect(soal.checkAnswer('Entity'), isTrue);
    });

    test('jawaban benar dengan spasi di awal/akhir → true', () {
      final soal = _buatSoal(jawaban: 'foreign key');
      expect(soal.checkAnswer('  foreign key  '), isTrue);
    });

    test('jawaban salah → false', () {
      final soal = _buatSoal(jawaban: 'entity');
      expect(soal.checkAnswer('attribute'), isFalse);
    });

    test('jawaban kosong → false', () {
      final soal = _buatSoal(jawaban: 'entity');
      expect(soal.checkAnswer(''), isFalse);
    });

    test(
        'kunci jawaban yang disimpan uppercase, input lowercase → true '
        '(model menyimpan jawaban lowercase per spec)', () {
      // Model menyimpan jawaban lowercase (fromMap: jawaban.toLowerCase())
      // Namun checkAnswer juga trim+lowercase, sehingga tetap konsisten
      final soal = _buatSoal(jawaban: 'primary key');
      expect(soal.checkAnswer('primary key'), isTrue);
      expect(soal.checkAnswer('PRIMARY KEY'), isTrue);
    });

    test('jawaban parsial (hanya sebagian) → false', () {
      final soal = _buatSoal(jawaban: 'normalisasi database');
      expect(soal.checkAnswer('normalisasi'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 2. QuestionSubmitRepository — validasi field soal baru
  //    Mengakses logika lewat subclass karena _validasi adalah protected
  // ══════════════════════════════════════════════════════════════════════════════

  group('QuestionSubmitRepository — validasi soal baru', () {
    final repo = QuestionSubmitRepository();

    SoalBaru _soalValid() => const SoalBaru(
          pertanyaan: 'Apa yang dimaksud dengan normalisasi database?',
          jawaban: 'menghilangkan redundansi',
          kategoriId: 'kat_bd_001',
          kategoriNama: 'Basis Data',
        );

    test('soal valid tidak menghasilkan error', () {
      expect(repo.validasi(_soalValid()), isNull);
    });

    test('pertanyaan kosong → pesan error yang sesuai', () {
      final soal = SoalBaru(
        pertanyaan: '',
        jawaban: 'jawaban',
        kategoriId: 'kat1',
        kategoriNama: 'Basis Data',
      );
      final err = repo.validasi(soal);
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('pertanyaan'));
    });

    test('pertanyaan hanya spasi → dianggap kosong', () {
      final soal = SoalBaru(
        pertanyaan: '   ',
        jawaban: 'jawaban',
        kategoriId: 'kat1',
        kategoriNama: 'Basis Data',
      );
      expect(repo.validasi(soal), isNotNull);
    });

    test('pertanyaan kurang dari 10 karakter → pesan error "terlalu singkat"',
        () {
      final soal = SoalBaru(
        pertanyaan: 'Apa itu?',
        jawaban: 'jawaban',
        kategoriId: 'kat1',
        kategoriNama: 'Basis Data',
      );
      final err = repo.validasi(soal);
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('singkat'));
    });

    test('pertanyaan tepat 10 karakter → valid (boundary test)', () {
      final soal = SoalBaru(
        pertanyaan: '1234567890',
        jawaban: 'jawaban',
        kategoriId: 'kat1',
        kategoriNama: 'Basis Data',
      );
      expect(repo.validasi(soal), isNull);
    });

    test('jawaban kosong → pesan error yang sesuai', () {
      final soal = SoalBaru(
        pertanyaan: 'Pertanyaan yang valid lebih dari 10 karakter',
        jawaban: '',
        kategoriId: 'kat1',
        kategoriNama: 'Basis Data',
      );
      final err = repo.validasi(soal);
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('jawaban'));
    });

    test('kategoriId kosong → pesan error yang sesuai', () {
      final soal = SoalBaru(
        pertanyaan: 'Pertanyaan yang valid lebih dari 10 karakter',
        jawaban: 'jawaban valid',
        kategoriId: '',
        kategoriNama: 'Basis Data',
      );
      final err = repo.validasi(soal);
      expect(err, isNotNull);
      // Pesan menggunakan "mata kuliah" (sesuai teks di repository)
      expect(err!.toLowerCase(), contains('mata kuliah'));
    });

    test('error pertama yang muncul adalah pertanyaan kosong, bukan jawaban',
        () {
      // Validasi dilakukan berurutan: pertanyaan dulu, baru jawaban
      final soal = SoalBaru(
        pertanyaan: '',
        jawaban: '',
        kategoriId: '',
        kategoriNama: '',
      );
      final err = repo.validasi(soal);
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('pertanyaan'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 3. Kalkulasi reward points kontribusi
  //    (logika dari rewardPointsProvider di kontribusi_controller.dart)
  // ══════════════════════════════════════════════════════════════════════════════

  group('Kalkulasi reward points kontribusi', () {
    test('0 soal → 0 poin', () {
      expect(_hitungRewardPoints([]), equals(0));
    });

    test('1 soal published → 50 poin', () {
      final soal = [_buatSoal(status: QuestionStatus.published)];
      expect(_hitungRewardPoints(soal), equals(50));
    });

    test('3 soal published → 150 poin', () {
      final soal = [
        _buatSoal(id: 's1', status: QuestionStatus.published),
        _buatSoal(id: 's2', status: QuestionStatus.published),
        _buatSoal(id: 's3', status: QuestionStatus.published),
      ];
      expect(_hitungRewardPoints(soal), equals(150));
    });

    test('soal dengan status pending/rejected tidak dihitung sebagai poin', () {
      final soal = [
        _buatSoal(id: 's1', status: QuestionStatus.published),
        _buatSoal(id: 's2', status: QuestionStatus.pending),
        _buatSoal(id: 's3', status: QuestionStatus.rejected),
      ];
      // Hanya 1 yang published → 50 poin
      expect(_hitungRewardPoints(soal), equals(50));
    });

    test('semua soal pending → 0 poin', () {
      final soal = [
        _buatSoal(id: 's1', status: QuestionStatus.pending),
        _buatSoal(id: 's2', status: QuestionStatus.pending),
      ];
      expect(_hitungRewardPoints(soal), equals(0));
    });

    test('mix semua status: hanya yang published yang menghasilkan poin', () {
      final soal = [
        _buatSoal(id: 's1', status: QuestionStatus.published),
        _buatSoal(id: 's2', status: QuestionStatus.rejected),
        _buatSoal(id: 's3', status: QuestionStatus.archived),
        _buatSoal(id: 's4', status: QuestionStatus.inactive),
        _buatSoal(id: 's5', status: QuestionStatus.revisionRequired),
        _buatSoal(id: 's6', status: QuestionStatus.published),
      ];
      // 2 published × 50 = 100
      expect(_hitungRewardPoints(soal), equals(100));
    });
  });
}
