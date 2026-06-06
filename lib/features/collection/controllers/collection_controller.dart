// lib/features/collection/controllers/collection_controller.dart
// Sprint 4 — Collection Management Controller
//
// Tanggung jawab:
//   - loadCollections : ambil semua soal berdasarkan kategori (koleksi)
//   - filterByStatus : filter soal berdasarkan status (published, draft, archived)
//   - deleteCollection : hapus koleksi/soal
//
// Validasi bisnis (di controller, bukan hanya di UI):
//   - Hanya role 'reviewer' yang bisa akses halaman ini

import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' show where, modify;

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

// ─── Enum State ───────────────────────────────────────────────────────────────

enum CollectionLoadState { idle, loading, loaded, error }

enum CollectionActionState { idle, processing, success, error }

// ─── Result wrapper ───────────────────────────────────────────────────────────

class CollectionActionResult {
  const CollectionActionResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

// ─── Collection Item Model ────────────────────────────────────────────────────

class CollectionItem {
  final String id;
  final String title;
  final String description;
  final String status; // 'published' | 'draft' | 'archived'
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final int soalCount;
  final DateTime createdAt;
  final String categoryName;

  CollectionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.difficulty,
    required this.soalCount,
    required this.createdAt,
    required this.categoryName,
  });

  factory CollectionItem.fromQuestionModel(
      QuestionModel q, List<QuestionModel> relatedQuestions) {
    return CollectionItem(
      id: q.id,
      title: q.pertanyaan,
      description: q.pertanyaan.substring(0, min(100, q.pertanyaan.length)),
      status: q.status.name,
      difficulty: q.tingkatKesulitan.name,
      soalCount: relatedQuestions.length,
      createdAt: q.createdAt,
      categoryName: q.kategoriNama,
    );
  }
}

int min(int a, int b) => a < b ? a : b;

// ─── Controller ───────────────────────────────────────────────────────────────

class CollectionController extends ChangeNotifier {
  final MongoDBService _db;
  final SessionService _session;
  final ConnectivityService _connectivity;

  CollectionController({
    MongoDBService? db,
    SessionService? session,
    ConnectivityService? connectivity,
  })  : _db = db ?? MongoDBService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance;

  // ─── State ─────────────────────────────────────────────────────────────────

  CollectionLoadState _loadState = CollectionLoadState.idle;
  CollectionActionState _actionState = CollectionActionState.idle;
  List<CollectionItem> _collections = [];
  List<CategoryModel> _categories = [];
  String? _errorMessage;
  String? _actionError;

  // ─── Getter publik ─────────────────────────────────────────────────────────

  CollectionLoadState get loadState => _loadState;
  CollectionActionState get actionState => _actionState;
  List<CollectionItem> get collections => List.unmodifiable(_collections);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  bool get isLoading => _loadState == CollectionLoadState.loading;
  bool get isProcessing => _actionState == CollectionActionState.processing;

  // ─── Load Collections ─────────────────────────────────────────────────────

  /// Ambil semua koleksi (soal yang sudah dipublikasikan) dari MongoDB.
  /// Dikelompokkan berdasarkan kategori.
  Future<void> loadCollections() async {
    // Guard RBAC di controller level
    if (!_isReviewer()) {
      _loadState = CollectionLoadState.error;
      _errorMessage = 'Akses ditolak. Halaman ini hanya untuk reviewer.';
      notifyListeners();
      return;
    }

    _loadState = CollectionLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      _loadState = CollectionLoadState.error;
      _errorMessage = 'Koleksi membutuhkan koneksi internet.';
      notifyListeners();
      return;
    }

    try {
      // Load categories
      final categoriesRaw = await _db.categories.find().toList();
      _categories = categoriesRaw
          .map((m) => CategoryModel.fromMap(m))
          .where((c) => c.isActive)
          .toList();

      // Load all published questions
      final questionsRaw =
          await _db.questions.find(where.eq('status', 'published')).toList();

      final allQuestions =
          questionsRaw.map((m) => QuestionModel.fromMap(m)).toList();

      // Group by category and create collections
      final collectionsMap = <String, List<QuestionModel>>{};
      for (final q in allQuestions) {
        if (!collectionsMap.containsKey(q.kategoriNama)) {
          collectionsMap[q.kategoriNama] = [];
        }
        collectionsMap[q.kategoriNama]!.add(q);
      }

      // Convert to CollectionItem list
      _collections = [];
      for (final entry in collectionsMap.entries) {
        final soals = entry.value;
        if (soals.isNotEmpty) {
          final representative = soals.first;
          _collections.add(
            CollectionItem(
              id: representative.id,
              title: entry.key,
              description:
                  'Kumpulan soal ${entry.key} dengan ${soals.length} soal',
              status: 'published',
              difficulty: soals.first.tingkatKesulitan.name,
              soalCount: soals.length,
              createdAt: soals.first.createdAt,
              categoryName: entry.key,
            ),
          );
        }
      }

      _collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _loadState = CollectionLoadState.loaded;
    } catch (e) {
      _loadState = CollectionLoadState.error;
      _errorMessage =
          'Gagal memuat koleksi: ${e.toString().replaceFirst('Exception: ', '')}';
    }

    notifyListeners();
  }

  // ─── Delete Collection ────────────────────────────────────────────────────

  /// Hapus koleksi (archive semua soal dalam kategori tersebut).
  Future<CollectionActionResult> deleteCollection({
    required String categoryName,
  }) async {
    final guard = _guardReviewer();
    if (guard != null) {
      return CollectionActionResult(success: false, errorMessage: guard);
    }

    _actionState = CollectionActionState.processing;
    _actionError = null;
    notifyListeners();

    return await _jalankanAksi(() async {
      await _db.questions.updateMany(
        where.eq('kategori_nama', categoryName),
        modify
            .set('status', 'archived')
            .set('updated_at', DateTime.now().toIso8601String()),
      );
    });
  }

  // ─── Helper Methods ────────────────────────────────────────────────────────

  bool _isReviewer() => _session.role == 'reviewer';

  String? _guardReviewer() {
    if (!_isReviewer()) {
      return 'Akses ditolak. Halaman ini hanya untuk reviewer.';
    }
    return null;
  }

  Future<CollectionActionResult> _jalankanAksi(
    Future<void> Function() action,
  ) async {
    _actionState = CollectionActionState.processing;
    _actionError = null;
    notifyListeners();

    try {
      await action();
      _actionState = CollectionActionState.success;
      await loadCollections(); // Reload after action
      return const CollectionActionResult(success: true);
    } catch (e) {
      _actionState = CollectionActionState.error;
      _actionError = e.toString().replaceFirst('Exception: ', '');
      return CollectionActionResult(
        success: false,
        errorMessage: _actionError,
      );
    } finally {
      notifyListeners();
    }
  }
}
