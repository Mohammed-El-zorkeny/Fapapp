import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Global Navigator Key to access navigation without Context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // Local Notifications for foreground "Heads-up"
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Define High Importance Channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    // 1. Request Permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Skip local notifications setup on web
    if (!kIsWeb) {
      // 2. Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification click when app is in foreground
          _navigateToNotifications();
        },
      );

      // 3. Create the Channel on Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // 4. Set Foreground presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] ── Foreground message received ──');
      debugPrint('[FCM] data        : ${message.data}');
      debugPrint('[FCM] notification: ${message.notification?.title} / ${message.notification?.body}');
      debugPrint('[FCM] screenName  : ${message.data['screenName']}');

      if (_isForceLogout(message)) {
        debugPrint('[FCM] FORCE_LOGOUT detected → logging out');
        _handleForceLogout();
        return;
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
        );
      }
    });

    // 6. Handle background/terminated state click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (_isForceLogout(message)) {
        _handleForceLogout();
        return;
      }
      _navigateToNotifications();
    });

    // 7. Handle app opened from terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (_isForceLogout(initialMessage)) {
        Future.delayed(const Duration(seconds: 1), _handleForceLogout);
      } else {
        Future.delayed(const Duration(seconds: 1), _navigateToNotifications);
      }
    }
  }

  bool _isForceLogout(RemoteMessage message) {
    return (message.data['screenName'] ?? '') == 'FORCE_LOGOUT';
  }

  Future<void> _handleForceLogout() async {
    await StorageService().clearAll();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToNotifications() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  Future<void> registerNotification(int userId) async {
    if (kIsWeb) return;
    try {
      final token = await _fcm.getToken();
      debugPrint('[FCM] userId=$userId');
      debugPrint('[FCM] token=${token ?? "NULL — token not obtained"}');

      if (token == null) {
        debugPrint('[FCM] ERROR: Could not get FCM token. Check google-services.json and internet connection.');
        return;
      }

      final deviceType = defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';
      debugPrint('[FCM] Registering token to API — deviceType=$deviceType');

      final result = await _apiService.updateDeviceToken(
        deviceToken: token,
        deviceType: deviceType,
        appVersion: '1.0.2',
      );

      debugPrint('[FCM] updateDeviceToken result: $result');
      if (result['success'] == true) {
        debugPrint('[FCM] Token saved to DB successfully.');
      } else {
        debugPrint('[FCM] ERROR saving token to DB: ${result['message']}');
      }
    } catch (e, stack) {
      debugPrint('[FCM] Exception in registerNotification: $e');
      debugPrint('$stack');
    }
  }
}
