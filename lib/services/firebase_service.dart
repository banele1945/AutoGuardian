import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Firebase Service for AutoGuardian
/// Handles Firebase initialization and messaging
class FirebaseService {
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static final _storage = FlutterSecureStorage();
  
  /// Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      await _setupMessaging();
      await _setupLocalNotifications();
      await _requestPermissions();
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  /// Setup Firebase messaging
  static Future<void> _setupMessaging() async {
    if (_messaging == null) return;

    // Get FCM token
    String? token = await _messaging!.getToken();
    if (token != null) {
      await _storage.write(key: 'fcm_token', value: token);
      print('FCM Token: $token');
    }

    // Handle token refresh
    _messaging!.onTokenRefresh.listen((newToken) async {
      await _storage.write(key: 'fcm_token', value: newToken);
      print('FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.data}');
      _handleForegroundMessage(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      _handleNotificationTap(message);
    });
  }

  /// Setup local notifications
  static Future<void> _setupLocalNotifications() async {
    if (_localNotifications == null) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications!.initialize(initializationSettings);
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    if (_messaging == null) return;

    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (_localNotifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'autoguardian_channel',
      'AutoGuardian Notifications',
      channelDescription: 'Notifications from AutoGuardian system',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _localNotifications!.show(
      message.hashCode,
      message.notification?.title ?? 'AutoGuardian Alert',
      message.notification?.body ?? 'New notification received',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification taps
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on message type
    final data = message.data;
    
    switch (data['type']) {
      case 'anomaly':
        // Navigate to anomaly details
        print('Navigate to anomaly details');
        break;
      case 'alert':
        // Navigate to alerts screen
        print('Navigate to alerts screen');
        break;
      case 'kill_switch':
        // Navigate to home screen
        print('Navigate to home screen');
        break;
      default:
        print('Unknown notification type: ${data['type']}');
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    return await _storage.read(key: 'fcm_token');
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    await _messaging!.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    await _messaging!.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message received: ${message.data}');
  
  // Handle background message processing
  if (message.data['type'] == 'anomaly') {
    // Process anomaly in background
    print('Processing anomaly in background: ${message.data['reason']}');
  }
} 