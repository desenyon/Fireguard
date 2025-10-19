import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> createReport({
    required double latitude,
    required double longitude,
    required String reportedByEmail,
    String? description,
    double? radiusMeters,
  }) async {
    log('Creating report at ($latitude, $longitude) by $reportedByEmail');
    await _db.collection('reports').add({
      'latitude': latitude,  // Changed from 'lat' to match Firebase function
      'longitude': longitude,  // Changed from 'lng' to match Firebase function
      'reportedByEmail': reportedByEmail,
      'description': description ?? 'Fire reported by community member',
      'radiusMeters': radiusMeters,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}


