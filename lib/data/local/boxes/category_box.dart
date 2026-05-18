import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../models/category_model.dart';

/// Akses Hive box untuk data kategori mata kuliah.
///
/// Cara pakai:
///   // Simpan semua kategori (setelah download dari MongoDB)
///   await CategoryBox.instance.saveAll(categories);
///
///   // Ambil semua kategori aktif
///   final categories = CategoryBox.instance.getAll();
class CategoryBox {
  CategoryBox._();
  static final CategoryBox instance = CategoryBox._();

  Box<CategoryModel> get _box =>
      Hive.box<CategoryModel>(HiveBoxes.categories);

  // ─── Simpan ──────────────────────────────────────────────────────────────

  /// Simpan satu kategori. Key = id kategori dari MongoDB.
  Future<void> save(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  /// Simpan banyak kategori sekaligus (batch insert).
  /// Dipanggil setelah fetch kategori dari MongoDB saat pertama login.
  Future<void> saveAll(List<CategoryModel> categories) async {
    final Map<String, CategoryModel> entries = {
      for (final c in categories) c.id: c,
    };
    await _box.putAll(entries);
  }

  // ─── Baca ────────────────────────────────────────────────────────────────

  /// Ambil semua kategori yang tersimpan di Hive.
  List<CategoryModel> getAll() {
    return _box.values.toList();
  }

  /// Ambil hanya kategori yang is_active = true.
  List<CategoryModel> getAllActive() {
    return _box.values.where((c) => c.isActive).toList();
  }

  /// Ambil satu kategori by id. Null jika tidak ditemukan.
  CategoryModel? getById(String id) {
    return _box.get(id);
  }

  /// True jika sudah ada kategori tersimpan di Hive.
  /// Dipakai untuk memutuskan apakah perlu fetch ulang dari server.
  bool get hasData => _box.isNotEmpty;

  // ─── Hapus ───────────────────────────────────────────────────────────────

  /// Hapus semua kategori dari Hive.
  /// Dipanggil saat logout atau saat perlu refresh data dari server.
  Future<void> clearAll() async {
    await _box.clear();
  }
}