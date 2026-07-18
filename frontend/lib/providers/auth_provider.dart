import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../core/constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Auth State ───────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null || isAdmin;

  AuthState copyWith({
    UserModel? user,
    bool? isAdmin,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isAdmin: isAdmin ?? this.isAdmin,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AuthState(isLoading: true)) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    try {
      // Wait for Firebase to restore any persisted session before making
      // authenticated calls — currentUser is null briefly on cold start, and
      // the backend now requires a valid ID token on protected endpoints.
      final fbUser = FirebaseAuth.instance.currentUser ??
          await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 5), onTimeout: () => null);

      final isAdmin = await _storage.read(key: StorageKeys.isAdmin);
      if (isAdmin == 'true') {
        // Staff access is enforced by Firestore rules (the /staff/{uid} doc);
        // just confirm a live Firebase session still backs it.
        if (fbUser != null) {
          state = const AuthState(isAdmin: true);
          // Re-register the device for new-order alerts (tokens rotate).
          FcmService.registerStaffToken(_api);
          return;
        }
        await _storage.deleteAll();
        state = const AuthState();
        return;
      }

      final userId = await _storage.read(key: StorageKeys.userId);
      if (userId != null && fbUser != null) {
        final user = await _api.getUser(userId);
        state = AuthState(user: user);
        return;
      }
      // Stored session but no live Firebase user → clean it up.
      if (userId != null) await _storage.deleteAll();
    } catch (_) {}
    state = const AuthState();
  }

  /// Called after Firebase phone OTP is verified on device.
  /// [idToken] = Firebase ID token.
  /// [fullName] = provided only on the register screen (new users).
  Future<void> completePhoneAuth({
    required String idToken,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Send the device's chosen language so order notifications are localized.
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(StorageKeys.locale) ?? 'en';
      final data = await _api.phoneVerify(
        idToken: idToken,
        fullName: fullName,
        lang: lang,
      );
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String?;

      await _storage.write(key: StorageKeys.userId, value: user.id);
      if (token != null) {
        await _storage.write(key: StorageKeys.authToken, value: token);
      }

      state = AuthState(user: user);
      // Register FCM token so push notifications reach this device
      FcmService.registerToken(_api, user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// Staff login via Firebase phone OTP.
  /// [idToken] = Firebase ID token from a verified phone sign-in.
  Future<bool> loginAdminPhone(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final valid = await _api.verifyAdminPhone(idToken);
      if (valid) {
        await _storage.write(key: StorageKeys.isAdmin, value: 'true');
        state = const AuthState(isAdmin: true);
        // Register this device for new-order push alerts.
        FcmService.registerStaffToken(_api);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Not authorized');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  /// Persist the customer's language choice so order notifications match it.
  /// Best-effort — a failure here shouldn't disrupt the UI language switch.
  Future<void> updateLanguage(String lang) async {
    final user = state.user;
    if (user == null) return;
    try {
      await _api.updateLanguage(user.id, lang);
      state = state.copyWith(user: UserModel(
        id: user.id,
        phone: user.phone,
        fullName: user.fullName,
        fcmToken: user.fcmToken,
        lang: lang,
        createdAt: user.createdAt,
      ));
    } catch (_) {}
  }

  Future<void> logout() async {
    // Clear the Firebase session too — otherwise it leaks into the next login
    // (e.g. switching between a customer and staff on the same device), and
    // Firestore security rules would run against the wrong user's token.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }

  /// Permanently delete the signed-in customer's account, then sign out.
  /// [idToken] = a freshly-minted Firebase ID token proving ownership.
  /// Returns true on success; on failure leaves the session intact and
  /// surfaces the error via state.error.
  Future<bool> deleteAccount(String idToken) async {
    final user = state.user;
    if (user == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteAccount(user.id, idToken);
      await _storage.deleteAll();
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final detail = e.response?.data?['detail'];
      if (detail != null) return detail.toString();
    }
    final msg = e.toString();
    if (msg.contains('NO_ACCOUNT')) return 'NO_ACCOUNT';
    return msg.replaceAll('Exception: ', '');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(apiServiceProvider)),
);
