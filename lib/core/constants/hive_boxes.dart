// lib/core/constants/hive_boxes.dart

class HiveBoxes {
  HiveBoxes._();

  // Auth & session
  static const String session = 'session_box';

  // Data utama
  static const String questions = 'questions_box';
  static const String categories = 'categories_box';

  // Progress & bookmark
  static const String userProgress = 'user_progress_box';
  static const String bookmarks = 'bookmarks_box';

  // Antrian sinkronisasi offline
  static const String syncQueue = 'sync_queue_box';
}