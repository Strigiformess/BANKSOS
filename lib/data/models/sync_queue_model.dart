import 'package:hive/hive.dart';

part 'sync_queue_model.g.dart';

@HiveType(typeId: 6)
enum SyncType {
  @HiveField(0)
  progress,

  @HiveField(1)
  bookmark
}

enum SyncAction { bookmarkAdd, bookmarkRemove, progressSync }

@HiveType(typeId: 9)
class SyncQueueModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncType type;

  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(5)
  final String action;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final int retryCount;

  SyncQueueModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.action,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] ?? '',
      type: map['type'] == 'bookmark' ? SyncType.bookmark : SyncType.progress,
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      action: map['action']?.toString() ?? SyncAction.bookmarkAdd.name,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      retryCount: map['retry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'action': action,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  SyncQueueModel copyWith({
    String? id,
    SyncType? type,
    Map<String, dynamic>? payload,
    String? action,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}