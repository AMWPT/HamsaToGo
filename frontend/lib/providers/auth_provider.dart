import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';
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
      final isAdmin = await _storage.read(key: StorageKeys.isAdmin);
      if (isAdmin == 'true') {
        state = const AuthState(isAdmin: true);
        return;
      }

      final userId = await _storage.read(key: StorageKeys.userId);
      if (userId != null) {
        final user = await _api.getUser(userId);
        state = AuthState(user: user);
        return;
      }
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
      final data = await _api.phoneVerify(
        idToken: idToken,
        fullName: fullName,
      );
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String?;

      await _storage.write(key: StorageKeys.userId, value: user.id);
      if (token != null) {
        await _storage.write(key: StorageKeys.authToken, value: token);
      }

      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<bool> loginAdmin(String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final valid = await _api.verifyAdmin(password);
      if (valid) {
        await _storage.write(key: StorageKeys.isAdmin, value: 'true');
        state = const AuthState(isAdmin: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid password');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
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

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
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
