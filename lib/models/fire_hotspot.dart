import '../services/geocoding_service.dart';

class FireHotspot {
  final double latitude;
  final double longitude;
  final double brightness;       
  final double scan;              
  final double track;             
  final String acqDate;           
  final String acqTime;         
  final String satellite;         
  final String confidence;        
  final String version;           
  final double brightT31;         
  final double frp;               
  final String dayNight;          

  FireHotspot({
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.scan,
    required this.track,
    required this.acqDate,
    required this.acqTime,
    required this.satellite,
    required this.confidence,
    required this.version,
    required this.brightT31,
    required this.frp,
    required this.dayNight,
  });

  // Parse from CSV fields
  factory FireHotspot.fromCsv(List<String> fields) {
    return FireHotspot(
      latitude: double.parse(fields[0]),
      longitude: double.parse(fields[1]),
      brightness: double.tryParse(fields[2]) ?? 0.0,
      scan: double.tryParse(fields[3]) ?? 0.0,
      track: double.tryParse(fields[4]) ?? 0.0,
      acqDate: fields[5],
      acqTime: fields[6],
      satellite: fields[7],
      confidence: _normalizeConfidence(fields[8]), // map short/varied codes
      version: fields[9],
      brightT31: double.tryParse(fields[10]) ?? 0.0,
      frp: double.tryParse(fields[11]) ?? 0.0,
      dayNight: fields[12],
    );
  }

  // Parse LANDSAT_NRT CSV (different schema, fewer columns)
  factory FireHotspot.fromLandsatCsv(List<String> fields) {
   
    return FireHotspot(
      latitude: double.parse(fields[0]),
      longitude: double.parse(fields[1]),
      brightness: 0.0, // not provided in LANDSAT csv
      scan: double.tryParse(fields[4]) ?? 0.0,
      track: double.tryParse(fields[5]) ?? 0.0,
      acqDate: fields[6],
      acqTime: fields[7],
      satellite: fields[8],
      confidence: _normalizeConfidence(fields[9]),
      version: 'LANDSAT_NRT',
      brightT31: 0.0,
      frp: 0.0,
      dayNight: fields[10],
    );
  }

  static String _normalizeConfidence(String raw) {
    final v = raw.trim().toLowerCase();
    // Map short codes to words
    if (v == 'h') return 'high';
    if (v == 'n') return 'nominal';
    if (v == 'l') return 'low';
    // Already in word form or numeric
    if (v == 'high' || v == 'nominal' || v == 'low') return v;
    return v;
  }

  // Check if this is likely a real fire
  bool get isRealFire {
    // High confidence fires are always considered real
    if (confidence == 'high') return true;
    
    // Nominal confidence fires with significant FRP (intense fire)
    if (confidence == 'nominal' && frp > 5.0) return true;
    
    // Very hot fires (likely wildfires) - brightness > 350K indicates intense heat
    if (brightness > 350.0) return true;
    
    // Low confidence fires with very high FRP (extreme intensity)
    if (confidence == 'low' && frp > 20.0) return true;
    
    return false;
  }

  // Get fire intensity level
  String get intensityLevel {
    if (frp > 50.0) return 'Extreme';
    if (frp > 20.0) return 'High';
    if (frp > 10.0) return 'Medium';
    return 'Low';
  }

  // Get fire color based on intensity
  String get colorCategory {
    if (confidence == 'high' && frp > 20.0) return 'red';
    if (confidence == 'high' || frp > 10.0) return 'orange';
    if (confidence == 'nominal') return 'yellow';
    return 'green';
  }

  // Generate a descriptive fire name based on location
  Future<String> get fireName async {
    final String location = await GeocodingService.getLocationName(latitude, longitude);
    final String intensity = _getFireIntensityDescriptor();
    
    return '$location $intensity Fire';
  }

  String _getFireIntensityDescriptor() {
    if (frp > 50.0) return 'Wildfire';
    if (frp > 20.0) return 'Fire';
    if (frp > 10.0) return 'Fire';
    if (confidence == 'high') return 'Fire';
    return 'Thermal Anomaly';
  }


  String _getTimeOfDay() {
    try {
      final intValue = int.parse(acqTime);
      
      // If acqTime is a day of year (1-365), use dayNight field instead
      if (intValue >= 1 && intValue <= 365) {
        return dayNight == 'D' ? 'Day' : 'Night';
      }
      
      // If it's actual time format (HHMM)
      if (acqTime.length >= 4) {
        final hour = int.parse(acqTime.substring(0, 2));
        if (hour >= 6 && hour < 12) return 'Morning';
        if (hour >= 12 && hour < 18) return 'Afternoon';
        if (hour >= 18 && hour < 22) return 'Evening';
        return 'Night';
      }
    } catch (e) {
      // Fallback
    }
    return dayNight == 'D' ? 'Day' : 'Night';
  }

  @override
  String toString() {
    return 'FireHotspot(lat: $latitude, lon: $longitude, confidence: $confidence, FRP: ${frp.toStringAsFixed(2)} MW, intensity: $intensityLevel)';
  }

  // JSON serialization for caching
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'brightness': brightness,
      'scan': scan,
      'track': track,
      'acqDate': acqDate,
      'acqTime': acqTime,
      'satellite': satellite,
      'confidence': confidence,
      'version': version,
      'brightT31': brightT31,
      'frp': frp,
      'dayNight': dayNight,
    };
  }

  factory FireHotspot.fromJson(Map<String, dynamic> json) {
    return FireHotspot(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      scan: (json['scan'] as num?)?.toDouble() ?? 0.0,
      track: (json['track'] as num?)?.toDouble() ?? 0.0,
      acqDate: json['acqDate'] as String,
      acqTime: json['acqTime'] as String,
      satellite: json['satellite'] as String,
      confidence: json['confidence'] as String,
      version: json['version'] as String,
      brightT31: (json['brightT31'] as num?)?.toDouble() ?? 0.0,
      frp: (json['frp'] as num?)?.toDouble() ?? 0.0,
      dayNight: json['dayNight'] as String,
    );
  }
}
