import 'package:banksos/data/local/hive/hive_service.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/data/remote/mongodb/mongodb_service.dart';
import 'package:banksos/core/config/db_config.dart';

abstract class IQuestionRepository {
  Future<List<QuestionModel>> getQuestionsByCategory({
    required String kategoriId,
    String? filterKesulitan,
  });

  Future<QuestionModel?> getQuestionById(String questionId);
}

class QuestionRepository implements IQuestionRepository {
  final MongoDBService _db;
  final HiveService _hive;

  QuestionRepository({
    MongoDBService? db,
    HiveService? hive,
  })  : _db = db ?? MongoDBService.instance,
        _hive = hive ?? HiveService.instance;

  @override
  Future<List<QuestionModel>> getQuestionsByCategory({
    required String kategoriId,
    String? filterKesulitan,
  }) async {
    try {
      if (!_db.isConnected) {
        return _getFromHive(kategoriId, filterKesulitan);
      }

      final selector = {
        'kategori_id': kategoriId,
        'status': 'published',
        if (filterKesulitan != null && filterKesulitan != 'semua')
          'tingkat_kesulitan': filterKesulitan,
      };

      final results = await _db.questions
          .find(selector)
          .toList();

      final questions = results
          .map((map) => QuestionModel.fromMap(map))
          .toList();

      return questions;
    } catch (e) {
      return _getFromHive(kategoriId, filterKesulitan);
    }
  }

  List<QuestionModel> _getFromHive(
    String kategoriId,
    String? filterKesulitan,
  ) {
    final box = _hive.questionsBox;
    final all = box.values.where((q) {
      final matchKategori = q.kategoriId == kategoriId;
      final matchKesulitan = filterKesulitan == null ||
          filterKesulitan == 'semua' ||
          q.tingkatKesulitan.name == filterKesulitan;
      return matchKategori && matchKesulitan;
    }).toList();

    return all;
  }

  @override
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final fromHive = _hive.questionsBox.get(questionId);
      if (fromHive != null) return fromHive;

      if (!_db.isConnected) return null;

      final result = await _db.questions
          .findOne({'_id': questionId});

      if (result == null) return null;
      return QuestionModel.fromMap(result);
    } catch (e) {
      return null;
    }
  }
}