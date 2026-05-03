import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../models/category_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/bookmark_model.dart';
import '../../models/sync_queue_model.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/session_service.dart';

/// Service untuk inisialisasi dan pengelolaan Hive.
///
/// Panggil HiveService.init() di main.dart sebelum runApp()
/// untuk membuka semua box dan mendaftarkan semua adapter.
class HiveService {
  HiveService._();

  /// Inisialisasi Hive: daftarkan adapter dan buka semua box.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Daftarkan semua TypeAdapter (di-generate oleh build_runner)
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(QuestionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserProgressModelAdapter());
    Hive.registerAdapter(BookmarkModelAdapter());
    Hive.registerAdapter(SyncQueueModelAdapter());

    // Buka semua box
    await Hive.openBox(HiveBoxes.session);
    await Hive.openBox<QuestionModel>(HiveBoxes.questions);
    await Hive.openBox<CategoryModel>(HiveBoxes.categories);
    await Hive.openBox<UserProgressModel>(HiveBoxes.progress);
    await Hive.openBox<BookmarkModel>(HiveBoxes.bookmarks);
    await Hive.openBox<SyncQueueModel>(HiveBoxes.syncQueue);

    // Inisialisasi session service
    await SessionService.instance.init();
  }
}
