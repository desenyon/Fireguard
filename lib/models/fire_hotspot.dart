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
    // Expected order:
    // 0:lat, 1:lon, 2:path, 3:row, 4:scan, 5:track, 6:acq_date, 7:acq_time,
    // 8:satellite, 9:confidence (L/N/H), 10:daynight
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
    // High confidence fires only
    if (confidence == 'high') return true;
    
    // // Nominal confidence with high FRP (intense fire)
    // if (confidence == 'nominal' && frp > 10.0) return true;
    
    // // // Very hot fires (likely wildfires)
    if (brightness > 366.0) return true;
    
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

  // Generate a descriptive fire name based on characteristics
  String get fireName {
    final String size = _getFireSizeName();
    final String location = _getLocationName();
    final String time = _getTimeOfDay();
    
    return '$size Fire near $location ($time)';
  }

  String _getFireSizeName() {
    if (frp > 50.0) return 'Major';
    if (frp > 20.0) return 'Large';
    if (frp > 10.0) return 'Medium';
    return 'Small';
  }

  String _getLocationName() {
    // Generate more specific location names based on coordinates
    final double lat = latitude.abs();
    final double lon = longitude.abs();
    
    // Generate region-based names with more detail
    if (latitude > 60) {
      if (longitude > -180 && longitude < -120) return 'Alaska/Northern Canada';
      if (longitude > -120 && longitude < -60) return 'Northern Canada';
      if (longitude > -60 && longitude < 0) return 'Northern Europe';
      if (longitude > 0 && longitude < 60) return 'Northern Russia';
      if (longitude > 60 && longitude < 120) return 'Siberia';
      if (longitude > 120 && longitude < 180) return 'Northern Asia';
      return 'Arctic Region';
    }
    
    if (latitude > 40) {
      if (longitude > -180 && longitude < -120) return 'Western North America';
      if (longitude > -120 && longitude < -80) return 'Central North America';
      if (longitude > -80 && longitude < -40) return 'Eastern North America';
      if (longitude > -40 && longitude < 0) return 'Northern Atlantic';
      if (longitude > 0 && longitude < 40) return 'Europe';
      if (longitude > 40 && longitude < 80) return 'Central Asia';
      if (longitude > 80 && longitude < 120) return 'Eastern Asia';
      if (longitude > 120 && longitude < 180) return 'Pacific Region';
      return 'Northern Region';
    }
    
    if (latitude > 20) {
      if (longitude > -180 && longitude < -120) return 'Western North America';
      if (longitude > -120 && longitude < -80) return 'Southwestern USA';
      if (longitude > -80 && longitude < -40) return 'Southeastern USA';
      if (longitude > -40 && longitude < 0) return 'Atlantic Ocean';
      if (longitude > 0 && longitude < 40) return 'Mediterranean';
      if (longitude > 40 && longitude < 80) return 'Middle East/Central Asia';
      if (longitude > 80 && longitude < 120) return 'Eastern Asia';
      if (longitude > 120 && longitude < 180) return 'Western Pacific';
      return 'Subtropical Region';
    }
    
    if (latitude > 0) {
      if (longitude > -180 && longitude < -120) return 'Pacific Ocean';
      if (longitude > -120 && longitude < -80) return 'Central America';
      if (longitude > -80 && longitude < -40) return 'Caribbean';
      if (longitude > -40 && longitude < 0) return 'Atlantic Ocean';
      if (longitude > 0 && longitude < 40) return 'Africa';
      if (longitude > 40 && longitude < 80) return 'Indian Ocean';
      if (longitude > 80 && longitude < 120) return 'Southeast Asia';
      if (longitude > 120 && longitude < 180) return 'Pacific Ocean';
      return 'Tropical Region';
    }
    
    if (latitude > -20) {
      if (longitude > -180 && longitude < -120) return 'Pacific Ocean';
      if (longitude > -120 && longitude < -80) return 'South America';
      if (longitude > -80 && longitude < -40) return 'South America';
      if (longitude > -40 && longitude < 0) return 'South Atlantic';
      if (longitude > 0 && longitude < 40) return 'Southern Africa';
      if (longitude > 40 && longitude < 80) return 'Indian Ocean';
      if (longitude > 80 && longitude < 120) return 'Australia';
      if (longitude > 120 && longitude < 180) return 'Pacific Ocean';
      return 'Subtropical Region';
    }
    
    if (latitude > -40) {
      if (longitude > -180 && longitude < -120) return 'Pacific Ocean';
      if (longitude > -120 && longitude < -80) return 'Southern South America';
      if (longitude > -80 && longitude < -40) return 'Southern South America';
      if (longitude > -40 && longitude < 0) return 'South Atlantic';
      if (longitude > 0 && longitude < 40) return 'Southern Africa';
      if (longitude > 40 && longitude < 80) return 'Indian Ocean';
      if (longitude > 80 && longitude < 120) return 'Southern Australia';
      if (longitude > 120 && longitude < 180) return 'Pacific Ocean';
      return 'Southern Region';
    }
    
    return 'Antarctic Region';
  }

  String _getTimeOfDay() {
    try {
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
