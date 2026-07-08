// ─── API ─────────────────────────────────────────────────────
abstract class ApiConstants {
  /// Backend URL. Defaults to production (Cloud Run) so release builds
  /// need no extra flags. For local development, override at run time:
  ///
  ///   Emulator:        flutter run --dart-define=API_URL=http://10.0.2.2:8080
  ///   Physical device: flutter run --dart-define=API_URL=http://<PC-LAN-IP>:8080
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://hamsa-backend-269284588239.europe-west3.run.app',
  );

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
