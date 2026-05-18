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
