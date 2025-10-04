
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FIRMSService {
  static const String _baseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area';
  static final String _mapKey = dotenv.env['MAP_API_KEY'] ?? '';
  
  /// Fetches fire data from NASA FIRMS API and displays coordinates in console
  /// 
  /// [source] - Data source (e.g., 'VIIRS_SNPP_NRT', 'MODIS_NRT', etc.)
  /// [area] - Area coordinates or 'world' for global data
  /// [dayRange] - Number of days to query (1-10)
  /// [date] - Optional date in YYYY-MM-DD format. If null, gets most recent data
  static Future<void> fetchFireData({
    String source = 'VIIRS_SNPP_NRT',
    String area = 'world',
    int dayRange = 1,
    String? date,
  }) async {
    try {
      // Build the API URL
      String url = '$_baseUrl/csv/$_mapKey/$source/$area/$dayRange';
      if (date != null) {
        url += '/$date';
      }
      
      print('🌍 FIRMS API Request: $url');
      
      // Make the HTTP request
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('✅ Successfully fetched fire data');
        print('📊 Response length: ${response.body.length} characters');
        
        // Parse and display the CSV data
        _parseAndDisplayFireData(response.body);
      } else {
        print('❌ Error fetching fire data: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
    }
  }
  
  /// Parses CSV data and displays fire coordinates
  static void _parseAndDisplayFireData(String csvData) {
    if (csvData.isEmpty) {
      print('📭 No fire data available for the specified parameters');
      return;
    }
    
    final lines = csvData.split('\n');
    if (lines.length < 2) {
      print('📭 No fire data found in response');
      return;
    }
    
    // Display header
    print('\n🔥 FIRE DETECTION DATA 🔥');
    print('=' * 50);
    print('Header: ${lines[0]}');
    print('=' * 50);
    
    // Parse and display fire coordinates
    int fireCount = 0;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final fields = line.split(',');
        if (fields.length >= 2) {
          fireCount++;
          final latitude = fields[0];
          final longitude = fields[1];
          
          // Display additional fields if available
          String additionalInfo = '';
          if (fields.length > 2) {
            additionalInfo = ' | Additional data: ${fields.skip(2).join(', ')}';
          }
          
          print('🔥 Fire #$fireCount: Lat: $latitude, Lon: $longitude$additionalInfo');
        }
      }
    }
    
    print('=' * 50);
    print('📈 Total fires detected: $fireCount');
    print('=' * 50);
  }
  
  /// Convenience method to fetch most recent global fire data
  static Future<void> fetchLatestGlobalFireData() {
    return fetchFireData();
  }
  
  /// Fetch fire data for a specific date
  static Future<void> fetchFireDataForDate(String date) {
    return fetchFireData(date: date);
  }
  
  /// Fetch fire data for a specific area with custom coordinates
  /// [west, south, east, north] - Bounding box coordinates
  static Future<void> fetchFireDataForArea({
    required double west,
    required double south,
    required double east,
    required double north,
    String source = 'VIIRS_SNPP_NRT',
    int dayRange = 1,
    String? date,
  }) {
    final area = '$west,$south,$east,$north';
    return fetchFireData(
      source: source,
      area: area,
      dayRange: dayRange,
      date: date,
    );
  }
}

