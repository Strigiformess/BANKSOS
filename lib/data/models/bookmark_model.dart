import 'package:hive/hive.dart';

part 'bookmark_model.g.dart';

/// Model bookmark soal.
/// Berkorespondensi dengan collection "bookmarks" di MongoDB
/// dan HiveBox "bookmarks_box" untuk akses offline.
///
/// Pengguna dapat mem-bookmark soal yang ingin dikerjakan
/// atau dipelajari kembali di kemudian hari.
@HiveType(typeId: 5)
class BookmarkModel extends HiveObject {
  /// ID unik bookmark dari MongoDB (_id).
  @HiveField(0)
  final String id;

  /// ID pengguna yang melakukan bookmark (referensi ke UserModel).
  @HiveField(1)
  final String userId;

  /// ID soal yang di-bookmark (referensi ke QuestionModel).
  @HiveField(2)
  final String questionId;

  /// Tanggal dan waktu bookmark dibuat.
  @HiveField(3)
  final DateTime createdAt;

  /// Penanda apakah data ini sudah disinkronisasi ke server.
  @HiveField(4)
  final bool isSynced;

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.createdAt,
    required this.isSynced,
  });

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['_id']?.toString() ?? map['id'] ?? '',
      userId: map['user_id']?.toString() ?? '',
      questionId: map['question_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      isSynced: map['is_synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'user_id': userId,
      'question_id': questionId,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  BookmarkModel copyWith({
    String? id,
    String? userId,
    String? questionId,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
