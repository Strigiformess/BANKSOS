// lib/data/local/boxes/question_box.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../models/question_model.dart';

/// Akses Hive box untuk data soal (offline storage).
///
/// Cara pakai:
///   // Simpan batch soal setelah download dari MongoDB
///   await QuestionBox.instance.saveAll(questions);
///
///   // Ambil semua soal satu kategori (mode offline)
///   final soal = QuestionBox.instance.getByKategori('kategoriId123');
///
///   // Cek apakah soal sudah diunduh
///   final sudah = QuestionBox.instance.isDownloaded('soalId456');
class QuestionBox {
  QuestionBox._();
  static final QuestionBox instance = QuestionBox._();

  Box<QuestionModel> get _box =>
      Hive.box<QuestionModel>(HiveBoxes.questions);

  // ─── Simpan ──────────────────────────────────────────────────────────────

  /// Simpan satu soal. Key = id soal dari MongoDB.
  Future<void> save(QuestionModel question) async {
    await _box.put(question.id, question);
  }

  /// Simpan banyak soal sekaligus (batch insert).
  /// Dipanggil setelah user tap "Unduh untuk Offline" per kategori.
  Future<void> saveAll(List<QuestionModel> questions) async {
    final Map<String, QuestionModel> entries = {
      for (final q in questions) q.id: q,
    };
    await _box.putAll(entries);
  }

  // ─── Baca ────────────────────────────────────────────────────────────────

  /// Ambil semua soal yang tersimpan di Hive.
  List<QuestionModel> getAll() {
    return _box.values.toList();
  }

  /// Ambil semua soal berdasarkan kategori.
  /// Dipakai saat mode offline — filter dari lokal, tidak ke server.
  List<QuestionModel> getByKategori(String kategoriId) {
    return _box.values
        .where((q) => q.kategoriId == kategoriId)
        .toList();
  }

  /// Ambil soal berdasarkan kategori DAN tingkat kesulitan.
  List<QuestionModel> getByKategoriDanKesulitan({
    required String kategoriId,
    required String tingkatKesulitan, // 'easy' | 'medium' | 'hard'
  }) {
    return _box.values
        .where((q) =>
            q.kategoriId == kategoriId &&
            q.tingkatKesulitan == tingkatKesulitan)
        .toList();
  }

  /// Ambil satu soal by id. Null jika tidak ditemukan.
  QuestionModel? getById(String id) {
    return _box.get(id);
  }

  /// True jika soal dengan id tersebut sudah ada di Hive.
  bool isDownloaded(String id) {
    return _box.containsKey(id);
  }

  /// True jika ada soal dari kategori tertentu yang sudah diunduh.
  bool isKategoriDownloaded(String kategoriId) {
    return _box.values.any((q) => q.kategoriId == kategoriId);
  }

  /// Jumlah soal yang sudah diunduh untuk satu kategori.
  int countByKategori(String kategoriId) {
    return _box.values.where((q) => q.kategoriId == kategoriId).length;
  }

  // ─── Hapus ───────────────────────────────────────────────────────────────

  /// Hapus satu soal by id.
  /// Dipanggil saat admin menonaktifkan/mengarsipkan soal.
  Future<void> deleteById(String id) async {
    await _box.delete(id);
  }

  /// Hapus semua soal dari satu kategori.
  Future<void> deleteByKategori(String kategoriId) async {
    final keysToDelete = _box.keys
        .where((key) {
          final q = _box.get(key);
          return q?.kategoriId == kategoriId;
        })
        .toList();

    await _box.deleteAll(keysToDelete);
  }

  /// Hapus semua soal dari Hive.
  /// Dipanggil saat logout dengan clearOfflineData = true.
  Future<void> clearAll() async {
    await _box.clear();
  }
}