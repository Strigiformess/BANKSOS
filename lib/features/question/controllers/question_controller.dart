// lib/features/question/controllers/question_controller.dart
// PIC: Revaldi (RP)
// Sprint 2: Implementasi logic dan state management fitur kerjakan soal

import 'package:flutter/foundation.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/features/question/repositories/question_repository.dart';

enum QuestionLoadState { idle, loading, loaded, error }

class QuestionController extends ChangeNotifier {
  final IQuestionRepository _repository;

  QuestionController({IQuestionRepository? repository})
      : _repository = repository ?? QuestionRepository();

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

  void reset() {
    _questions = [];
    _state = QuestionLoadState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}