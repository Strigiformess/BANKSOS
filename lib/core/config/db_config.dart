/// Konfigurasi koneksi MongoDB Atlas untuk aplikasi BANKSOS.
class DbConfig {
  DbConfig._();

  /// Nama database di MongoDB Atlas.
  static const String dbName = 'banksos_db';

  /// Nama semua collection.
  static const String colUsers = 'users';
  static const String colQuestions = 'questions';
  static const String colCategories = 'categories';
  static const String colUserProgress = 'user_progress';
  static const String colBookmarks = 'bookmarks';
}
