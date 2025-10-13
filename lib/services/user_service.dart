import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Position?> getCurrentPositionSafely() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      dev.log('[UserService] getCurrentPositionSafely error: $e');
      return null;
    }
  }

  static Future<String?> requestNotificationPermissionAndToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      dev.log('[UserService] Notification permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final String? token = await messaging.getToken();
        dev.log('[UserService] FCM token: $token');
        return token;
      }
      return null;
    } catch (e) {
      dev.log('[UserService] requestNotificationPermissionAndToken error: $e');
      return null;
    }
  }

  static Future<void> upsertUserDocument({
    required User user,
    Position? position,
    String? fcmToken,
  }) async {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (position != null) {
        data['location'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }
      if (fcmToken != null) {
        data['fcmToken'] = fcmToken;
      }

      await _firestore.collection('users').doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );
      dev.log('[UserService] Upserted user document for ${user.uid}');
    } catch (e) {
      dev.log('[UserService] upsertUserDocument error: $e');
      rethrow;
    }
  }

  static Future<void> syncSignedInUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final Position? position = await getCurrentPositionSafely();
    final String? token = await requestNotificationPermissionAndToken();
    await upsertUserDocument(user: user, position: position, fcmToken: token);
  }
}


