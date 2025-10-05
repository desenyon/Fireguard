import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants/palette.dart';
import '../../models/report_model.dart';

class ReportViewModel extends StateNotifier<ReportState> {
  ReportViewModel() : super(const ReportState());
  
  void setDescription(String v) => state = state.copyWith(description: v);
  
  void setSelectedLocation(LatLng location) => state = state.copyWith(selectedLocation: location);
  
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoadingLocation: true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      state = state.copyWith(
        currentLocation: currentLocation,
        selectedLocation: currentLocation,
        isLoadingLocation: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingLocation: false);
      rethrow;
    }
  }
  
  Future<void> submit() async {
    // TODO: Implement report submission
  }
}

final reportProvider = StateNotifierProvider<ReportViewModel, ReportState>((ref) => ReportViewModel());

class ReportView extends ConsumerWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(reportProvider);
    final controller = TextEditingController(text: s.description);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    // Default location (San Francisco) if no current location
    final initialLocation = s.currentLocation ?? const LatLng(37.7749, -122.4194);
    final mapController = MapController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Smoke'),
        backgroundColor: AppPalette.backgroundDarker,
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Stack(
        children: [
          // Flutter Map
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  ref.read(reportProvider.notifier).setSelectedLocation(point);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected location: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: AppPalette.white),
                      ),
                      backgroundColor: AppPalette.mediumGray,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fireguard',
                ),
                // Current location marker
                if (s.currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: s.currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                // Selected location marker
                if (s.selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: s.selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
    
          Positioned(
            right: 12,
            top: 80,
            child: Column(
              children: [
                _RoundControl(
                  onTap: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 1,
                  ),
                  child: const Icon(Icons.add, color: AppPalette.white),
                ),
                const SizedBox(height: 10),
                _RoundControl(
                  onTap: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 1,
                  ),
                  child: const Icon(Icons.remove, color: AppPalette.white),
                ),
                const SizedBox(height: 10),
                _RoundControl(
                  onTap: () async {
                    try {
                      await ref.read(reportProvider.notifier).getCurrentLocation();
                      if (s.currentLocation != null) {
                        mapController.move(s.currentLocation!, 15.0);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error getting location: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: s.isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppPalette.white),
                          ),
                        )
                      : const Icon(Icons.my_location, color: AppPalette.white),
                ),
              ],
            ),
          ),
          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppPalette.backgroundDarker,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () => ref.read(reportProvider.notifier).submit(),
                      child: const Text('Report Smoke Here', style: TextStyle(color: AppPalette.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppPalette.mediumGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: AppPalette.lightGrayLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: 1,
                            onChanged: (v) => ref.read(reportProvider.notifier).setDescription(v),
                            style: const TextStyle(color: AppPalette.white),
                            decoration: const InputDecoration(
                              hintText: 'Describe what you see (optional)',
                              hintStyle: TextStyle(color: AppPalette.placeholderText),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _RoundControl({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppPalette.mediumGray,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: Center(child: child),
      ),
    );
  }
}


