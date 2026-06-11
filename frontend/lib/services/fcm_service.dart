import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

// Top-level handler required by Firebase for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  // Call once at app startup (after Firebase.initializeApp)
  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    // Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Register top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message — show a banner inside the app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF124734),
          action: _orderAction(message, navigatorKey),
        ),
      );
    });

    // Notification tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message, navigatorKey);
    });

    // Notification tapped that launched the app from terminated state
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromMessage(initial, navigatorKey);
    }
  }

  static SnackBarAction? _orderAction(
      RemoteMessage message, GlobalKey<NavigatorState> key) {
    final orderId = message.data['order_id'] as String?;
    if (orderId == null) return null;
    return SnackBarAction(
      label: 'View',
      textColor: const Color(0xFF52B788),
      onPressed: () => key.currentState?.pushNamed('/orders/$orderId'),
    );
  }

  static void _navigateFromMessage(
      RemoteMessage message, GlobalKey<NavigatorState> key) {
    final orderId = message.data['order_id'] as String?;
    if (orderId != null) {
      key.currentState?.pushNamed('/orders/$orderId');
    }
  }

  static Future<String?> getToken() => _messaging.getToken();

  // Call after the user logs in
  static Future<void> registerToken(ApiService api, String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;
      await api.saveFcmToken(userId: userId, token: token);
      debugPrint('[FCM] Token registered for $userId');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}
