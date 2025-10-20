import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'notification_service.dart';

class UserPresenceService {
  UserPresenceService._();
  static final UserPresenceService instance = UserPresenceService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> savePresence({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    final String? token = await NotificationService().getFCMToken();
    if (token == null) return;

    final String geohash = GeoHasher().encode(latitude, longitude, precision: 9);
    await _db.collection('user_presence').doc(uid).set({
      'uid': uid,
      'fcmToken': token,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}


