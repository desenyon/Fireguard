import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherData {
  final double windSpeed; // in m/s
  final double windDirection; // in degrees (0-360, where 0 is North)
  final double temperature; // in Celsius
  final double humidity; // percentage
  final double airQualityIndex; // AQI value
  final String windDirectionLabel; // e.g., "Northwest"
  final String airQualityDescription; // e.g., "Good", "Moderate", "Unhealthy"
  final DateTime timestamp;

  const WeatherData({
    required this.windSpeed,
    required this.windDirection,
    required this.temperature,
    required this.humidity,
    required this.airQualityIndex,
    required this.windDirectionLabel,
    required this.airQualityDescription,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final wind = json['wind'] ?? {};
    final main = json['main'] ?? {};
    final airQuality = json['air_quality'] ?? {};
    
    final windDirection = (wind['deg'] ?? 0).toDouble();
    final windSpeed = (wind['speed'] ?? 0).toDouble();
    final temperature = (main['temp'] ?? 0).toDouble();
    final humidity = (main['humidity'] ?? 0).toDouble();
    final aqi = (airQuality['us-epa-index'] ?? 1).toDouble();

    return WeatherData(
      windSpeed: windSpeed,
      windDirection: windDirection,
      temperature: temperature - 273.15, // Convert from Kelvin to Celsius
      humidity: humidity,
      airQualityIndex: aqi,
      windDirectionLabel: _degreesToCardinal(windDirection),
      airQualityDescription: _getAirQualityDescription(aqi),
      timestamp: DateTime.now(),
    );
  }

  static String _degreesToCardinal(double degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  static String _getAirQualityDescription(double aqi) {
    if (aqi <= 1) return 'Good';
    if (aqi <= 2) return 'Moderate';
    if (aqi <= 3) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 4) return 'Unhealthy';
    if (aqi <= 5) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // Calculate the direction to move for cleaner air
  double getSmokeFreeDirection() {
    // Smoke typically moves in the direction of the wind
    // To find cleaner air, we want to move opposite to the wind direction
    // or perpendicular to it
    return (windDirection + 180) % 360;
  }

  // Get the risk level based on wind and air quality
  String getRiskLevel() {
    if (airQualityIndex >= 4) return 'Highest Risk';
    if (airQualityIndex >= 3) return 'High Risk';
    if (airQualityIndex >= 2) return 'Moderate Risk';
    return 'Low Risk';
  }

  // Get guidance message for the user
  String getGuidanceMessage() {
    final smokeFreeDir = getSmokeFreeDirection();
    final cardinal = _degreesToCardinal(smokeFreeDir);
    
    if (airQualityIndex >= 4) {
      return 'Head $cardinal immediately for cleaner air. Air quality is $airQualityDescription.';
    } else if (airQualityIndex >= 3) {
      return 'Consider moving $cardinal for better air quality.';
    } else if (airQualityIndex >= 2) {
      return 'Air quality is $airQualityDescription. Monitor conditions.';
    } else {
      return 'Air quality is good. Stay alert for changes.';
    }
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static Future<WeatherData?> fetchWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        log('❌ OpenWeather API key not found in environment variables');
        return null;
      }

      // Fetch current weather data
      final weatherUrl = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey';
      log('🌤️ Weather API Request: $weatherUrl');
      
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      
      if (weatherResponse.statusCode == 200) {
        final weatherJson = json.decode(weatherResponse.body);
        
        // Try to fetch air quality data if available
        Map<String, dynamic> airQualityData = {};
        try {
          final airQualityUrl = '$_baseUrl/air_pollution?lat=$latitude&lon=$longitude&appid=$_apiKey';
          final airQualityResponse = await http.get(Uri.parse(airQualityUrl));
          
          if (airQualityResponse.statusCode == 200) {
            final airQualityJson = json.decode(airQualityResponse.body);
            airQualityData = airQualityJson['list']?[0] ?? {};
          }
        } catch (e) {
          log('⚠️ Could not fetch air quality data: $e');
        }

        // Merge weather and air quality data
        weatherJson['air_quality'] = airQualityData;
        
        log('✅ Successfully fetched weather data');
        return WeatherData.fromJson(weatherJson);
      } else {
        log('❌ Error fetching weather data: ${weatherResponse.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Exception occurred while fetching weather: $e');
      return null;
    }
  }

  // Fallback method using a free weather API if OpenWeather fails
  static Future<WeatherData?> fetchWeatherDataFallback({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Using wttr.in as a fallback (free, no API key required)
      final url = 'https://wttr.in/$latitude,$longitude?format=j1';
      log('🌤️ Fallback Weather API Request: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final current = json['current_condition']?[0] ?? {};
        final weather = current['weatherDesc']?[0] ?? {};
        
        // Extract wind data
        final windSpeed = double.tryParse(current['windspeedKmph'] ?? '0') ?? 0.0;
        final windDirection = double.tryParse(current['winddirDegree'] ?? '0') ?? 0.0;
        final temperature = double.tryParse(current['temp_C'] ?? '0') ?? 0.0;
        final humidity = double.tryParse(current['humidity'] ?? '0') ?? 0.0;
        
        // Create a basic WeatherData object
        return WeatherData(
          windSpeed: windSpeed / 3.6, // Convert km/h to m/s
          windDirection: windDirection,
          temperature: temperature,
          humidity: humidity,
          airQualityIndex: 2.0, // Default moderate air quality
          windDirectionLabel: WeatherData._degreesToCardinal(windDirection),
          airQualityDescription: 'Moderate',
          timestamp: DateTime.now(),
        );
      } else {
        log('❌ Error fetching fallback weather data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Exception occurred while fetching fallback weather: $e');
      return null;
    }
  }

  // Get weather data with fallback
  static Future<WeatherData?> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    // Try primary API first
    final weatherData = await fetchWeatherData(
      latitude: latitude,
      longitude: longitude,
    );
    
    if (weatherData != null) {
      return weatherData;
    }
    
    // Fallback to secondary API
    log('🔄 Trying fallback weather API...');
    return await fetchWeatherDataFallback(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
