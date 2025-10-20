import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

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
      // Use the centralized notification service
      return await NotificationService().getFCMToken();
    } catch (e) {
      dev.log('[UserService] requestNotificationPermissionAndToken error: $e');
      return null;
    }
  }

  static Future<void> upsertUserDocument({
    required User user,
    Position? position,
    String? fcmToken,
    double? alertRadius,
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
      if (alertRadius != null) {
        data['alertRadius'] = alertRadius;
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

  static Future<void> updateAlertRadius(double radius) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        dev.log('[UserService] No authenticated user found for updating alert radius');
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'alertRadius': radius,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      dev.log('[UserService] Updated alert radius to $radius for user ${user.uid}');
    } catch (e) {
      dev.log('[UserService] updateAlertRadius error: $e');
      rethrow;
    }
  }

  static Future<double?> getAlertRadius() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        dev.log('[UserService] No authenticated user found for getting alert radius');
        return null;
      }

      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final radius = data?['alertRadius'] as double?;
        dev.log('[UserService] Retrieved alert radius: $radius for user ${user.uid}');
        return radius;
      }
      return null;
    } catch (e) {
      dev.log('[UserService] getAlertRadius error: $e');
      return null;
    }
  }
}


