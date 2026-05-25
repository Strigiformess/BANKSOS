import 'package:hive/hive.dart';

part 'user_progress_model.g.dart';

/// Model riwayat pengerjaan soal oleh pengguna.
/// Berkorespondensi dengan collection "user_progress" di MongoDB
/// dan HiveBox "progress_box" untuk menyimpan progres offline.
///
/// Catatan: hanya soal yang berhasil dijawab benar yang dicatat
/// ke dalam riwayat pengerjaan.
@HiveType(typeId: 6)
class UserProgressModel extends HiveObject {
  /// ID unik rekap progress dari MongoDB (_id).
  @HiveField(0)
  final String id;

  /// ID pengguna (referensi ke UserModel).
  @HiveField(1)
  final String userId;

  /// ID soal (referensi ke QuestionModel).
  @HiveField(2)
  final String questionId;

  /// True jika soal sudah berhasil dijawab dengan benar.
  @HiveField(3)
  final bool isSolved;

  /// Tanggal dan waktu soal pertama kali dijawab dengan benar.
  /// Null jika soal belum diselesaikan.
  @HiveField(4)
  final DateTime? solvedAt;

  /// Jumlah total percobaan menjawab soal ini.
  @HiveField(5)
  final int attemptCount;

  /// Penanda apakah data ini sudah disinkronisasi ke server.
  /// false = data masih tersimpan lokal (pending sync).
  /// true  = data sudah berhasil dikirim ke MongoDB.
  @HiveField(6)
  final bool isSynced;

  UserProgressModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.isSolved,
    this.solvedAt,
    required this.attemptCount,
    required this.isSynced,
  });

  factory UserProgressModel.fromMap(Map<String, dynamic> map) {
    return UserProgressModel(
      id: map['_id']?.toString() ?? map['id'] ?? '',
      userId: map['user_id']?.toString() ?? '',
      questionId: map['question_id']?.toString() ?? '',
      isSolved: map['is_solved'] ?? false,
      solvedAt: map['solved_at'] != null
          ? DateTime.tryParse(map['solved_at'].toString())
          : null,
      attemptCount: map['attempt_count'] ?? 0,
      isSynced: map['is_synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'user_id': userId,
      'question_id': questionId,
      'is_solved': isSolved,
      'solved_at': solvedAt?.toIso8601String(),
      'attempt_count': attemptCount,
      'is_synced': isSynced,
    };
  }

  UserProgressModel copyWith({
    String? id,
    String? userId,
    String? questionId,
    bool? isSolved,
    DateTime? solvedAt,
    int? attemptCount,
    bool? isSynced,
  }) {
    return UserProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      isSolved: isSolved ?? this.isSolved,
      solvedAt: solvedAt ?? this.solvedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
