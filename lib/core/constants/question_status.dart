/// Konstanta string status soal sesuai yang disimpan di MongoDB.
class QuestionStatusConstants {
  QuestionStatusConstants._();

  static const String pending = 'pending';
  static const String published = 'published';
  static const String rejected = 'rejected';
  static const String archived = 'archived';
  static const String inactive = 'inactive';
  static const String revisionRequired = 'revision_required';
}
