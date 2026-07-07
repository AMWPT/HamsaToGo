// ─── API ─────────────────────────────────────────────────────
abstract class ApiConstants {
  /// Emulator uses 10.0.2.2 (alias for the host's localhost).
  /// A physical device on the same Wi-Fi needs the PC's actual LAN IP
  /// instead — swap back to 10.0.2.2 when testing on the emulator again.
  static const baseUrl = 'http://192.168.0.118:8080';

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

// ─── App Info ────────────────────────────────────────────────
abstract class AppConstants {
  static const appName = 'Hamsa To Go';
  static const taglineEn = 'Crafted with care';
  static const taglineAr = 'مصنوع باتقان';
}

// ─── Moyasar Payments ────────────────────────────────────────
// TODO: replace with real keys once Moyasar activates the merchant account.
// Publishable key is safe to ship in the app (it can only create charges,
// never read/refund). The SECRET key must only ever live in the backend .env.
abstract class MoyasarConfig {
  static const publishableApiKey = 'pk_test_REPLACE_ME';

  // Apple Pay only works on iOS once the merchant ID is registered in the
  // Apple Developer account and linked in Moyasar's dashboard.
  static const applePayMerchantId = 'merchant.com.hamsa.hamsa_flutter';

  // Samsung Pay service ID comes from the Samsung Pay developer portal,
  // then gets paired with the Moyasar account.
  static const samsungPayServiceId = 'REPLACE_ME';

  static const merchantName = 'Hamsa Coffee Roasters';
}
