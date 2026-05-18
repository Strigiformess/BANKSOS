// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionModelAdapter extends TypeAdapter<QuestionModel> {
  @override
  final int typeId = 1;

  @override
  QuestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionModel(
      id: fields[0] as String,
      pertanyaan: fields[1] as String,
      jawaban: fields[2] as String,
      kategoriId: fields[3] as String,
      kategoriNama: fields[4] as String,
      tingkatKesulitan: fields[5] as DifficultyLevel,
      status: fields[6] as QuestionStatus,
      hints: (fields[7] as List).cast<String>(),
      submittedBy: fields[8] as String,
      reviewedBy: fields[9] as String?,
      rejectionReason: fields[10] as String?,
      solveCount: fields[11] as int,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      imageUrl: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionModel obj) {
    writer
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pertanyaan)
      ..writeByte(2)
      ..write(obj.jawaban)
      ..writeByte(3)
      ..write(obj.kategoriId)
      ..writeByte(4)
      ..write(obj.kategoriNama)
      ..writeByte(5)
      ..write(obj.tingkatKesulitan)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.hints)
      ..writeByte(8)
      ..write(obj.submittedBy)
      ..writeByte(9)
      ..write(obj.reviewedBy)
      ..writeByte(10)
      ..write(obj.rejectionReason)
      ..writeByte(11)
      ..write(obj.solveCount)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionStatusAdapter extends TypeAdapter<QuestionStatus> {
  @override
  final int typeId = 7;

  @override
  QuestionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionStatus.pending;
      case 1:
        return QuestionStatus.published;
      case 2:
        return QuestionStatus.rejected;
      case 3:
        return QuestionStatus.archived;
      case 4:
        return QuestionStatus.inactive;
      case 5:
        return QuestionStatus.revisionRequired;
      default:
        return QuestionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionStatus obj) {
    switch (obj) {
      case QuestionStatus.pending:
        writer.writeByte(0);
        break;
      case QuestionStatus.published:
        writer.writeByte(1);
        break;
      case QuestionStatus.rejected:
        writer.writeByte(2);
        break;
      case QuestionStatus.archived:
        writer.writeByte(3);
        break;
      case QuestionStatus.inactive:
        writer.writeByte(4);
        break;
      case QuestionStatus.revisionRequired:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 6;

  @override
  DifficultyLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DifficultyLevel.easy;
      case 1:
        return DifficultyLevel.medium;
      case 2:
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.easy;
    }
  }

  @override
  void write(BinaryWriter writer, DifficultyLevel obj) {
    switch (obj) {
      case DifficultyLevel.easy:
        writer.writeByte(0);
        break;
      case DifficultyLevel.medium:
        writer.writeByte(1);
        break;
      case DifficultyLevel.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
