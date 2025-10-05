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
      confidence: fields[8].toLowerCase(), // low, nominal, high
      version: fields[9],
      brightT31: double.tryParse(fields[10]) ?? 0.0,
      frp: double.tryParse(fields[11]) ?? 0.0,
      dayNight: fields[12],
    );
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

  @override
  String toString() {
    return 'FireHotspot(lat: $latitude, lon: $longitude, confidence: $confidence, FRP: ${frp.toStringAsFixed(2)} MW, intensity: $intensityLevel)';
  }
}