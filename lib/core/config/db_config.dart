import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbConfig {
  static String get mongoUri => dotenv.env['MONGO_URI'] ?? '';

  /// Nama database di MongoDB Atlas.
  static const String dbName = 'banksos_db';

  /// Nama semua collection.
  static const String colUsers = 'users';
  static const String colQuestions = 'questions';
  static const String colCategories = 'categories';
  static const String colUserProgress = 'user_progress';
  static const String colBookmarks = 'bookmarks';
}
