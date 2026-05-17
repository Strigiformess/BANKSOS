import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk memantau status koneksi internet.
///
/// Digunakan oleh SyncManager untuk mendeteksi kapan perangkat
/// kembali online dan memulai proses sinkronisasi data offline.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Inisialisasi singkat — gunakan di `main()` untuk mengecek status awal.
  Future<void> init() async {
    final r = await _connectivity.checkConnectivity();
    // logging ringan untuk debugging
    // ignore: avoid_print
    print('ConnectivityService.init() -> status: $r');
  }

  /// Mengecek apakah perangkat saat ini terhubung ke internet.
  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    final mapped = _toConnectivityResult(result);
    return mapped != ConnectivityResult.none;
  }

  ConnectivityResult _toConnectivityResult(dynamic event) {
    if (event is ConnectivityResult) return event;
    if (event is List && event.isNotEmpty) {
      final first = event.first;
      if (first is ConnectivityResult) return first;
      if (first is String) {
        switch (first) {
          case 'none':
            return ConnectivityResult.none;
          case 'wifi':
            return ConnectivityResult.wifi;
          case 'mobile':
            return ConnectivityResult.mobile;
          default:
            return ConnectivityResult.none;
        }
      }
      if (first is int) {
        try {
          return ConnectivityResult.values[first];
        } catch (_) {
          return ConnectivityResult.none;
        }
      }
    }
    if (event is String) {
      switch (event) {
        case 'none':
          return ConnectivityResult.none;
        case 'wifi':
          return ConnectivityResult.wifi;
        case 'mobile':
          return ConnectivityResult.mobile;
        default:
          return ConnectivityResult.none;
      }
    }
    return ConnectivityResult.none;
  }

  /// Kembalian properti lama untuk kompatibilitas kode lain.
  Future<bool> get isOnline async => checkNow();

    /// Stream perubahan status koneksi.
      Stream<ConnectivityResult> get onConnectivityChanged =>
        (_connectivity.onConnectivityChanged as Stream<dynamic>).map((event) {
      // event can be ConnectivityResult, or in tests a List like ['none']
      if (event is ConnectivityResult) return event;
      if (event is List && event.isNotEmpty) {
        final first = event.first;
        if (first is ConnectivityResult) return first;
        if (first is String) {
          switch (first) {
            case 'none':
              return ConnectivityResult.none;
            case 'wifi':
              return ConnectivityResult.wifi;
            case 'mobile':
              return ConnectivityResult.mobile;
            default:
              return ConnectivityResult.none;
          }
        }
        if (first is int) {
          try {
            return ConnectivityResult.values[first];
          } catch (_) {
            return ConnectivityResult.none;
          }
        }
      }
      if (event is String) {
        switch (event) {
          case 'none':
            return ConnectivityResult.none;
          case 'wifi':
            return ConnectivityResult.wifi;
          case 'mobile':
            return ConnectivityResult.mobile;
          default:
            return ConnectivityResult.none;
        }
      }
      return ConnectivityResult.none;
    });
}
