import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(StorageKeys.locale);
    if (saved != null) {
      state = Locale(saved);
      _syncFirebaseLanguage(saved);
    }
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    _syncFirebaseLanguage(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.locale, languageCode);
  }

  /// Keep Firebase Auth's language in step with the app language so the
  /// OTP SMS (and any reCAPTCHA UI) arrives in Arabic for Arabic users.
  void _syncFirebaseLanguage(String languageCode) {
    try {
      FirebaseAuth.instance.setLanguageCode(languageCode);
    } catch (_) {
      // Firebase not initialized yet (e.g. during early startup) — the
      // default (device locale) applies until the next locale change.
    }
  }

  bool get isArabic => state.languageCode == 'ar';
  String get code => state.languageCode;
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
