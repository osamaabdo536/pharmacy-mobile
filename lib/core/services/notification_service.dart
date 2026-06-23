import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'dawak_high_importance';
  static const String _channelName = 'Dawak Notifications';
  static const String _channelDesc =
      'Reservation updates and medication reminders';

  static Future<void> init() async {
    debugPrint('🔔 NotificationService.init() started');

    // 1. Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    // 2. Create Android notification channel
    const AndroidNotificationChannel androidChannel =
    AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    final plugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin != null) {
      await plugin.createNotificationChannel(androidChannel);
      debugPrint('🔔 Android channel created');
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    plugin is AndroidFlutterLocalNotificationsPlugin ? plugin : null;

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      debugPrint('🔔 Android channel created');
    } else {
      debugPrint('🔔 androidPlugin is null');
    }

    // 3. Init flutter_local_notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final bool? initialized = await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    debugPrint('🔔 flutter_local_notifications initialized: $initialized');

    // 4. Force foreground notifications (iOS)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Foreground presentation options set');

    // 5. Foreground messages listener
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('🔔 onMessage fired: ${message.notification?.title}');
      debugPrint('🔔 onMessage data: ${message.data}');
      _showLocalNotification(message);
    });
    debugPrint('🔔 onMessage listener registered');

    // 6. Background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    debugPrint('🔔 onMessageOpenedApp listener registered');

    // 7. Terminated tap
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App opened from terminated via notification');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('🔔 NotificationService.init() completed');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    debugPrint('🔔 _showLocalNotification called');
    final String? title =
        message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];

    debugPrint('🔔 title: $title, body: $body');

    if (title == null && body == null) {
      debugPrint('🔔 Both title and body are null - skipping');
      return;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
    debugPrint('🔔 Local notification shown');
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped');
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/notifications');
    }
  }

  static Future<String?> getToken() => _fcm.getToken();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}