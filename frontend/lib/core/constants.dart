// ─── API ─────────────────────────────────────────────────────
abstract class ApiConstants {
  /// Replace with your local IP when testing on a physical device,
  /// or your deployed backend URL in production.
  static const baseUrl = 'http://10.0.2.2:8080'; // Android emulator → localhost

  static const timeout = Duration(seconds: 15);
}

// ─── Storage Keys ────────────────────────────────────────────
abstract class StorageKeys {
  static const authToken = 'auth_token';
  static const userId = 'user_id';
  static const userEmail = 'user_email';
  static const userName = 'user_name';
  static const isAdmin = 'is_admin';
  static const locale = 'locale';
  static const fcmToken = 'fcm_token';
}

// ─── Admin Credentials ───────────────────────────────────────
abstract class AdminConstants {
  /// The fixed admin email — one shared device
  static const adminEmail = 'admin@hamsa.coffee';
  static const adminPin = '1234'; // Change this!
}

// ─── App Info ────────────────────────────────────────────────
abstract class AppConstants {
  static const appName = 'Hamsa To Go';
  static const taglineEn = 'Crafted with care';
  static const taglineAr = 'مصنوع باتقان';
}
