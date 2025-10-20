import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://api.bigdatacloud.net/data/reverse-geocode-client';
  
  // Cache to avoid repeated API calls for same coordinates
  static final Map<String, String> _cache = {};
  
  /// Get location name from coordinates using reverse geocoding
  static Future<String> getLocationName(double latitude, double longitude) async {
    // Create cache key with rounded coordinates to group nearby locations
    final String cacheKey = '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    try {
      final String url = '$_baseUrl?latitude=$latitude&longitude=$longitude&localityLanguage=en';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Extract location components
        final String? city = data['city'];
        final String? locality = data['locality'];
        final String? principalSubdivision = data['principalSubdivision'];
        final String? countryName = data['countryName'];
        
        // Build location name with priority: city > locality > principalSubdivision > countryName
        String locationName = '';
        
        if (city != null && city.isNotEmpty) {
          locationName = city;
        } else if (locality != null && locality.isNotEmpty) {
          locationName = locality;
        } else if (principalSubdivision != null && principalSubdivision.isNotEmpty) {
          locationName = principalSubdivision;
        } else if (countryName != null && countryName.isNotEmpty) {
          locationName = countryName;
        } else {
          locationName = 'Unknown Location';
        }
        
        // Add country if it's different from the main location
        if (countryName != null && 
            countryName.isNotEmpty && 
            !locationName.toLowerCase().contains(countryName.toLowerCase())) {
          locationName = '$locationName, $countryName';
        }
        
        // Cache the result
        _cache[cacheKey] = locationName;
        
        return locationName;
      } else {
        print('Geocoding API error: ${response.statusCode}');
        return _getFallbackLocationName(latitude, longitude);
      }
    } catch (e) {
      print('Geocoding error: $e');
      return _getFallbackLocationName(latitude, longitude);
    }
  }
  
  /// Fallback location name when geocoding fails
  static String _getFallbackLocationName(double latitude, double longitude) {
    // Simple fallback based on coordinates
    if (latitude > 60) {
      if (longitude > -180 && longitude < -60) return 'Arctic Canada';
      if (longitude > -60 && longitude < 0) return 'Arctic Europe';
      if (longitude > 0 && longitude < 180) return 'Arctic Russia';
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
  
  /// Clear the cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
  }
}
