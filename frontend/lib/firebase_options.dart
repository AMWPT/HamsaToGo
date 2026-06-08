import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBg1oohnZswS7o3k_B-681uhTC83V-0fSU',
    appId: '1:269284588239:android:8fa62ab7b09dc9b1ec15ba',
    messagingSenderId: '269284588239',
    projectId: 'hamsacafe-1',
    storageBucket: 'hamsacafe-1.firebasestorage.app',
  );
}
