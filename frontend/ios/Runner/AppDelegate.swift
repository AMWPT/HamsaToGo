import Flutter
import UIKit
import firebase_messaging
import FirebaseAuth

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

  // ── Firebase Auth phone-verification pushes ──────────────────────────────
  // FCM order notifications flow through firebase_messaging, but Firebase
  // Auth's phone-verification uses its OWN silent APNs push. Under the UIScene
  // life cycle the automatic app-delegate forwarding is missed, so Auth never
  // receives its token/push and verifyPhoneNumber fails with "internal-error"
  // (after the first reCAPTCHA). Forward both to Auth explicitly.

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // .unknown lets the SDK detect sandbox vs production automatically.
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Auth consumes its own verification pushes; everything else falls through
    // to the default handler (FCM, etc.).
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler)
  }

  // Plugin registration moves here from didFinishLaunchingWithOptions: the
  // implicit Flutter engine now exists only once the scene has connected.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
