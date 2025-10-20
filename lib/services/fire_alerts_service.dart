import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import '../models/fire_hotspot.dart';
import 'firms_service.dart';
import 'user_service.dart';
import 'user_reports_service.dart';

class FireAlert {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String severity;
  final DateTime detectedAt;
  final String description;
  final bool isNearby;
  final String type; // 'satellite' or 'user_report'
  final String? reporterEmail; // For user reports

  FireAlert({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.severity,
    required this.detectedAt,
    required this.description,
    required this.isNearby,
    required this.type,
    this.reporterEmail,
  });

  static Future<FireAlert> fromFireHotspot(FireHotspot hotspot, double userLat, double userLon, double alertRadius) async {
    final distance = _calculateDistance(userLat, userLon, hotspot.latitude, hotspot.longitude);
    final isNearby = distance <= alertRadius;
    
    return FireAlert(
      id: 'satellite_${hotspot.latitude}_${hotspot.longitude}_${hotspot.acqDate}',
      name: await hotspot.fireName,
      latitude: hotspot.latitude,
      longitude: hotspot.longitude,
      distanceKm: distance,
      severity: _getSeverityFromFrp(hotspot.frp),
      detectedAt: DateTime.now(), // You could parse hotspot.acqDate if needed
      description: 'Fire detected via satellite',
      isNearby: isNearby,
      type: 'satellite',
    );
  }

  static FireAlert fromUserReport(UserReport report) {
    return FireAlert(
      id: 'user_${report.id}',
      name: 'Community Report - ${report.reporterName}',
      latitude: report.latitude,
      longitude: report.longitude,
      distanceKm: report.distanceKm,
      severity: 'High', // User reports are considered high priority
      detectedAt: report.createdAt,
      description: report.description,
      isNearby: report.isNearby,
      type: 'user_report',
      reporterEmail: report.reportedByEmail,
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  static String _getSeverityFromFrp(double frp) {
    if (frp > 50.0) return 'Critical';
    if (frp > 20.0) return 'High';
    if (frp > 10.0) return 'Medium';
    return 'Low';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(detectedAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class FireAlertsService {
  static List<FireAlert> _currentAlerts = [];
  static DateTime? _lastUpdate;
  static const Duration _updateInterval = Duration(minutes: 15);

  static Future<List<FireAlert>> getFireAlerts({double? userLat, double? userLon}) async {
    try {
      // Get user's alert radius
      final alertRadius = await UserService.getAlertRadius() ?? 16.0;
      
      // Get current user location if not provided
      if (userLat == null || userLon == null) {
        final position = await UserService.getCurrentPositionSafely();
        if (position == null) {
          log('[FireAlertsService] No user location available');
          return [];
        }
        userLat = position.latitude;
        userLon = position.longitude;
      }

      // Check if we need to update data
      final shouldUpdate = _lastUpdate == null || 
          DateTime.now().difference(_lastUpdate!) > _updateInterval;

      if (shouldUpdate) {
        await _updateFireData(userLat, userLon, alertRadius);
      }

      // Get both satellite and user report alerts
      final satelliteAlerts = _currentAlerts.where((alert) => alert.isNearby).toList();
      final userReports = await UserReportsService.getUserReports(userLat: userLat, userLon: userLon);
      final userReportAlerts = userReports.map((report) => FireAlert.fromUserReport(report)).toList();

      // Combine all alerts
      final allAlerts = [...satelliteAlerts, ...userReportAlerts];
      
      // Sort by distance (closest first)
      allAlerts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      return allAlerts;
    } catch (e) {
      log('[FireAlertsService] Error getting fire alerts: $e');
      return [];
    }
  }

  static Future<void> _updateFireData(double userLat, double userLon, double alertRadius) async {
    try {
      log('[FireAlertsService] Updating fire data...');
      
      // Fetch latest fire data from FIRMS
      final hotspots = await FIRMSService.fetchLatestGlobalFireData();
      log('[FireAlertsService] Fetched ${hotspots.length} fire hotspots');

      // Convert to alerts
      _currentAlerts = await Future.wait(
        hotspots.map((hotspot) {
          return FireAlert.fromFireHotspot(hotspot, userLat, userLon, alertRadius);
        })
      );

      _lastUpdate = DateTime.now();
      log('[FireAlertsService] Updated ${_currentAlerts.length} fire alerts');
    } catch (e) {
      log('[FireAlertsService] Error updating fire data: $e');
    }
  }

  static Future<List<FireAlert>> getAllFireAlerts({double? userLat, double? userLon}) async {
    try {
      // Get user's alert radius
      final alertRadius = await UserService.getAlertRadius() ?? 16.0;
      
      // Get current user location if not provided
      if (userLat == null || userLon == null) {
        final position = await UserService.getCurrentPositionSafely();
        if (position == null) {
          log('[FireAlertsService] No user location available');
          return [];
        }
        userLat = position.latitude;
        userLon = position.longitude;
      }

      // Force update to get all fires
      await _updateFireData(userLat, userLon, alertRadius);

      // Return all alerts sorted by distance
      final allAlerts = List<FireAlert>.from(_currentAlerts);
      allAlerts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      return allAlerts;
    } catch (e) {
      log('[FireAlertsService] Error getting all fire alerts: $e');
      return [];
    }
  }

  static Future<void> refreshAlerts() async {
    _lastUpdate = null; // Force refresh on next request
    await UserReportsService.refreshReports(); // Also refresh user reports
  }

  static List<FireAlert> getCachedAlerts() {
    return List.from(_currentAlerts);
  }
}

