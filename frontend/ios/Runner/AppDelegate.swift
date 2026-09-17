import Flutter
import UIKit
import firebase_messaging

// Adopts the UIScene life cycle. Apple requires it for any UIKit app built
// with the iOS 27 SDK — without it the app fails to launch ("UIScene life
// cycle is required for apps built with this SDK"). The scene itself is
// declared in Info.plist (UIApplicationSceneManifest → FlutterSceneDelegate).
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Under UIScene, plugins register later (in didInitializeImplicitFlutterEngine
    // below), but Apple requires UNUserNotificationCenter's delegate to be set
    // before this method returns. Without this, foreground push notifications
    // (e.g. "your order is ready") are silently dropped.
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Plugin registration moves here from didFinishLaunchingWithOptions: the
  // implicit Flutter engine now exists only once the scene has connected.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
