// lib/features/question/controllers/question_controller.dart
// PIC: Revaldi (RP)
// Sprint 2: Implementasi logic dan state management fitur kerjakan soal

import 'package:flutter/foundation.dart';
import 'package:banksos/data/local/hive/hive_service.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/features/question/repositories/question_repository.dart';
import 'package:banksos/features/question/repositories/question_submit_repository.dart';

enum QuestionLoadState { idle, loading, loaded, error }

class QuestionController extends ChangeNotifier {
  final IQuestionRepository _repository;
  final IQuestionSubmitRepository _submitRepository;

  QuestionController({
    IQuestionRepository? repository,
    IQuestionSubmitRepository? submitRepository,
  })  : _repository = repository ?? QuestionRepository(),
        _submitRepository = submitRepository ?? QuestionSubmitRepository();

  QuestionLoadState _state = QuestionLoadState.idle;
  List<QuestionModel> _questions = [];
  String? _errorMessage;
  String _activeFilter = 'semua';

  QuestionLoadState get state => _state;
  List<QuestionModel> get questions => _questions;
  String? get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;
  bool get isLoading => _state == QuestionLoadState.loading;

  Future<void> loadQuestions({
    required String kategoriId,
    String? filter,
  }) async {
    _state = QuestionLoadState.loading;
    _activeFilter = filter ?? 'semua';
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getQuestionsByCategory(
        kategoriId: kategoriId,
        filterKesulitan: _activeFilter == 'semua' ? null : _activeFilter,
      );

      _questions = result;
      _state = QuestionLoadState.loaded;
    } catch (e) {
      _errorMessage = 'Gagal memuat soal: ${e.toString()}';
      _state = QuestionLoadState.error;
    }

    notifyListeners();
  }

  void changeFilter(String filter, String kategoriId) {
    if (_activeFilter == filter) return;
    loadQuestions(kategoriId: kategoriId, filter: filter);
  }

  Future<QuestionSubmitResult> tambahSoal({
    required String pertanyaan,
    required String jawaban,
    required String kategoriNama,
  }) async {
    final kategori = HiveService.instance.categoriesBox.values
        .where((c) => c.nama == kategoriNama)
        .firstOrNull;

    if (kategori == null) {
      return const QuestionSubmitResult(
        success: false,
        errorMessage: 'Kategori tidak ditemukan. Muat ulang data kategori.',
      );
    }

    return _submitRepository.ajukanSoal(
      SoalBaru(
        pertanyaan: pertanyaan,
        jawaban: jawaban,
        kategoriId: kategori.id,
        kategoriNama: kategori.nama,
      ),
    );
  }

  void reset() {
    _questions = [];
    _state = QuestionLoadState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
