import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/fire_hotspot.dart';

class FIRMSService {
  static const String _baseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area';
  static final String _mapKey = dotenv.env['MAP_API_KEY'] ?? '';

  static Future<List<FireHotspot>> fetchFireData({
    String source = 'VIIRS_SNPP_NRT',
    String area = 'world',
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true, // NEW: Filter option
  }) async {
    try {
      String url = '$_baseUrl/csv/$_mapKey/$source/$area/$dayRange/2025-10-04';
      if (date != null) {
        url += '/$date';
      }

      print('🌍 FIRMS API Request: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('✅ Successfully fetched fire data');
        log(response.body);
        return _parseFireData(
          response.body,
          filterRealFiresOnly: filterRealFiresOnly,
        );
      } else {
        print('❌ Error fetching fire data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return [];
    }
  }

  static List<FireHotspot> _parseFireData(
    String csvData, {
    bool filterRealFiresOnly = true,
  }) {
    if (csvData.isEmpty) {
      print('📭 No fire data available');
      return [];
    }

    final lines = csvData.split('\n');
    if (lines.length < 2) {
      print('📭 No fire data found in response');
      return [];
    }

    print('\n🔥 FIRE DETECTION DATA 🔥');
    print('=' * 60);
    print('Header: ${lines[0]}');
    print('=' * 60);

    final allHotspots = <FireHotspot>[];
    final filteredHotspots = <FireHotspot>[];
    int totalCount = 0;
    int realFireCount = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final fields = line.split(',');
        if (fields.length >= 13) {
          try {
            totalCount++;
            final hotspot = FireHotspot.fromCsv(fields);
            allHotspots.add(hotspot);

            // Check if it's a real fire
            if (hotspot.isRealFire) {
              realFireCount++;
              filteredHotspots.add(hotspot);
              
              print('🔥 Fire #$realFireCount: '
                  'Lat: ${hotspot.latitude.toStringAsFixed(4)}, '
                  'Lon: ${hotspot.longitude.toStringAsFixed(4)} | '
                  'Confidence: ${hotspot.confidence}, '
                  'FRP: ${hotspot.frp.toStringAsFixed(2)} MW, '
                  'Intensity: ${hotspot.intensityLevel}');
            }
          } catch (e) {
            print('❌ Error parsing line $i: $e');
          }
        }
      }
    }

    print('=' * 60);
    print('📊 Total thermal anomalies detected: $totalCount');
    print('🔥 Real fires (filtered): $realFireCount');
    print('📉 Filtered out: ${totalCount - realFireCount} (low confidence/small burns)');
    print('=' * 60);

    return filterRealFiresOnly ? filteredHotspots : allHotspots;
  }

  // Fetch only real fires (default)
  static Future<List<FireHotspot>> fetchLatestGlobalFireData() {
    return fetchFireData(filterRealFiresOnly: true);
  }

  // Fetch all thermal anomalies (including low confidence)
  static Future<List<FireHotspot>> fetchAllThermalAnomalies() {
    return fetchFireData(filterRealFiresOnly: false);
  }

  // Fetch fire data for a specific date
  static Future<List<FireHotspot>> fetchFireDataForDate(String date) {
    return fetchFireData(date: date, filterRealFiresOnly: true);
  }

  // Fetch fire data for a specific area with custom coordinates
  static Future<List<FireHotspot>> fetchFireDataForArea({
    required double west,
    required double south,
    required double east,
    required double north,
    String source = 'VIIRS_SNPP_NRT',
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true,
  }) {
    final area = '$west,$south,$east,$north';
    return fetchFireData(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
  }
}