/// Nama-nama HiveBox yang digunakan di seluruh aplikasi BANKSOS.
/// Selalu gunakan konstanta ini — jangan hardcode nama box di tempat lain.
class HiveBoxes {
  HiveBoxes._();

  /// Box untuk menyimpan sesi login pengguna yang sedang aktif.
  static const String session = 'session_box';

  /// Box untuk menyimpan soal yang sudah diunduh untuk akses offline.
  static const String questions = 'questions_box';

  /// Box untuk menyimpan daftar kategori mata kuliah.
  static const String categories = 'categories_box';

  /// Box untuk menyimpan riwayat pengerjaan soal.
  static const String progress = 'progress_box';

  /// Box untuk menyimpan daftar soal yang di-bookmark.
  static const String bookmarks = 'bookmarks_box';

  /// Box untuk antrian sinkronisasi data offline ke server.
  static const String syncQueue = 'sync_queue_box';
}
