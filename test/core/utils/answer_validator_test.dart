// test/core/utils/answer_validator_test.dart
//
// Unit test untuk AnswerValidator — business logic validasi jawaban.
// Test ini murni Dart, tidak butuh Hive, MongoDB, atau network.

import 'package:flutter_test/flutter_test.dart';
import 'package:banksos/core/utils/answer_validator.dart';

void main() {
  group('AnswerValidator.checkAnswer()', () {
    // ─── Input kosong ────────────────────────────────────────────────────

    group('input kosong', () {
      test('string kosong "" dianggap salah dengan feedback yang sesuai', () {
        final result = AnswerValidator.checkAnswer(
          userInput: '',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isFalse);
        expect(result.feedback, contains('kosong'));
      });

      test('string hanya spasi "   " dianggap kosong dan salah', () {
        final result = AnswerValidator.checkAnswer(
          userInput: '   ',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isFalse);
        expect(result.feedback, contains('kosong'));
      });
    });

    // ─── Jawaban benar ────────────────────────────────────────────────────

    group('jawaban benar', () {
      test('input sama persis dengan kunci jawaban → isCorrect true', () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'normalisasi',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isTrue);
        expect(result.feedback, contains('Benar'));
      });

      test(
          'perbandingan case-insensitive: "NoRmAlIsAsI" cocok dengan "normalisasi"',
          () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'NoRmAlIsAsI',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isTrue);
      });

      test('spasi di awal dan akhir di-trim: "  normalisasi  " cocok', () {
        final result = AnswerValidator.checkAnswer(
          userInput: '  normalisasi  ',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isTrue);
      });

      test(
          'spasi ganda di tengah di-normalize: "basis  data" cocok dengan "basis data"',
          () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'basis  data',
          correctAnswer: 'basis data',
        );

        expect(result.isCorrect, isTrue);
      });

      test('kombinasi uppercase + spasi berlebih + trim semuanya di-handle',
          () {
        final result = AnswerValidator.checkAnswer(
          userInput: '  SISTEM   OPERASI  ',
          correctAnswer: 'sistem operasi',
        );

        expect(result.isCorrect, isTrue);
      });
    });

    // ─── Jawaban salah ────────────────────────────────────────────────────

    group('jawaban salah', () {
      test(
          'input yang berbeda arti → isCorrect false dengan feedback yang sesuai',
          () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'denormalisasi',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isFalse);
        expect(result.feedback, contains('salah'));
      });

      test('ejaan yang mirip tapi berbeda tetap dianggap salah', () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'normalissasi',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isFalse);
      });

      test('jawaban parsial (substring) tidak dianggap benar', () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'normal',
          correctAnswer: 'normalisasi',
        );

        expect(result.isCorrect, isFalse);
      });
    });

    // ─── Kunci jawaban yang kompleks ─────────────────────────────────────

    group('kunci jawaban kompleks', () {
      test('kunci jawaban uppercase, input lowercase → benar', () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'foreign key',
          correctAnswer: 'FOREIGN KEY',
        );

        expect(result.isCorrect, isTrue);
      });

      test('kunci jawaban dengan angka perlu sama persis (setelah normalize)',
          () {
        final result = AnswerValidator.checkAnswer(
          userInput: 'OSI Model 7 Layer',
          correctAnswer: 'osi model 7 layer',
        );

        expect(result.isCorrect, isTrue);
      });
    });
  });
}
