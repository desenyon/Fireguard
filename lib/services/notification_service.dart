import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as dev;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Request notification permissions
    await _requestPermissions();
    
    // Set up FCM message handlers
    await _setupMessageHandlers();
    
    // Get and log FCM token
    final token = await _messaging.getToken();
    dev.log('[NotificationService] FCM Token: $token');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for fire alerts
    await _createFireAlertChannel();
  }

  Future<void> _createFireAlertChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fire_alerts',
      'Fire Alerts',
      description: 'Notifications for fire reports and safety alerts',
      importance: Importance.high,
      // priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    dev.log('[NotificationService] Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle messages when app is opened from terminated state
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    dev.log('[NotificationService] Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    dev.log('[NotificationService] App opened from notification: ${message.messageId}');
    
    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fire_alerts',
      'Fire Alerts',
      channelDescription: 'Notifications for fire reports and safety alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B00),
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    dev.log('[NotificationService] Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final reportId = data['reportId'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];

    dev.log('[NotificationService] Navigation data - Type: $type, ReportId: $reportId, Lat: $latitude, Lng: $longitude');

    // TODO: Implement navigation to appropriate screen based on notification data
    // This could navigate to the map view with the fire report location
    // or show a detailed alert screen
  }

  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    dev.log('[NotificationService] Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    dev.log('[NotificationService] Unsubscribed from topic: $topic');
  }
}
