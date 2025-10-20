import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fire_hotspot.dart';

class FIRMSService {
  static const String _baseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area';
  static final String _mapKey = dotenv.env['MAP_API_KEY'] ?? '';

  // Simple in-memory cache with background refresh
  static final Map<_CacheKey, _CacheEntry> _cache = {};
  static Duration defaultMaxAge = const Duration(minutes: 5);
  
  // Location-based cache with local storage
  static final Map<String, _LocationCacheEntry> _locationCache = {};
  static Duration locationMaxAge = const Duration(hours: 1);
  static SharedPreferences? _prefs;

  static Future<List<FireHotspot>> fetchFireData({
    String source = 'VIIRS_SNPP_NRT',
    String area = 'world',
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true, // NEW: Filter option
    // Caching controls
    bool useCache = true,
    Duration? maxAge,
    void Function(List<FireHotspot> freshData)? onBackgroundUpdated,
  }) async {
    final Duration ttl = maxAge ?? defaultMaxAge;
    final _CacheKey key = _CacheKey(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date ?? '',
      filterRealFiresOnly: filterRealFiresOnly,
    );

    if (!useCache) {
      return _fetchFromApi(
        source: source,
        area: area,
        dayRange: dayRange,
        date: date,
        filterRealFiresOnly: filterRealFiresOnly,
      );
    }

    // Serve from cache if fresh
    final _CacheEntry? existing = _cache[key];
    final DateTime now = DateTime.now().toUtc();
    if (existing != null && now.difference(existing.fetchedAt) < ttl) {
      // Consider refreshing in background if close to stale
      final bool nearExpiry = now.difference(existing.fetchedAt) > ttl * 0.8;
      if (nearExpiry && !existing.inFlight) {
        _refreshInBackground(
          key: key,
          onBackgroundUpdated: onBackgroundUpdated,
        );
      }
      return existing.data;
    }

    // If stale cache exists, return it immediately and refresh in background
    if (existing != null && existing.data.isNotEmpty) {
      if (!existing.inFlight) {
        _refreshInBackground(
          key: key,
          onBackgroundUpdated: onBackgroundUpdated,
        );
      }
      return existing.data;
    }

    // No cache: fetch now
    final List<FireHotspot> fresh = await _fetchFromApi(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
    _cache[key] = _CacheEntry(data: fresh, fetchedAt: now, inFlight: false);
    return fresh;
  }

  static List<FireHotspot> _parseFireData(
    String csvData, {
    bool filterRealFiresOnly = true,
    bool isLandsat = false,
  }) {
    if (csvData.isEmpty) {
     
      return [];
    }

    final lines = csvData.split('\n');
    if (lines.length < 2) {
      print('❌ No fire data available in the response.');
      return [];
    }

   

    final allHotspots = <FireHotspot>[];
    final filteredHotspots = <FireHotspot>[];
    int totalCount = 0;
    int realFireCount = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final fields = line.split(',');
        final bool looksLandsat = isLandsat || fields.length == 11;
        if (!looksLandsat && fields.length >= 13) {
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
        } else if (looksLandsat && fields.length >= 11) {
          try {
            totalCount++;
            final hotspot = FireHotspot.fromLandsatCsv(fields);
            allHotspots.add(hotspot);
            if (hotspot.isRealFire) {
              realFireCount++;
              filteredHotspots.add(hotspot);
            }
          } catch (e) {
            print('❌ Error parsing LANDSAT line $i: $e');
          }
        }
      }
    }


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

  // Convenience: USA + Canada bbox for LANDSAT
  static Future<List<FireHotspot>> fetchLandsatForUsaCanada({
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true,
  }) {
    // Rough bounding box: west, south, east, north
    // Covers contiguous US, Alaska, Canada (broad box)
    const double west = -170.0;
    const double south = 24.0; // includes Hawaii lower bound, adjust if needed
    const double east = -52.0;
    const double north = 72.0;
    final area = '$west,$south,$east,$north';
    return fetchFireData(
      source: 'LANDSAT_NRT',
      area: area,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
  }

  // Location-based caching with local storage persistence
  static Future<List<FireHotspot>> fetchFireDataForLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    String source = 'LANDSAT_NRT',
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true,
    Duration? maxAge,
    void Function(List<FireHotspot> freshData)? onBackgroundUpdated,
  }) async {
    await _ensurePrefsInitialized();
    
    final Duration ttl = maxAge ?? locationMaxAge;
    final String locationKey = _generateLocationKey(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      source: source,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );

    // Check memory cache first
    final _LocationCacheEntry? memoryEntry = _locationCache[locationKey];
    final DateTime now = DateTime.now().toUtc();
    
    if (memoryEntry != null && now.difference(memoryEntry.fetchedAt) < ttl) {
      // Consider background refresh if near expiry
      final bool nearExpiry = now.difference(memoryEntry.fetchedAt) > ttl * 0.8;
      if (nearExpiry && !memoryEntry.inFlight) {
        _refreshLocationInBackground(
          locationKey: locationKey,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          source: source,
          dayRange: dayRange,
          date: date,
          filterRealFiresOnly: filterRealFiresOnly,
          onBackgroundUpdated: onBackgroundUpdated,
        );
      }
      return memoryEntry.data;
    }

    // Check local storage for offline data
    final List<FireHotspot>? storedData = await _loadLocationFromStorage(locationKey);
    if (storedData != null && storedData.isNotEmpty) {
      // Return stored data immediately and refresh in background
      if (memoryEntry == null || !memoryEntry.inFlight) {
        _refreshLocationInBackground(
          locationKey: locationKey,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          source: source,
          dayRange: dayRange,
          date: date,
          filterRealFiresOnly: filterRealFiresOnly,
          onBackgroundUpdated: onBackgroundUpdated,
        );
      }
      return storedData;
    }

    // No cache: fetch now
    final List<FireHotspot> fresh = await _fetchLocationFromApi(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      source: source,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
    
    // Update both memory and storage
    _locationCache[locationKey] = _LocationCacheEntry(
      data: fresh,
      fetchedAt: now,
      inFlight: false,
    );
    await _saveLocationToStorage(locationKey, fresh, now);
    
    return fresh;
  }

 
  static Future<List<FireHotspot>> forceRefreshLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    String source = 'LANDSAT_NRT',
    int dayRange = 1,
    String? date,
    bool filterRealFiresOnly = true,
  }) async {
    await _ensurePrefsInitialized();
    
    final String locationKey = _generateLocationKey(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      source: source,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );

    final List<FireHotspot> fresh = await _fetchLocationFromApi(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      source: source,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );

    final DateTime now = DateTime.now().toUtc();
    _locationCache[locationKey] = _LocationCacheEntry(
      data: fresh,
      fetchedAt: now,
      inFlight: false,
    );
    await _saveLocationToStorage(locationKey, fresh, now);
    
    return fresh;
  }

 
  static Future<List<FireHotspot>> forceRefresh({
    required String source,
    required String area,
    required int dayRange,
    String? date,
    bool filterRealFiresOnly = true,
  }) async {
    final _CacheKey key = _CacheKey(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date ?? '',
      filterRealFiresOnly: filterRealFiresOnly,
    );
    final List<FireHotspot> fresh = await _fetchFromApi(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
    _cache[key] = _CacheEntry(data: fresh, fetchedAt: DateTime.now().toUtc(), inFlight: false);
    return fresh;
  }

  // Internal: background refresh
  static void _refreshInBackground({
    required _CacheKey key,
    void Function(List<FireHotspot> freshData)? onBackgroundUpdated,
  }) {
    final existing = _cache[key];
    if (existing != null && existing.inFlight) return;
    _cache[key] = (existing ?? _CacheEntry.empty()).copyWith(inFlight: true);

    Future.microtask(() async {
      try {
        final List<FireHotspot> fresh = await _fetchFromApi(
          source: key.source,
          area: key.area,
          dayRange: key.dayRange,
          date: key.date.isEmpty ? null : key.date,
          filterRealFiresOnly: key.filterRealFiresOnly,
        );
        _cache[key] = _CacheEntry(
          data: fresh,
          fetchedAt: DateTime.now().toUtc(),
          inFlight: false,
        );
        if (onBackgroundUpdated != null) {
          onBackgroundUpdated(fresh);
        }
      } catch (_) {
        // Keep existing cache on failure; clear inflight flag
        final prev = _cache[key];
        if (prev != null) {
          _cache[key] = prev.copyWith(inFlight: false);
        }
      }
    });
  }


  static Future<List<FireHotspot>> _fetchFromApi({
    required String source,
    required String area,
    required int dayRange,
    String? date,
    bool filterRealFiresOnly = true,
  }) async {
    try {
      final String effectiveDate = date ?? '';
      final String dateSuffix = effectiveDate.isNotEmpty ? '/$effectiveDate' : '';
      final String url = '$_baseUrl/csv/$_mapKey/$source/$area/$dayRange$dateSuffix';

      print('🌍 FIRMS API Request: $url');
      final response = await http.get(Uri.parse(url));
      // dev.log('FIRMS API Response Code: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Successfully fetched fire data');
      
        return _parseFireData(
          response.body,
          filterRealFiresOnly: filterRealFiresOnly,
          isLandsat: source == 'LANDSAT_NRT',
        );
      } else {
        print('❌ Error fetching fire data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      
      return [];
    }
  }


  static Future<void> _ensurePrefsInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _generateLocationKey({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String source,
    required int dayRange,
    String? date,
    required bool filterRealFiresOnly,
  }) {
    // Create a consistent key based on location and parameters
    final String latStr = latitude.toStringAsFixed(2);
    final String lonStr = longitude.toStringAsFixed(2);
    final String radiusStr = radiusKm.toStringAsFixed(1);
    final String dateStr = date ?? 'latest';
    return 'location_${source}_${latStr}_${lonStr}_${radiusStr}_${dayRange}_${dateStr}_${filterRealFiresOnly}';
  }

  static Future<void> _saveLocationToStorage(
    String key,
    List<FireHotspot> data,
    DateTime fetchedAt,
  ) async {
    try {
      final Map<String, dynamic> cacheData = {
        'data': data.map((h) => h.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };
      await _prefs!.setString('firms_location_$key', jsonEncode(cacheData));
    } catch (e) {
      print('❌ Error saving location cache: $e');
    }
  }

  static Future<List<FireHotspot>?> _loadLocationFromStorage(String key) async {
    try {
      final String? cached = _prefs!.getString('firms_location_$key');
      if (cached == null) return null;
      
      final Map<String, dynamic> cacheData = jsonDecode(cached);
      final List<dynamic> hotspotsJson = cacheData['data'] as List<dynamic>;
      
      return hotspotsJson.map((json) => FireHotspot.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading location cache: $e');
      return null;
    }
  }

  static void _refreshLocationInBackground({
    required String locationKey,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String source,
    required int dayRange,
    String? date,
    required bool filterRealFiresOnly,
    void Function(List<FireHotspot> freshData)? onBackgroundUpdated,
  }) {
    final existing = _locationCache[locationKey];
    if (existing != null && existing.inFlight) return;
    
    _locationCache[locationKey] = (existing ?? _LocationCacheEntry.empty()).copyWith(inFlight: true);

    Future.microtask(() async {
      try {
        final List<FireHotspot> fresh = await _fetchLocationFromApi(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          source: source,
          dayRange: dayRange,
          date: date,
          filterRealFiresOnly: filterRealFiresOnly,
        );
        
        final DateTime now = DateTime.now().toUtc();
        _locationCache[locationKey] = _LocationCacheEntry(
          data: fresh,
          fetchedAt: now,
          inFlight: false,
        );
        await _saveLocationToStorage(locationKey, fresh, now);
        
        if (onBackgroundUpdated != null) {
          onBackgroundUpdated(fresh);
        }
      } catch (_) {
        // Keep existing cache on failure; clear inflight flag
        final prev = _locationCache[locationKey];
        if (prev != null) {
          _locationCache[locationKey] = prev.copyWith(inFlight: false);
        }
      }
    });
  }

  static Future<List<FireHotspot>> _fetchLocationFromApi({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String source,
    required int dayRange,
    String? date,
    required bool filterRealFiresOnly,
  }) async {
    // Convert radius to bounding box (rough approximation)
    const double kmPerDegree = 111.0; // approximate km per degree
    final double latDelta = radiusKm / kmPerDegree;
    final double lonDelta = radiusKm / (kmPerDegree * cos(latitude * pi / 180));
    
    final double west = longitude - lonDelta;
    final double south = latitude - latDelta;
    final double east = longitude + lonDelta;
    final double north = latitude + latDelta;
    
    final String area = '$west,$south,$east,$north';
    
    return _fetchFromApi(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date,
      filterRealFiresOnly: filterRealFiresOnly,
    );
  }
}

class _CacheKey {
  final String source;
  final String area;
  final int dayRange;
  final String date;
  final bool filterRealFiresOnly;

  const _CacheKey({
    required this.source,
    required this.area,
    required this.dayRange,
    required this.date,
    required this.filterRealFiresOnly,
  });

  @override
  bool operator ==(Object other) {
    return other is _CacheKey &&
        other.source == source &&
        other.area == area &&
        other.dayRange == dayRange &&
        other.date == date &&
        other.filterRealFiresOnly == filterRealFiresOnly;
  }

  @override
  int get hashCode => Object.hash(source, area, dayRange, date, filterRealFiresOnly);
}

class _CacheEntry {
  final List<FireHotspot> data;
  final DateTime fetchedAt;
  final bool inFlight;

  _CacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.inFlight,
  });

  factory _CacheEntry.empty() {
    return _CacheEntry(
      data: const [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      inFlight: false,
    );
  }

  _CacheEntry copyWith({
    List<FireHotspot>? data,
    DateTime? fetchedAt,
    bool? inFlight,
  }) {
    return _CacheEntry(
      data: data ?? this.data,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}

class _LocationCacheEntry {
  final List<FireHotspot> data;
  final DateTime fetchedAt;
  final bool inFlight;

  _LocationCacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.inFlight,
  });

  factory _LocationCacheEntry.empty() {
    return _LocationCacheEntry(
      data: const [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      inFlight: false,
    );
  }

  _LocationCacheEntry copyWith({
    List<FireHotspot>? data,
    DateTime? fetchedAt,
    bool? inFlight,
  }) {
    return _LocationCacheEntry(
      data: data ?? this.data,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}