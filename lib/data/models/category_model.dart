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
  @HiveField(5)
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
       id: _parseObjectId(map['_id']),
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

  static String _parseObjectId(dynamic value) {
  if (value == null) return '';
  final raw = value.toString();
  // Kalau formatnya ObjectId("abc123..."), ambil isinya saja
  final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(raw);
  if (match != null) return match.group(1)!;
  return raw; // sudah string biasa, langsung pakai
}
}
