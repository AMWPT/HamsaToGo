import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // iOS must get its own app ID. Handing it the Android config makes
        // the Firebase iOS SDK (12+) raise an NSException on a non-iOS
        // GOOGLE_APP_ID, killing the app on launch — GoogleService-Info.plist
        // isn't in the Xcode project's bundle resources, so these options are
        // what actually configure Firebase on iOS.
        return ios;
      default:
        return android;
    }
  }

  // Mirrors ios/Runner/GoogleService-Info.plist (verified against the live
  // Firebase iOS app, com.hamsa.hamsaFlutter).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOlwDKJeUfV1cnOyZYh2rnGTDSDk1DDzA',
    appId: '1:269284588239:ios:51aaf290028bb655ec15ba',
    messagingSenderId: '269284588239',
    projectId: 'hamsacafe-1',
    storageBucket: 'hamsacafe-1.firebasestorage.app',
    iosBundleId: 'com.hamsa.hamsaFlutter',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBg1oohnZswS7o3k_B-681uhTC83V-0fSU',
    appId: '1:269284588239:android:8fa62ab7b09dc9b1ec15ba',
    messagingSenderId: '269284588239',
    projectId: 'hamsacafe-1',
    storageBucket: 'hamsacafe-1.firebasestorage.app',
  );
}
