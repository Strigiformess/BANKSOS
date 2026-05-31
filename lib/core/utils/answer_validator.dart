class AnswerResult {
  final bool isCorrect;
  final String feedback;

  AnswerResult({required this.isCorrect, required this.feedback});
}

class AnswerValidator {
  /// Membandingkan input pengguna dengan kunci jawaban secara presisi
  /// dan kebal terhadap kesalahan ketik minor (seperti huruf kapital/spasi berlebih).
  static AnswerResult checkAnswer({
    required String userInput,
    required String correctAnswer,
  }) {
    // 1. Jika input kosong, langsung kembalikan salah
    if (userInput.trim().isEmpty) {
      return AnswerResult(
        isCorrect: false,
        feedback: "Jawaban tidak boleh kosong. Silakan isi jawaban Anda.",
      );
    }

    // 2. Normalisasi Teks (Standardisasi Akademik untuk Auto-Grader)
    // - toLowerCase(): Membuat perbandingan menjadi case-insensitive
    // - trim(): Memotong spasi yang tidak sengaja terketik di awal/akhir
    // - replaceAll(RegExp(r'\s+'), ' '): Mengubah spasi ganda di tengah kalimat menjadi spasi tunggal
    String normalizedInput = userInput
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
        
    String normalizedCorrectAnswer = correctAnswer
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    // 3. Evaluasi Logika
    if (normalizedInput == normalizedCorrectAnswer) {
      return AnswerResult(
        isCorrect: true,
        feedback: "Benar! Jawaban Anda tepat.",
      );
    } else {
      return AnswerResult(
        isCorrect: false,
        feedback: "Jawaban salah. Coba periksa kembali ejaan atau konsepnya.",
      );
    }
  }
}