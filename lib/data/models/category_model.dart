import 'package:hive/hive.dart';

part 'category_model.g.dart';

/// Model kategori mata kuliah.
/// Berkorespondensi dengan collection "categories" di MongoDB
/// dan HiveBox "categories_box" untuk akses offline.
@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  /// ID unik kategori dari MongoDB (_id).
  @HiveField(0)
  final String id;

  /// Nama mata kuliah. Contoh: 'Basis Data', 'Sistem Operasi'.
  @HiveField(1)
  final String nama;

  /// Deskripsi singkat mata kuliah.
  @HiveField(2)
  final String deskripsi;

  /// Status aktif kategori.
  /// Jika false, kategori tidak ditampilkan kepada pengguna.
  @HiveField(3)
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.isActive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['_id']?.toString() ?? '',
      nama: map['nama'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? nama,
    String? deskripsi,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      deskripsi: deskripsi ?? this.deskripsi,
      isActive: isActive ?? this.isActive,
    );
  }
}
