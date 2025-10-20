import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class UserReport {
  final String id;
  final String reportedByEmail;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime createdAt;
  final double? radiusMeters;
  final double distanceKm;
  final bool isNearby;

  UserReport({
    required this.id,
    required this.reportedByEmail,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.createdAt,
    this.radiusMeters,
    required this.distanceKm,
    required this.isNearby,
  });

  static Future<UserReport> fromFirestore(
    DocumentSnapshot doc,
    double userLat,
    double userLon,
    double alertRadius,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    
    final distance = _calculateDistance(
      userLat,
      userLon,
      data['latitude'] as double,
      data['longitude'] as double,
    );
    
    final isNearby = distance <= alertRadius;
    
    return UserReport(
      id: doc.id,
      reportedByEmail: data['reportedByEmail'] as String? ?? 'Unknown',
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      description: data['description'] as String? ?? 'Fire reported by community member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble(),
      distanceKm: distance,
      isNearby: isNearby,
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String get reporterName {
    // Extract name from email (everything before @)
    final emailParts = reportedByEmail.split('@');
    if (emailParts.isNotEmpty) {
      return emailParts[0];
    }
    return 'Community Member';
  }
}

class UserReportsService {
  static List<UserReport> _currentReports = [];
  static DateTime? _lastUpdate;
  static const Duration _updateInterval = Duration(minutes: 5); // More frequent updates for user reports

  static Future<List<UserReport>> getUserReports({double? userLat, double? userLon}) async {
    try {
      // Get user's alert radius
      final alertRadius = await _getAlertRadius();
      
      // Get current user location if not provided
      if (userLat == null || userLon == null) {
        final position = await _getCurrentPositionSafely();
        if (position == null) {
          log('[UserReportsService] No user location available');
          return [];
        }
        userLat = position.latitude;
        userLon = position.longitude;
      }

      // Check if we need to update data
      final shouldUpdate = _lastUpdate == null || 
          DateTime.now().difference(_lastUpdate!) > _updateInterval;

      if (shouldUpdate) {
        await _updateUserReports(userLat, userLon, alertRadius);
      }

      // Filter to show only nearby reports by default
      final nearbyReports = _currentReports.where((report) => report.isNearby).toList();
      
      // Sort by distance (closest first)
      nearbyReports.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      return nearbyReports;
    } catch (e) {
      log('[UserReportsService] Error getting user reports: $e');
      return [];
    }
  }

  static Future<void> _updateUserReports(double userLat, double userLon, double alertRadius) async {
    try {
      log('[UserReportsService] Updating user reports...');
      
      // Fetch user reports from Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit to recent reports
          .get();
      
      log('[UserReportsService] Fetched ${snapshot.docs.length} user reports');

      // Convert to UserReport objects
      _currentReports = await Future.wait(
        snapshot.docs.map((doc) {
          return UserReport.fromFirestore(doc, userLat, userLon, alertRadius);
        })
      );

      _lastUpdate = DateTime.now();
      log('[UserReportsService] Updated ${_currentReports.length} user reports');
    } catch (e) {
      log('[UserReportsService] Error updating user reports: $e');
    }
  }

  static Future<List<UserReport>> getAllUserReports({double? userLat, double? userLon}) async {
    try {
      // Get user's alert radius
      final alertRadius = await _getAlertRadius();
      
      // Get current user location if not provided
      if (userLat == null || userLon == null) {
        final position = await _getCurrentPositionSafely();
        if (position == null) {
          log('[UserReportsService] No user location available');
          return [];
        }
        userLat = position.latitude;
        userLon = position.longitude;
      }

      // Force update to get all reports
      await _updateUserReports(userLat, userLon, alertRadius);

      // Return all reports sorted by distance
      final allReports = List<UserReport>.from(_currentReports);
      allReports.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      return allReports;
    } catch (e) {
      log('[UserReportsService] Error getting all user reports: $e');
      return [];
    }
  }

  static Future<void> refreshReports() async {
    _lastUpdate = null; // Force refresh on next request
  }

  static List<UserReport> getCachedReports() {
    return List.from(_currentReports);
  }

  static Future<double> _getAlertRadius() async {
    try {
      return await UserService.getAlertRadius() ?? 16.0;
    } catch (e) {
      log('[UserReportsService] Error getting alert radius: $e');
      return 16.0; // Default 16km radius
    }
  }

  static Future<Position?> _getCurrentPositionSafely() async {
    try {
      return await UserService.getCurrentPositionSafely();
    } catch (e) {
      log('[UserReportsService] Error getting current position: $e');
      return null;
    }
  }
}
