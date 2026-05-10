import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk memantau status koneksi internet.
///
/// Digunakan oleh SyncManager untuk mendeteksi kapan perangkat
/// kembali online dan memulai proses sinkronisasi data offline.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Mengecek apakah perangkat saat ini terhubung ke internet.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream perubahan status koneksi.
  /// Gunakan ini di SyncManager untuk listen perubahan online/offline.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
