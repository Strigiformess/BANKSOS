// lib/features/dashboard/controllers/dashboard_controller.dart
// PIC: Seruni Libertina Islami
// Sprint 6: Mengganti semua data hardcoded di dashboard menjadi data real

import 'package:flutter/foundation.dart';
import '../../../core/services/session_service.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';
import '../../../core/services/connectivity_service.dart';

// ─── Model Rank ───────────────────────────────────────────────────────────────

class RankInfo {
  final String rankName;
  final int currentPts;
  final int nextLevelPts;
  final double progressPercent;

  const RankInfo({
    required this.rankName,
    required this.currentPts,
    required this.nextLevelPts,
    required this.progressPercent,
  });
}

// ─── Model Top Student ────────────────────────────────────────────────────────

class TopStudentEntry {
  final String nama;
  final int pts;
  final int rank;

  const TopStudentEntry({
    required this.nama,
    required this.pts,
    required this.rank,
  });
}

// ─── Controller ───────────────────────────────────────────────────────────────

class DashboardController extends ChangeNotifier {
  final HiveService _hive = HiveService.instance;
  final SessionService _session = SessionService.instance;
  final MongoDBService _db = MongoDBService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  // ─── State ─────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  List<QuestionModel> _soalTerbaru = [];
  List<CategoryModel> _rekomendasi = [];
  List<TopStudentEntry> _topStudents = [];
  int _streakDays = 0;
  RankInfo _rankInfo = const RankInfo(
    rankName: 'Novice',
    currentPts: 0,
    nextLevelPts: 500,
    progressPercent: 0,
  );

  // ─── Getter ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  List<QuestionModel> get soalTerbaru => _soalTerbaru;
  List<CategoryModel> get rekomendasi => _rekomendasi;
  List<TopStudentEntry> get topStudents => _topStudents;
  int get streakDays => _streakDays;
  RankInfo get rankInfo => _rankInfo;

  // ─── Load semua data dashboard ────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    _computeRankInfo();
    _computeStreak();
    _loadSoalTerbaruFromHive();
    _loadRekomendasiFromHive();

    final isOnline = await _connectivity.checkNow();
    if (isOnline && _db.isConnected) {
      await _fetchTopStudentsFromServer();
      await _fetchSoalTerbaruFromServer();
      await _fetchRekomendasiFromServer();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Rank System ─────────────────────────────────────────────────────────

  // Rank levels: Novice 0-499, Explorer 500-1499, Scholar 1500-2999,
  //              Expert 3000-4999, Master 5000+
  void _computeRankInfo() {
    final userId = _session.userId ?? '';
    final solvedCount = _hive.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved)
        .length;

    // Setiap soal selesai = 10 pts (sama dengan StatisticsScreen)
    final pts = solvedCount * 10;

    String rankName;
    int nextPts;

    if (pts < 500) {
      rankName = 'Novice';
      nextPts = 500;
    } else if (pts < 1500) {
      rankName = 'Explorer';
      nextPts = 1500;
    } else if (pts < 3000) {
      rankName = 'Scholar';
      nextPts = 3000;
    } else if (pts < 5000) {
      rankName = 'Expert';
      nextPts = 5000;
    } else {
      rankName = 'Master';
      nextPts = pts + 1000;
    }

    // Hitung progress ke rank berikutnya
    final prevPts = _prevRankPts(rankName);
    final range = nextPts - prevPts;
    final progress = range > 0 ? ((pts - prevPts) / range).clamp(0.0, 1.0) : 1.0;

    _rankInfo = RankInfo(
      rankName: rankName,
      currentPts: pts,
      nextLevelPts: nextPts,
      progressPercent: progress,
    );
  }

  int _prevRankPts(String rank) {
    switch (rank) {
      case 'Explorer': return 500;
      case 'Scholar':  return 1500;
      case 'Expert':   return 3000;
      case 'Master':   return 5000;
      default:         return 0;
    }
  }

  // ─── Streak ───────────────────────────────────────────────────────────────

  void _computeStreak() {
    final userId = _session.userId ?? '';
    final solvedDates = _hive.userProgressBox.values
        .where((p) => p.userId == userId && p.isSolved && p.solvedAt != null)
        .map((p) => _dateOnly(p.solvedAt!))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // terbaru dulu

    if (solvedDates.isEmpty) {
      _streakDays = 0;
      return;
    }

    int streak = 0;
    DateTime cursor = _dateOnly(DateTime.now());

    for (final date in solvedDates) {
      if (date == cursor || date == cursor.subtract(const Duration(days: 1))) {
        streak++;
        cursor = date;
      } else {
        break;
      }
    }

    _streakDays = streak;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ─── Soal Terbaru dari Hive ───────────────────────────────────────────────

  void _loadSoalTerbaruFromHive() {
    final published = _hive.questionsBox.values
        .where((q) => q.status == QuestionStatus.published)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _soalTerbaru = published.take(5).toList();
  }

  // ─── Soal Terbaru dari Server ─────────────────────────────────────────────

  Future<void> _fetchSoalTerbaruFromServer() async {
    try {
      final raw = await _db.questions
          .find({'status': 'published'})
          .toList();

      final list = raw.map((m) => QuestionModel.fromMap(m)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _soalTerbaru = list.take(5).toList();

      // Simpan ke Hive
      for (final q in list) {
        _hive.questionsBox.put(q.id, q);
      }
    } catch (e) {
      debugPrint('DashboardController: fetchSoalTerbaru error: $e');
    }
  }

  // ─── Rekomendasi Matkul dari Hive ────────────────────────────────────────

  void _loadRekomendasiFromHive() {
    final all = _hive.categoriesBox.values
        .where((c) => c.isActive)
        .toList();
    _rekomendasi = all.take(4).toList();
  }

  // ─── Rekomendasi dari Server ──────────────────────────────────────────────

  Future<void> _fetchRekomendasiFromServer() async {
    try {
      final raw = await _db.categories
          .find({'is_active': true})
          .toList();

      final list = raw.map((m) => CategoryModel.fromMap(m)).toList();

      // Simpan ke Hive
      for (final c in list) {
        _hive.categoriesBox.put(c.id, c);
      }

      _rekomendasi = list.take(4).toList();
    } catch (e) {
      debugPrint('DashboardController: fetchRekomendasi error: $e');
    }
  }

  // ─── Top Students dari Server ─────────────────────────────────────────────

  Future<void> _fetchTopStudentsFromServer() async {
    try {
      // Agregasi: hitung jumlah soal solved per user, ambil top 3
      final progressRaw = await _db.userProgress.find().toList();

      // Group by user_id, hitung solved
      final Map<String, int> userSolvedCount = {};
      for (final p in progressRaw) {
        final uid = p['user_id']?.toString() ?? '';
        final isSolved = p['is_solved'] == true;
        if (uid.isNotEmpty && isSolved) {
          userSolvedCount[uid] = (userSolvedCount[uid] ?? 0) + 1;
        }
      }

      if (userSolvedCount.isEmpty) {
        _topStudents = [];
        return;
      }

      // Sort desc
      final sorted = userSolvedCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = sorted.take(3).toList();

      // Fetch nama user
      final List<TopStudentEntry> result = [];
      for (int i = 0; i < top3.length; i++) {
        final uid = top3[i].key;
        final solvedCount = top3[i].value;
        final pts = solvedCount * 10;

        String nama = 'Pengguna';
        try {
          final userDoc = await _db.users.findOne({'_id': uid});
          nama = userDoc?['nama_lengkap']?.toString() ?? 'Pengguna';
        } catch (_) {}

        result.add(TopStudentEntry(nama: nama, pts: pts, rank: i + 1));
      }

      _topStudents = result;
    } catch (e) {
      debugPrint('DashboardController: fetchTopStudents error: $e');
      _topStudents = [];
    }
  }

  // ─── Jumlah soal per kategori (untuk rekomendasi card) ───────────────────

  int countSoalByKategori(String kategoriId) {
    return _hive.questionsBox.values
        .where((q) => q.kategoriId == kategoriId && q.status == QuestionStatus.published)
        .length;
  }
}