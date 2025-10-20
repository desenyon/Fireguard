import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants/palette.dart';
import '../../services/firms_service.dart';
import '../../models/fire_hotspot.dart';
import '../../services/evacuation_routing_service.dart';
import '../../services/user_presence_service.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../menu/menu_view.dart';
import 'dart:math';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  List<FireHotspot> fireHotspots = [];
  bool isLoading = false;
  bool showAllAnomalies = false; 
  int _activeRequestId = 0; 
  bool _disposed = false;   
  
  // Location-related variables
  LatLng? userLocation;
  bool isLocationLoading = false;
  MapController mapController = MapController();
  List<LatLng> _evacuationRoute = [];
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadFireData();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    _safeSetState(() {
      isLocationLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        _safeSetState(() {
          isLocationLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          _safeSetState(() {
            isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        _safeSetState(() {
          isLocationLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      _safeSetState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        isLocationLoading = false;
      });

      // Move map to user location
      if (userLocation != null) {
        mapController.move(userLocation!, 12.0);
      }

      print('📍 User location: ${position.latitude}, ${position.longitude}');

      // Save presence with FCM token and geohash
      try {
        final uid = ref.read(currentUserProvider).value?.uid;
        if (uid != null) {
          await UserPresenceService.instance.requestPermissions();
          await UserPresenceService.instance.savePresence(
            uid: uid,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (e) {
     
      }

    } catch (e) {
      print('Error getting location: $e');
      if (!mounted) return;
      _safeSetState(() {
        isLocationLoading = false;
      });
    }
  }

  Future<void> _loadFireData() async {
    if (!mounted) return;

    final int requestId = ++_activeRequestId; 
    _safeSetState(() {
      isLoading = true;
    });

    try {
      final hotspots = showAllAnomalies
          ? await FIRMSService.fetchAllThermalAnomalies()
          : await FIRMSService.fetchLatestGlobalFireData();

      if (!mounted || _disposed || requestId != _activeRequestId) return;

    _safeSetState(() {
        fireHotspots = hotspots;
        isLoading = false;
      });
      print('🗺️ Loaded ${hotspots.length} fire hotspots on map (request $requestId)');

      // Proximity alerts are now handled by backend push notifications.
    } catch (e) {
      print('Error loading fire data: $e');
      if (!mounted || _disposed || requestId != _activeRequestId) return;
      _safeSetState(() {
        isLoading = false;
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _disposed) return;
  
    super.setState(fn);
  }

  bool _postDisposeSetStateWarned = false;
  @override
  void setState(VoidCallback fn) {
    if (_disposed || !mounted) {
      if (!_postDisposeSetStateWarned) {
        _postDisposeSetStateWarned = true;
        
        final stackLines = StackTrace.current.toString().split('\n');
        final interesting = stackLines.take(8).join('\n');
        // ignore: avoid_print
        print('[MapView] Ignored setState after dispose. First occurrence. Stack snippet:\n$interesting');
      }
      return; 
    }
    super.setState(fn);
  }

  @override
  void dispose() {
    _disposed = true; 
    _activeRequestId++; 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.screenBackground,
      body: Stack(
        children: [
          // Flutter Map
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: userLocation ?? const LatLng(20.0, 0.0), // Use user location or world view
                initialZoom: userLocation != null ? 12.0 : 3.0,
                minZoom: 2.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fireguard',
                ),
                if (_evacuationRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _evacuationRoute,
                        color: Colors.cyanAccent,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // User location marker
                    if (userLocation != null)
                      Marker(
                        point: userLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.7),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    // Fire hotspot markers
                    ...fireHotspots.map((hotspot) => Marker(
                      point: LatLng(hotspot.latitude, hotspot.longitude),
                      width: _getMarkerSize(hotspot.frp),
                      height: _getMarkerSize(hotspot.frp),
                      child: GestureDetector(
                        onTap: () => _showFireDetails(hotspot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getFireColorFromHotspot(hotspot),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _getFireColorFromHotspot(hotspot).withOpacity(0.7),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: _getMarkerSize(hotspot.frp) * 0.6,
                          ),
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ],
            ),
          ),
          
          // Menu button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton(
                mini: true,
                heroTag: null,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MenuView(),
                    ),
                  );
                },
                backgroundColor: AppPalette.backgroundDarker.withOpacity(0.8),
                child: const Icon(Icons.menu, color: AppPalette.white, size: 20),
              ),
            ),
          ),
          
          // Top search pill with fire count
          // Positioned(
          //   top: 16,
          //   left: 80,
          //   right: 16,
          //   child: SafeArea(
          //     bottom: false,
          //     child: Column(
          //       children: [
          //         Container(
          //           height: 40,
          //           width: double.infinity,
          //           constraints: const BoxConstraints(maxWidth: 320),
          //           decoration: BoxDecoration(
          //             color: Colors.white.withOpacity(0.25),
          //             borderRadius: BorderRadius.circular(20),
          //           ),
          //           padding: const EdgeInsets.symmetric(horizontal: 16),
          //           child: Row(
          //             children: [
          //               const Icon(Icons.search, color: Colors.white70, size: 20),
          //               const SizedBox(width: 8),
          //               Expanded(
          //                 child: Text(
          //                   showAllAnomalies ? 'All Thermal Anomalies' : 'Real Fires Only',
          //                   style: const TextStyle(
          //                     color: Colors.white,
          //                     fontSize: 14,
          //                     fontWeight: FontWeight.w600,
          //                   ),
          //                   overflow: TextOverflow.ellipsis,
          //                 ),
          //               ),
          //               // if (fireHotspots.isNotEmpty)
          //                 // Container(
          //                 //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //                 //   decoration: BoxDecoration(
          //                 //     color: AppPalette.orange,
          //                 //     borderRadius: BorderRadius.circular(12),
          //                 //   ),
          //                 //   child: Text(
          //                 //     '${fireHotspots.length}',
          //                 //     style: const TextStyle(
          //                 //       color: Colors.white,
          //                 //       fontSize: 12,
          //                 //       fontWeight: FontWeight.bold,
          //                 //     ),
          //                 //   ),
          //                 // ),
          //             ],
          //           ),
          //         ),
          //         const SizedBox(height: 8),
          //       ],
          //     ),
          //   ),
          // ),
          
          // Refresh button
          Positioned(
            top: 120,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton(
                mini: true,
                heroTag: null,
                onPressed: _loadFireData,
                backgroundColor: AppPalette.orange,
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ),
          
          // My Location button
          if (userLocation != null)
            Positioned(
              top: 170,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: FloatingActionButton(
                  mini: true,
                heroTag: null,
                  onPressed: () {
                    mapController.move(userLocation!, 12.0);
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                ),
              ),
            ),

          // Evacuate button
          if (userLocation != null)
            Positioned(
              top: 220,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: FloatingActionButton(
                  mini: false,
                heroTag: null,
                  onPressed: _isRouting ? null : _computeAndDrawEvacuation,
                  backgroundColor: Colors.green,
                  child: _isRouting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.directions_walk, color: Colors.white, size: 22),
                ),
              ),
            ),
          
     
      
      
          
        
          if (isLoading || isLocationLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppPalette.orange),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLocationLoading ? 'Getting your location...' : 'Loading fire data...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  



  double _getMarkerSize(double frp) {
    if (frp > 50.0) return 32.0;
    if (frp > 20.0) return 26.0;
    if (frp > 10.0) return 22.0;
    return 18.0;
  }

  Color _getFireColorFromHotspot(FireHotspot hotspot) {
    if (hotspot.frp > 50.0) return Colors.red;
    if (hotspot.frp > 20.0) return Colors.orange;
    if (hotspot.frp > 10.0) return Colors.yellow;
    return Colors.green;
  }

  void _showFireDetails(FireHotspot hotspot) async {
    // Calculate distance from user location
    double? distanceFromUser;
    if (userLocation != null) {
      distanceFromUser = _calculateDistance(
        userLocation!.latitude,
        userLocation!.longitude,
        hotspot.latitude,
        hotspot.longitude,
      );
    }

    // Calculate evacuation direction
    String evacuationDirection = _calculateEvacuationDirection(hotspot);

    // Calculate risk assessment
    String riskLevel = _calculateRiskAssessment(hotspot, distanceFromUser);

    // Get fire name asynchronously
    final fireName = await hotspot.fireName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🔥 Fire Details'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getFireColorFromHotspot(hotspot),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hotspot.intensityLevel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('🔥 Fire Name', fireName),
              _buildDetailRow('📍 Coordinates', 
                  '${hotspot.latitude.toStringAsFixed(4)}, ${hotspot.longitude.toStringAsFixed(4)}'),
              _buildDetailRow('🔥 Fire Size', _getFireSizeDescription(hotspot.frp)),
              _buildDetailRow('📅 Detected On', _formatDate(hotspot.acqDate)),
              
              // Enhanced information
              if (distanceFromUser != null) ...[
                const Divider(height: 20),
                _buildDetailRow('📏 Distance from You', '${distanceFromUser.toStringAsFixed(1)} km'),
              ],
              _buildDetailRow('🚨 Safety Level', _getUserFriendlyRiskLevel(riskLevel)),
              _buildDetailRow('🏃 Safe Direction', 'Head $evacuationDirection'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Calculate evacuation direction from fire hotspot
  String _calculateEvacuationDirection(FireHotspot hotspot) {
    if (userLocation == null) return 'Unknown (no location)';
    
    double deltaLat = userLocation!.latitude - hotspot.latitude;
    double deltaLon = userLocation!.longitude - hotspot.longitude;
    
    // Calculate bearing angle
    double bearing = (atan2(deltaLon, deltaLat) * 180 / 3.14159265359 + 360) % 360;
    
    // Convert to compass direction
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'Northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'Southeast';
    if (bearing >= 157.5 && bearing < 202.5) return 'South';
    if (bearing >= 202.5 && bearing < 247.5) return 'Southwest';
    if (bearing >= 247.5 && bearing < 292.5) return 'West';
    if (bearing >= 292.5 && bearing < 337.5) return 'Northwest';
    
    return 'Unknown';
  }

  // Calculate risk assessment based on confidence, intensity, and distance
  String _calculateRiskAssessment(FireHotspot hotspot, double? distanceFromUser) {
    int riskScore = 0;
    
    // Confidence scoring
    switch (hotspot.confidence.toLowerCase()) {
      case 'high':
        riskScore += 3;
        break;
      case 'nominal':
        riskScore += 2;
        break;
      case 'low':
        riskScore += 1;
        break;
    }
    
    // Intensity scoring (based on FRP)
    if (hotspot.frp > 50.0) riskScore += 3;
    else if (hotspot.frp > 20.0) riskScore += 2;
    else if (hotspot.frp > 10.0) riskScore += 1;
    
    // Distance scoring (closer = higher risk)
    if (distanceFromUser != null) {
      if (distanceFromUser < 5.0) riskScore += 3;
      else if (distanceFromUser < 15.0) riskScore += 2;
      else if (distanceFromUser < 30.0) riskScore += 1;
    }
    
    // Determine risk level
    if (riskScore >= 7) return '🔴 Critical';
    if (riskScore >= 5) return '🟠 High';
    if (riskScore >= 3) return '🟡 Moderate';
    return '🟢 Low';
  }

  Future<void> _computeAndDrawEvacuation() async {
    if (userLocation == null) return;
    if (fireHotspots.isEmpty) return;
    _safeSetState(() {
      _isRouting = true;
    });

    try {
      final LatLng safeTarget = EvacuationRoutingService.computeSafeTarget(
        user: userLocation!,
        hotspots: fireHotspots,
        moveAwayKm: 3.0,
      );

      final List<LatLng> route = await EvacuationRoutingService.getWalkingRoute(
        start: userLocation!,
        end: safeTarget,
      );

      if (!_disposed && mounted) {
        _safeSetState(() {
          _evacuationRoute = route;
          _isRouting = false;
        });
        if (route.isNotEmpty) {
          mapController.fitCamera(CameraFit.coordinates(
            padding: const EdgeInsets.all(24),
            coordinates: route,
          ));
        }
      }
    } catch (e) {
      if (!_disposed && mounted) {
        _safeSetState(() {
          _isRouting = false;
        });
      }
    }
  }

  // Helper methods to convert technical data to user-friendly descriptions
  String _getFireSizeDescription(double frp) {
    if (frp > 50.0) return 'Very Large Fire (High Danger)';
    if (frp > 20.0) return 'Large Fire (Moderate Danger)';
    if (frp > 10.0) return 'Medium Fire (Low Danger)';
    return 'Small Fire (Minimal Danger)';
  }


  String _formatDate(String dateStr) {
    try {
      // Assuming date format is YYYY-MM-DD
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day/$month/$year';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }


  String _getUserFriendlyRiskLevel(String riskLevel) {
    switch (riskLevel) {
      case '🔴 Critical':
        return '🔴 EXTREME DANGER - Evacuate immediately!';
      case '🟠 High':
        return '🟠 HIGH DANGER - Prepare to evacuate';
      case '🟡 Moderate':
        return '🟡 MODERATE DANGER - Stay alert';
      case '🟢 Low':
        return '🟢 LOW DANGER - Monitor situation';
      default:
        return riskLevel;
    }
  }
}