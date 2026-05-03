class AppConstants {
  AppConstants._();

  static const String appName = 'BANKSOS';
  static const String appVersion = '1.0.0';

  /// Key untuk menyimpan data user di session_box.
  static const String sessionKey = 'current_user';

  /// Maksimum retry sinkronisasi sebelum item dianggap gagal.
  static const int maxSyncRetry = 3;
}
