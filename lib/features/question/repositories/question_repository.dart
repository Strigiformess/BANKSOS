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

  /// Strip wrapper ObjectId("...") jadi 24-hex murni
  static String _toHex(String raw) {
    final match = RegExp(
      r'''ObjectId\(["']?([0-9a-fA-F]{24})["']?\)''',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match != null) return match.group(1)!;
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(raw)) return raw;
    final anyHex = RegExp(r'([0-9a-fA-F]{24})').firstMatch(raw);
    if (anyHex != null) return anyHex.group(1)!;
    return raw;
  }

  @override
  Future<List<QuestionModel>> getQuestionsByCategory({
    required String kategoriId,
    String? filterKesulitan,
  }) async {
    try {
      if (!_db.isConnected) {
        return _getFromHive(kategoriId, filterKesulitan);
      }

      // Selalu query dengan ObjectId, bukan string mentah
      final kategoriOid = ObjectId.parse(_toHex(kategoriId));

      final selector = <String, dynamic>{
        'kategori_id': kategoriOid,
        'status': 'published',
        if (filterKesulitan != null && filterKesulitan != 'semua')
          'tingkat_kesulitan': filterKesulitan,
      };

      final results = await _db.questions.find(selector).toList();

      return results.map((map) => QuestionModel.fromMap(map)).toList();
    } catch (e) {
      return _getFromHive(kategoriId, filterKesulitan);
    }
  }

  List<QuestionModel> _getFromHive(
    String kategoriId,
    String? filterKesulitan,
  ) {
    final box = _hive.questionsBox;
    return box.values.where((q) {
      final matchKategori = q.kategoriId == _toHex(kategoriId);
      final matchKesulitan = filterKesulitan == null ||
          filterKesulitan == 'semua' ||
          q.tingkatKesulitan.name == filterKesulitan;
      return matchKategori && matchKesulitan;
    }).toList();
  }

  @override
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final hexId = _toHex(questionId);
      final fromHive = _hive.questionsBox.get(hexId);
      if (fromHive != null) return fromHive;

      if (!_db.isConnected) return null;

      final result = await _db.questions
          .findOne({'_id': ObjectId.parse(hexId)});

      if (result == null) return null;
      return QuestionModel.fromMap(result);
    } catch (e) {
      return null;
    }
  }
}