import 'services/firms_service.dart';

/// Test file to demonstrate FIRMS service usage
/// Run this file to see fire coordinates in the console
void main() async {
  print('🚀 Starting FIRMS Service Test');
  print('=' * 50);
  
  // Test 1: Fetch most recent global fire data
  print('\n📡 Test 1: Fetching most recent global fire data...');
  await FIRMSService.fetchLatestGlobalFireData();
  
  // Test 2: Fetch fire data for a specific date (if you want to test with a specific date)
  // Uncomment the line below and replace with a valid date
  // print('\n📡 Test 2: Fetching fire data for specific date...');
  // await FIRMSService.fetchFireDataForDate('2025-01-15');
  
  // Test 3: Fetch fire data for a specific area (e.g., California)
  print('\n📡 Test 3: Fetching fire data for California area...');
  await FIRMSService.fetchFireDataForArea(
    west: -124.5,  // Western boundary of California
    south: 32.5,   // Southern boundary of California
    east: -114.0,  // Eastern boundary of California
    north: 42.0,   // Northern boundary of California
  );
  
  print('\n✅ FIRMS Service Test Complete');
}




