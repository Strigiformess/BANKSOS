import 'package:banksos/data/local/hive/hive_service.dart';
import 'package:banksos/data/models/question_model.dart';
import 'package:banksos/data/remote/mongodb/mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

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

      final cleanId = _cleanId(kategoriId);
      final selector = {
        'kategori_id': ObjectId.parse(cleanId),
        'status': 'published',
        if (filterKesulitan != null && filterKesulitan != 'semua')
          'tingkat_kesulitan': filterKesulitan,
      };

      final results = await _db.questions.find(selector).toList();
      final questions = results.map((map) => QuestionModel.fromMap(map)).toList();

      for (final q in questions) {
        await _hive.questionsBox.put(q.id, q);
      }

      return questions;
    } catch (e) {
      return _getFromHive(kategoriId, filterKesulitan);
    }
  }

  List<QuestionModel> _getFromHive(
    String kategoriId,
    String? filterKesulitan,
  ) {
    final cleanId = _cleanId(kategoriId);
    final box = _hive.questionsBox;
    return box.values.where((q) {
      final matchKategori = _cleanId(q.kategoriId) == cleanId;
      final matchKesulitan = filterKesulitan == null ||
          filterKesulitan == 'semua' ||
          q.tingkatKesulitan.name == filterKesulitan;
      final isPublished = q.status == QuestionStatus.published;
      return matchKategori && matchKesulitan && isPublished;
    }).toList();
  }

  @override
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final cleanId = _cleanId(questionId);

      final fromHive = _hive.questionsBox.get(cleanId);
      if (fromHive != null) return fromHive;

      if (!_db.isConnected) return null;

      final result = await _db.questions.findOne({'_id': ObjectId.parse(cleanId)});
      if (result == null) return null;
      return QuestionModel.fromMap(result);
    } catch (e) {
      return null;
    }
  }

  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    return match != null ? match.group(1)! : id;
  }
}