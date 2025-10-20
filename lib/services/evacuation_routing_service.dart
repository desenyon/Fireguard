import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/fire_hotspot.dart';

class EvacuationRoutingService {
  EvacuationRoutingService._();

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // pi/180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static FireHotspot? _nearestHotspot(LatLng user, List<FireHotspot> hotspots) {
    if (hotspots.isEmpty) return null;
    FireHotspot nearest = hotspots.first;
    double best = _distanceKm(user.latitude, user.longitude, nearest.latitude, nearest.longitude);
    for (final h in hotspots.skip(1)) {
      final d = _distanceKm(user.latitude, user.longitude, h.latitude, h.longitude);
      if (d < best) {
        best = d;
        nearest = h;
      }
    }
    return nearest;
  }

  // Compute a simple safe target by moving away from the nearest hotspot by a given distance.
  // This is a heuristic; for proper safety zones, integrate official shelter POIs.
  static LatLng computeSafeTarget({
    required LatLng user,
    required List<FireHotspot> hotspots,
    double moveAwayKm = 3.0,
  }) {
    final FireHotspot? nearest = _nearestHotspot(user, hotspots);
    if (nearest == null) {
      // Fallback: move slightly north if no hotspots
      return LatLng(user.latitude + (moveAwayKm / 111.0), user.longitude);
    }

    // Vector from hotspot to user
    final double dLat = user.latitude - nearest.latitude;
    final double dLon = user.longitude - nearest.longitude;
    // If vector too small (same spot), push east
    final double norm = (dLat.abs() + dLon.abs()) < 1e-9 ? 1.0 : sqrt(dLat * dLat + dLon * dLon);
    final double vLat = dLat / norm;
    final double vLon = dLon / norm;

    // Convert km to degrees roughly (1 deg lat ~ 111 km; lon scaled by cos(lat))
    final double degLat = moveAwayKm / 111.0;
    final double cosLat = cos(user.latitude * 0.017453292519943295);
    final double degLon = cosLat == 0 ? 0 : moveAwayKm / (111.0 * cosLat);

    final double targetLat = user.latitude + vLat * degLat;
    final double targetLon = user.longitude + vLon * degLon;
    return LatLng(targetLat, targetLon);
  }

  // Fetch a walking route from OSRM public server
  static Future<List<LatLng>> getWalkingRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final String url = 'https://router.project-osrm.org/route/v1/foot/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final http.Response resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      return [];
    }
    final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return [];
    final geometry = routes.first['geometry'] as Map<String, dynamic>?;
    if (geometry == null) return [];
    final coords = geometry['coordinates'] as List<dynamic>?;
    if (coords == null) return [];
    final List<LatLng> points = [];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final double lon = (c[0] as num).toDouble();
        final double lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }
    }
    return points;
  }
}














