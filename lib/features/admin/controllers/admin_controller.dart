// // lib/features/admin/controllers/admin_controller.dart
// // Sprint 5 — Revaldi (RP): Guard RBAC Panel Admin — Controller Level
// //
// // RBAC ditegakkan di CONTROLLER LEVEL, bukan hanya di UI.
// // Konsisten dengan guard reviewer yang dibuat di Sprint 4.
// //
// // Tanggung jawab:
// //   - loadUsers        : ambil semua user dari MongoDB
// //   - updateUserStatus : aktifkan / nonaktifkan / ubah role user
// //   - loadSoal         : ambil semua soal (semua status termasuk arsip)
// //   - updateStatusSoal : arsipkan / nonaktifkan / aktifkan kembali soal
// //
// // Validasi bisnis (di controller, bukan hanya UI):
// //   - Semua fungsi hanya bisa dipanggil oleh role 'admin'
// //   - updateUserStatus → status baru harus valid
// //   - updateStatusSoal → status baru harus valid
// //   - Admin tidak bisa mengubah role dirinya sendiri

// import 'package:flutter/foundation.dart';
// import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where, modify;

// import '../../../core/services/connectivity_service.dart';
// import '../../../core/services/session_service.dart';
// import '../../../data/models/question_model.dart';
// import '../../../data/models/user_model.dart';
// import '../../../data/remote/mongodb/mongodb_service.dart';

// // ─── Enum state ───────────────────────────────────────────────────────────────

// enum AdminLoadState { idle, loading, loaded, error }

// enum AdminActionState { idle, processing, success, error }

// // ─── Result wrapper ───────────────────────────────────────────────────────────

// class AdminActionResult {
//   const AdminActionResult({
//     required this.success,
//     this.errorMessage,
//   });

//   final bool success;
//   final String? errorMessage;
// }

// // ─── Controller ───────────────────────────────────────────────────────────────

// class AdminController extends ChangeNotifier {
//   final MongoDBService _db;
//   final SessionService _session;
//   final ConnectivityService _connectivity;

//   AdminController({
//     MongoDBService? db,
//     SessionService? session,
//     ConnectivityService? connectivity,
//   })  : _db = db ?? MongoDBService.instance,
//         _session = session ?? SessionService.instance,
//         _connectivity = connectivity ?? ConnectivityService.instance;

//   // ─── State ─────────────────────────────────────────────────────────────────

//   AdminLoadState _loadState = AdminLoadState.idle;
//   AdminActionState _actionState = AdminActionState.idle;

//   List<UserModel> _users = [];
//   List<QuestionModel> _soal = [];

//   String? _errorMessage;
//   String? _actionError;

//   // Filter state
//   String? _filterRole;      // null = semua
//   String? _filterStatus;    // null = semua
//   String? _filterSoalStatus;
//   String? _filterKategori;

//   // ─── Getter publik ─────────────────────────────────────────────────────────

//   AdminLoadState get loadState => _loadState;
//   AdminActionState get actionState => _actionState;
//   List<UserModel> get users => List.unmodifiable(_users);
//   List<QuestionModel> get soal => List.unmodifiable(_soal);
//   String? get errorMessage => _errorMessage;
//   String? get actionError => _actionError;
//   bool get isLoading => _loadState == AdminLoadState.loading;
//   bool get isProcessing => _actionState == AdminActionState.processing;

//   // Stats
//   int get totalUserAktif =>
//       _users.where((u) => u.status == UserStatus.active).length;
//   int get totalUserInaktif =>
//       _users.where((u) => u.status == UserStatus.inactive).length;
//   int get totalSoalAktif =>
//       _soal.where((q) => q.status == QuestionStatus.published).length;
//   int get totalSoalArsip =>
//       _soal.where((q) => q.status == QuestionStatus.archived).length;

//   // ─── Kelola Pengguna ──────────────────────────────────────────────────────

//   /// Ambil semua user dari MongoDB.
//   /// Guard: hanya admin yang bisa akses.
//   Future<void> loadUsers() async {
//     // ── GUARD RBAC di controller level ──
//     final guard = _guardAdmin();
//     if (guard != null) {
//       _loadState = AdminLoadState.error;
//       _errorMessage = guard;
//       notifyListeners();
//       return;
//     }

//     _loadState = AdminLoadState.loading;
//     _errorMessage = null;
//     notifyListeners();

//     final isOnline = await _connectivity.checkNow();
//     if (!isOnline || !_db.isConnected) {
//       _loadState = AdminLoadState.error;
//       _errorMessage = 'Panel admin membutuhkan koneksi internet.';
//       notifyListeners();
//       return;
//     }

//     try {
//       final rawList = await _db.users
//           .find()
//           .toList();

//       _users = rawList
//           .map((m) => UserModel.fromMap(m))
//           .toList()
//         ..sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));

//       _loadState = AdminLoadState.loaded;
//     } catch (e) {
//       _loadState = AdminLoadState.error;
//       _errorMessage =
//           'Gagal memuat data pengguna: ${e.toString().replaceFirst('Exception: ', '')}';
//     }

//     notifyListeners();
//   }

//   /// Ubah status akun user (aktif/nonaktif) atau ubah role-nya.
//   ///
//   /// Validasi bisnis:
//   ///   - Admin tidak bisa mengubah akun dirinya sendiri
//   ///   - newStatus harus 'active' atau 'inactive'
//   ///   - newRole harus 'mahasiswa', 'reviewer', atau 'admin'
//   Future<AdminActionResult> updateUserStatus({
//     required String userId,
//     String? newStatus,  // 'active' | 'inactive' | null (tidak diubah)
//     String? newRole,    // 'mahasiswa' | 'reviewer' | 'admin' | null (tidak diubah)
//   }) async {
//     // ── GUARD RBAC di controller level ──
//     final guard = _guardAdmin();
//     if (guard != null) {
//       return AdminActionResult(success: false, errorMessage: guard);
//     }

//     // Validasi: admin tidak boleh mengubah dirinya sendiri
//     if (userId == _session.userId) {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Admin tidak dapat mengubah status akun dirinya sendiri.',
//       );
//     }

//     // Validasi status
//     if (newStatus != null &&
//         newStatus != 'active' &&
//         newStatus != 'inactive') {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Status tidak valid. Pilih "active" atau "inactive".',
//       );
//     }

//     // Validasi role
//     const validRoles = ['mahasiswa', 'reviewer', 'admin'];
//     if (newRole != null && !validRoles.contains(newRole)) {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Role tidak valid.',
//       );
//     }

//     if (newStatus == null && newRole == null) {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Tidak ada perubahan yang dilakukan.',
//       );
//     }

//     return await _jalankanAksi(() async {
//       final updateFields = <String, dynamic>{
//         'updated_at': DateTime.now().toIso8601String(),
//       };
//       if (newStatus != null) updateFields['status'] = newStatus;
//       if (newRole != null) updateFields['role'] = newRole;

//       await _db.users.updateOne(
//         where.id(ObjectId.parse(userId)),
//         modify.set('status', newStatus ?? '').set('role', newRole ?? ''),
//       );

//       // Update lokal agar UI reaktif
//       final idx = _users.indexWhere((u) => u.id == userId);
//       if (idx != -1) {
//         final old = _users[idx];
//         _users[idx] = old.copyWith(
//           status: newStatus == 'inactive'
//               ? UserStatus.inactive
//               : newStatus == 'active'
//                   ? UserStatus.active
//                   : old.status,
//           role: newRole != null ? _roleFromString(newRole) : old.role,
//         );
//       }
//     });
//   }

//   // ─── Kelola Soal ─────────────────────────────────────────────────────────

//   /// Ambil semua soal dari MongoDB termasuk yang diarsipkan.
//   /// Guard: hanya admin yang bisa akses.
//   Future<void> loadSoal() async {
//     // ── GUARD RBAC di controller level ──
//     final guard = _guardAdmin();
//     if (guard != null) {
//       _loadState = AdminLoadState.error;
//       _errorMessage = guard;
//       notifyListeners();
//       return;
//     }

//     _loadState = AdminLoadState.loading;
//     _errorMessage = null;
//     notifyListeners();

//     final isOnline = await _connectivity.checkNow();
//     if (!isOnline || !_db.isConnected) {
//       _loadState = AdminLoadState.error;
//       _errorMessage = 'Panel admin membutuhkan koneksi internet.';
//       notifyListeners();
//       return;
//     }

//     try {
//       // Admin bisa lihat SEMUA soal termasuk arsip dan nonaktif
//       final rawList = await _db.questions
//           .find()
//           .toList();

//       _soal = rawList
//           .map((m) => QuestionModel.fromMap(m))
//           .toList()
//         ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

//       _loadState = AdminLoadState.loaded;
//     } catch (e) {
//       _loadState = AdminLoadState.error;
//       _errorMessage =
//           'Gagal memuat data soal: ${e.toString().replaceFirst('Exception: ', '')}';
//     }

//     notifyListeners();
//   }

//   /// Ubah status soal: arsipkan / nonaktifkan / aktifkan kembali.
//   ///
//   /// [questionId]  — ID soal yang akan diubah.
//   /// [newStatus]   — 'published' | 'archived' | 'inactive'
//   ///
//   /// Validasi:
//   ///   - status baru harus valid
//   ///   - Hanya admin yang bisa
//   Future<AdminActionResult> updateStatusSoal({
//     required String questionId,
//     required String newStatus,
//   }) async {
//     // ── GUARD RBAC di controller level ──
//     final guard = _guardAdmin();
//     if (guard != null) {
//       return AdminActionResult(success: false, errorMessage: guard);
//     }

//     const validStatus = ['published', 'archived', 'inactive'];
//     if (!validStatus.contains(newStatus)) {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Status soal tidak valid.',
//       );
//     }

//     return await _jalankanAksi(() async {
//       await _db.questions.updateOne(
//         where.id(ObjectId.parse(questionId)),
//         modify
//             .set('status', newStatus)
//             .set('updated_at', DateTime.now().toIso8601String()),
//       );

//       // Update lokal agar UI reaktif
//       final idx = _soal.indexWhere((q) => q.id == questionId);
//       if (idx != -1) {
//         _soal[idx] = _soal[idx].copyWith(
//           status: _statusFromString(newStatus),
//           updatedAt: DateTime.now(),
//         );
//       }
//     });
//   }

//   // ─── Reset state aksi ─────────────────────────────────────────────────────

//   void resetActionState() {
//     _actionState = AdminActionState.idle;
//     _actionError = null;
//     notifyListeners();
//   }

//   // ─── Helper: guard admin ──────────────────────────────────────────────────

//   /// Cek apakah user yang sedang login adalah admin.
//   /// Kembalikan null jika boleh akses, kembalikan pesan error jika ditolak.
//   ///
//   /// RBAC DITEGAKKAN DI SINI — bukan hanya di UI.
//   String? _guardAdmin() {
//     if (!_session.isLoggedIn) {
//       return 'Sesi tidak ditemukan. Silakan login ulang.';
//     }
//     if (_session.role != 'admin') {
//       return 'Akses ditolak. Halaman ini hanya untuk administrator.';
//     }
//     return null;
//   }

//   /// Verifikasi boolean tanpa pesan error — untuk pengecekan cepat.
//   bool get _isAdmin =>
//       _session.isLoggedIn && _session.role == 'admin';

//   // ─── Helper: jalankan aksi dengan state management ────────────────────────

//   Future<AdminActionResult> _jalankanAksi(
//     Future<void> Function() aksi,
//   ) async {
//     final isOnline = await _connectivity.checkNow();
//     if (!isOnline || !_db.isConnected) {
//       return const AdminActionResult(
//         success: false,
//         errorMessage: 'Aksi admin membutuhkan koneksi internet.',
//       );
//     }

//     _actionState = AdminActionState.processing;
//     _actionError = null;
//     notifyListeners();

//     try {
//       await aksi();
//       _actionState = AdminActionState.success;
//       notifyListeners();
//       return const AdminActionResult(success: true);
//     } catch (e) {
//       _actionError = e.toString().replaceFirst('Exception: ', '');
//       _actionState = AdminActionState.error;
//       notifyListeners();
//       return AdminActionResult(
//         success: false,
//         errorMessage: _actionError,
//       );
//     }
//   }

//   // ─── Konverter helper ────────────────────────────────────────────────────

//   UserRole _roleFromString(String value) {
//     switch (value) {
//       case 'reviewer':
//         return UserRole.reviewer;
//       case 'admin':
//         return UserRole.admin;
//       default:
//         return UserRole.mahasiswa;
//     }
//   }

//   QuestionStatus _statusFromString(String value) {
//     switch (value) {
//       case 'published':
//         return QuestionStatus.published;
//       case 'archived':
//         return QuestionStatus.archived;
//       case 'inactive':
//         return QuestionStatus.inactive;
//       default:
//         return QuestionStatus.pending;
//     }
//   }
// }

// lib/features/admin/controllers/admin_controller.dart
// Sprint 5 — Revaldi (RP): Guard RBAC Panel Admin — Controller Level

import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where, modify;

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/remote/mongodb/mongodb_service.dart';

// ─── Enum state ───────────────────────────────────────────────────────────────

enum AdminLoadState { idle, loading, loaded, error }
enum AdminActionState { idle, processing, success, error }

// ─── Result wrapper ───────────────────────────────────────────────────────────

class AdminActionResult {
  const AdminActionResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

// ─── Controller ───────────────────────────────────────────────────────────────

class AdminController extends ChangeNotifier {
  final MongoDBService _db;
  final SessionService _session;
  final ConnectivityService _connectivity;

  AdminController({
    MongoDBService? db,
    SessionService? session,
    ConnectivityService? connectivity,
  })  : _db = db ?? MongoDBService.instance,
        _session = session ?? SessionService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance;

  // ─── State ─────────────────────────────────────────────────────────────────

  AdminLoadState _loadState = AdminLoadState.idle;
  AdminActionState _actionState = AdminActionState.idle;

  List<UserModel> _users = [];
  List<QuestionModel> _soal = [];

  String? _errorMessage;
  String? _actionError;

  // ─── Getter publik ─────────────────────────────────────────────────────────

  AdminLoadState get loadState => _loadState;
  AdminActionState get actionState => _actionState;
  List<UserModel> get users => List.unmodifiable(_users);
  List<QuestionModel> get soal => List.unmodifiable(_soal);
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  bool get isLoading => _loadState == AdminLoadState.loading;
  bool get isProcessing => _actionState == AdminActionState.processing;

  // Stats
  int get totalUserAktif => _users.where((u) => u.status == UserStatus.active).length;
  int get totalUserInaktif => _users.where((u) => u.status == UserStatus.inactive).length;
  int get totalSoalAktif => _soal.where((q) => q.status == QuestionStatus.published).length;
  int get totalSoalArsip => _soal.where((q) => q.status == QuestionStatus.archived).length;

  // ─── Kelola Pengguna ──────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    final guard = _guardAdmin();
    if (guard != null) {
      _loadState = AdminLoadState.error;
      _errorMessage = guard;
      notifyListeners();
      return;
    }

    _loadState = AdminLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      _loadState = AdminLoadState.error;
      _errorMessage = 'Panel admin membutuhkan koneksi internet.';
      notifyListeners();
      return;
    }

    try {
      final rawList = await _db.users.find().toList();

      _users = rawList.map((m) => UserModel.fromMap(m)).toList()
        ..sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));

      _loadState = AdminLoadState.loaded;
    } catch (e) {
      _loadState = AdminLoadState.error;
      _errorMessage = 'Gagal memuat data pengguna: ${e.toString().replaceFirst('Exception: ', '')}';
    }

    notifyListeners();
  }

  Future<AdminActionResult> updateUserStatus({
    required String userId,
    String? newStatus,
    String? newRole,
  }) async {
    final guard = _guardAdmin();
    if (guard != null) {
      return AdminActionResult(success: false, errorMessage: guard);
    }

    if (userId == _session.userId) {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Admin tidak dapat mengubah status akun dirinya sendiri.',
      );
    }

    if (newStatus != null && newStatus != 'active' && newStatus != 'inactive') {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Status tidak valid. Pilih "active" atau "inactive".',
      );
    }

    const validRoles = ['mahasiswa', 'reviewer', 'admin'];
    if (newRole != null && !validRoles.contains(newRole)) {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Role tidak valid.',
      );
    }

    if (newStatus == null && newRole == null) {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Tidak ada perubahan yang dilakukan.',
      );
    }

    return await _jalankanAksi(() async {
      final updateFields = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus != null) updateFields['status'] = newStatus;
      if (newRole != null) updateFields['role'] = newRole;

      await _db.users.updateOne(
        where.id(ObjectId.parse(userId)),
        modify.set('status', newStatus ?? '').set('role', newRole ?? ''),
      );

      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        final old = _users[idx];
        _users[idx] = old.copyWith(
          status: newStatus == 'inactive'
              ? UserStatus.inactive
              : newStatus == 'active'
                  ? UserStatus.active
                  : old.status,
          role: newRole != null ? _roleFromString(newRole) : old.role,
        );
      }
    });
  }

  // ─── Kelola Soal ─────────────────────────────────────────────────────────

  Future<void> loadSoal() async {
    final guard = _guardAdmin();
    if (guard != null) {
      _loadState = AdminLoadState.error;
      _errorMessage = guard;
      notifyListeners();
      return;
    }

    _loadState = AdminLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      _loadState = AdminLoadState.error;
      _errorMessage = 'Panel admin membutuhkan koneksi internet.';
      notifyListeners();
      return;
    }

    try {
      final rawList = await _db.questions.find().toList();

      _soal = rawList.map((m) => QuestionModel.fromMap(m)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _loadState = AdminLoadState.loaded;
    } catch (e) {
      _loadState = AdminLoadState.error;
      _errorMessage = 'Gagal memuat data soal: ${e.toString().replaceFirst('Exception: ', '')}';
    }

    notifyListeners();
  }

  Future<AdminActionResult> updateStatusSoal({
    required String questionId,
    required String newStatus,
  }) async {
    final guard = _guardAdmin();
    if (guard != null) {
      return AdminActionResult(success: false, errorMessage: guard);
    }

    const validStatus = ['published', 'archived', 'inactive'];
    if (!validStatus.contains(newStatus)) {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Status soal tidak valid.',
      );
    }

    return await _jalankanAksi(() async {
      await _db.questions.updateOne(
        where.id(ObjectId.parse(questionId)),
        modify
            .set('status', newStatus)
            .set('updated_at', DateTime.now().toIso8601String()),
      );

      final idx = _soal.indexWhere((q) => q.id == questionId);
      if (idx != -1) {
        _soal[idx] = _soal[idx].copyWith(
          status: _statusFromString(newStatus),
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  void resetActionState() {
    _actionState = AdminActionState.idle;
    _actionError = null;
    notifyListeners();
  }

  String? _guardAdmin() {
    if (!_session.isLoggedIn) {
      return 'Sesi tidak ditemukan. Silakan login ulang.';
    }
    if (_session.role != 'admin') {
      return 'Akses ditolak. Halaman ini hanya untuk administrator.';
    }
    return null;
  }

  Future<AdminActionResult> _jalankanAksi(
    Future<void> Function() aksi,
  ) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline || !_db.isConnected) {
      return const AdminActionResult(
        success: false,
        errorMessage: 'Aksi admin membutuhkan koneksi internet.',
      );
    }

    _actionState = AdminActionState.processing;
    _actionError = null;
    notifyListeners();

    try {
      await aksi();
      _actionState = AdminActionState.success;
      notifyListeners();
      return const AdminActionResult(success: true);
    } catch (e) {
      _actionError = e.toString().replaceFirst('Exception: ', '');
      _actionState = AdminActionState.error;
      notifyListeners();
      return AdminActionResult(
        success: false,
        errorMessage: _actionError,
      );
    }
  }

  UserRole _roleFromString(String value) {
    switch (value) {
      case 'reviewer': return UserRole.reviewer;
      case 'admin': return UserRole.admin;
      default: return UserRole.mahasiswa;
    }
  }

  QuestionStatus _statusFromString(String value) {
    switch (value) {
      case 'published': return QuestionStatus.published;
      case 'archived': return QuestionStatus.archived;
      case 'inactive': return QuestionStatus.inactive;
      default: return QuestionStatus.pending;
    }
  }
}