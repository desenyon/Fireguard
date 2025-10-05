import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants/palette.dart';
import '../../services/firms_service.dart';
import '../../models/fire_hotspot.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  List<FireHotspot> fireHotspots = [];
  bool isLoading = false;
  bool showAllAnomalies = false; 
  int _activeRequestId = 0; // Tracks the latest data fetch to ignore stale responses
  bool _disposed = false;   // Extra defensive flag (mounted is usually enough)
  
  // Location-related variables
  LatLng? userLocation;
  bool isLocationLoading = false;
  MapController mapController = MapController();

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

    final int requestId = ++_activeRequestId; // mark this invocation
    _safeSetState(() {
      isLoading = true;
    });

    try {
      final hotspots = showAllAnomalies
          ? await FIRMSService.fetchAllThermalAnomalies()
          : await FIRMSService.fetchLatestGlobalFireData();

      // If another, newer request started meanwhile or widget disposed, ignore
      if (!mounted || _disposed || requestId != _activeRequestId) return;

    _safeSetState(() {
        fireHotspots = hotspots;
        isLoading = false;
      });
      print('🗺️ Loaded ${hotspots.length} fire hotspots on map (request $requestId)');
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
    // Use super.setState to avoid recursive guard if we override setState
    super.setState(fn);
  }

  // Extra defensive override: if any external code holds a reference to this State
  // and calls setState after dispose, we silently ignore and log once.
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
      return; // ignore silently after first log
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
          
          // Top search pill with fire count
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 40,
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            showAllAnomalies ? 'All Thermal Anomalies' : 'Real Fires Only',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (fireHotspots.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppPalette.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${fireHotspots.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter toggle
                  // Container(
                  //   height: 36,
                  //   decoration: BoxDecoration(
                  //     color: Colors.black.withOpacity(0.5),
                  //     borderRadius: BorderRadius.circular(18),
                  //   ),
                  //   padding: const EdgeInsets.all(4),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       _buildFilterButton('Real Fires', !showAllAnomalies, () {
                  //         setState(() {
                  //           showAllAnomalies = false;
                  //         });
                  //         _loadFireData();
                  //       }),
                  //       const SizedBox(width: 4),
                  //       _buildFilterButton('All', showAllAnomalies, () {
                  //         setState(() {
                  //           showAllAnomalies = true;
                  //         });
                  //         _loadFireData();
                  //       }),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          
          // Refresh button
          Positioned(
            top: 120,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton(
                mini: true,
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
                  onPressed: () {
                    mapController.move(userLocation!, 12.0);
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                ),
              ),
            ),
          
          // Legend
          // Positioned(
          //   bottom: 80,
          //   right: 16,
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.7),
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const Text(
          //           'Fire Intensity',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //             fontSize: 12,
          //           ),
          //         ),
          //         const SizedBox(height: 8),
          //         _buildLegendItem(Colors.red, 'Extreme (>50 MW)'),
          //         _buildLegendItem(Colors.orange, 'High (20-50 MW)'),
          //         _buildLegendItem(Colors.yellow, 'Medium (10-20 MW)'),
          //         _buildLegendItem(Colors.green, 'Low (<10 MW)'),
          //       ],
          //     ),
          //   ),
          // ),
          
          // Bottom center action
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  height: 44,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          
          // Loading indicator
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

  Widget _buildFilterButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppPalette.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
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

  void _showFireDetails(FireHotspot hotspot) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('📍 Location', 
                '${hotspot.latitude.toStringAsFixed(4)}, ${hotspot.longitude.toStringAsFixed(4)}'),
            _buildDetailRow('🔥 Fire Radiative Power', '${hotspot.frp.toStringAsFixed(2)} MW'),
            _buildDetailRow('🌡️ Brightness Temp', '${hotspot.brightness.toStringAsFixed(1)} K'),
            _buildDetailRow('✅ Confidence', hotspot.confidence.toUpperCase()),
            _buildDetailRow('📅 Date', hotspot.acqDate),
            _buildDetailRow('🕐 Time', hotspot.acqTime),
            _buildDetailRow('🛰️ Satellite', hotspot.satellite),
            _buildDetailRow('🌙 Day/Night', hotspot.dayNight),
          ],
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
}