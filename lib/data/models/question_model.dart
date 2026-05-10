import 'package:hive/hive.dart';

part 'question_model.g.dart';

/// Status soal dalam siklus hidup BANKSOS.
enum QuestionStatus { pending, published, rejected, archived, inactive, revisionRequired }

/// Tingkat kesulitan soal, ditentukan oleh reviewer.
enum DifficultyLevel { easy, medium, hard }

/// Model soal BANKSOS.
/// Berkorespondensi dengan collection "questions" di MongoDB
/// dan HiveBox "questions_box" untuk akses offline.
@HiveType(typeId: 1)
class QuestionModel extends HiveObject {
  /// ID unik soal dari MongoDB (_id).
  @HiveField(0)
  final String id;

  /// Teks pertanyaan soal.
  @HiveField(1)
  final String pertanyaan;

  /// Jawaban yang benar. Disimpan dalam lowercase agar
  /// perbandingan jawaban user bersifat tidak case-sensitive.
  @HiveField(2)
  final String jawaban;

  /// ID kategori mata kuliah (referensi ke CategoryModel).
  @HiveField(3)
  final String kategoriId;

  /// Nama kategori mata kuliah (disimpan lokal agar tidak perlu
  /// join saat akses offline).
  @HiveField(4)
  final String kategoriNama;

  /// Tingkat kesulitan: easy | medium | hard.
  @HiveField(5)
  final DifficultyLevel tingkatKesulitan;

  /// Status soal: pending | published | rejected | archived | inactive | revisionRequired.
  @HiveField(6)
  final QuestionStatus status;

  /// Daftar hint yang tersedia untuk soal ini.
  /// Seluruh hint langsung tersedia tanpa mekanisme unlock bertahap.
  @HiveField(7)
  final List<String> hints;

  /// ID pengguna yang mengajukan soal (referensi ke UserModel).
  @HiveField(8)
  final String submittedBy;

  /// ID reviewer yang memproses soal. Null jika belum direview.
  @HiveField(9)
  final String? reviewedBy;

  /// Alasan penolakan dari reviewer. Diisi hanya jika status = rejected.
  @HiveField(10)
  final String? rejectionReason;

  /// Jumlah pengguna yang berhasil menyelesaikan soal (fitur opsional).
  @HiveField(11)
  final int solveCount;

  /// Tanggal soal dibuat atau diajukan.
  @HiveField(12)
  final DateTime createdAt;

  /// Tanggal data soal terakhir diperbarui.
  @HiveField(13)
  final DateTime updatedAt;

  QuestionModel({
    required this.id,
    required this.pertanyaan,
    required this.jawaban,
    required this.kategoriId,
    required this.kategoriNama,
    required this.tingkatKesulitan,
    required this.status,
    required this.hints,
    required this.submittedBy,
    this.reviewedBy,
    this.rejectionReason,
    this.solveCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Memeriksa apakah jawaban user benar.
  /// Perbandingan dilakukan dalam lowercase (tidak case-sensitive).
  bool checkAnswer(String userAnswer) {
    return userAnswer.trim().toLowerCase() == jawaban.trim().toLowerCase();
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['_id']?.toString() ?? '',
      pertanyaan: map['pertanyaan'] ?? '',
      jawaban: (map['jawaban'] ?? '').toString().toLowerCase(),
      kategoriId: map['kategori_id']?.toString() ?? '',
      kategoriNama: map['kategori_nama'] ?? '',
      tingkatKesulitan: _difficultyFromString(map['tingkat_kesulitan']),
      status: _statusFromString(map['status']),
      hints: List<String>.from(map['hints'] ?? []),
      submittedBy: map['submitted_by']?.toString() ?? '',
      reviewedBy: map['reviewed_by']?.toString(),
      rejectionReason: map['rejection_reason'],
      solveCount: map['solve_count'] ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'pertanyaan': pertanyaan,
      'jawaban': jawaban,
      'kategori_id': kategoriId,
      'kategori_nama': kategoriNama,
      'tingkat_kesulitan': tingkatKesulitan.name,
      'status': status.name,
      'hints': hints,
      'submitted_by': submittedBy,
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'solve_count': solveCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  QuestionModel copyWith({
    String? id,
    String? pertanyaan,
    String? jawaban,
    String? kategoriId,
    String? kategoriNama,
    DifficultyLevel? tingkatKesulitan,
    QuestionStatus? status,
    List<String>? hints,
    String? submittedBy,
    String? reviewedBy,
    String? rejectionReason,
    int? solveCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      jawaban: jawaban ?? this.jawaban,
      kategoriId: kategoriId ?? this.kategoriId,
      kategoriNama: kategoriNama ?? this.kategoriNama,
      tingkatKesulitan: tingkatKesulitan ?? this.tingkatKesulitan,
      status: status ?? this.status,
      hints: hints ?? this.hints,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      solveCount: solveCount ?? this.solveCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DifficultyLevel _difficultyFromString(String? value) {
    switch (value) {
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.easy;
    }
  }

  static QuestionStatus _statusFromString(String? value) {
    switch (value) {
      case 'published':
        return QuestionStatus.published;
      case 'rejected':
        return QuestionStatus.rejected;
      case 'archived':
        return QuestionStatus.archived;
      case 'inactive':
        return QuestionStatus.inactive;
      case 'revision_required':
        return QuestionStatus.revisionRequired;
      default:
        return QuestionStatus.pending;
    }
  }
}
