// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueModelAdapter extends TypeAdapter<SyncQueueModel> {
  @override
  final int typeId = 8;

  @override
  SyncQueueModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueModel(
      id: fields[0] as String,
      type: fields[1] as SyncType,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncTypeAdapter extends TypeAdapter<SyncType> {
  @override
  final int typeId = 7;

  @override
  SyncType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncType.progress;
      case 1:
        return SyncType.bookmark;
      default:
        return SyncType.progress;
    }
  }

  @override
  void write(BinaryWriter writer, SyncType obj) {
    switch (obj) {
      case SyncType.progress:
        writer.writeByte(0);
        break;
      case SyncType.bookmark:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
