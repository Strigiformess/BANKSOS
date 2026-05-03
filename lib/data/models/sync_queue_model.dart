import 'package:hive/hive.dart';

part 'sync_queue_model.g.dart';

/// Jenis data yang ada dalam antrian sinkronisasi.
enum SyncType { progress, bookmark }

/// Model antrian sinkronisasi offline ke cloud.
/// Hanya disimpan di Hive lokal — tidak ada collection MongoDB untuk ini.
///
/// Ketika pengguna mengerjakan soal atau membuat bookmark secara offline,
/// data tersebut dimasukkan ke SyncQueue. SyncManager akan membaca
/// antrian ini dan mengirimkannya ke server saat perangkat kembali online.
@HiveType(typeId: 5)
class SyncQueueModel extends HiveObject {
  /// ID unik antrian (UUID yang dibuat secara lokal).
  @HiveField(0)
  final String id;

  /// Jenis data: progress | bookmark.
  @HiveField(1)
  final SyncType type;

  /// Data yang akan dikirim ke server dalam format Map (JSON).
  /// Isinya adalah toMap() dari UserProgressModel atau BookmarkModel.
  @HiveField(2)
  final Map<String, dynamic> payload;

  /// Waktu data masuk ke antrian.
  @HiveField(3)
  final DateTime createdAt;

  /// Jumlah percobaan sinkronisasi yang sudah dilakukan.
  /// Digunakan untuk mendeteksi item yang gagal berulang kali.
  @HiveField(4)
  final int retryCount;

  SyncQueueModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] ?? '',
      type: map['type'] == 'bookmark' ? SyncType.bookmark : SyncType.progress,
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      retryCount: map['retry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  SyncQueueModel copyWith({
    String? id,
    SyncType? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
