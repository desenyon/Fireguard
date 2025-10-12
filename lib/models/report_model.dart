
import 'package:latlong2/latlong.dart';
class ReportState {
  final String description;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final bool isLoadingLocation;
  final double? expectedRadius;
  
  const ReportState({
    this.description = '',
    this.currentLocation,
    this.selectedLocation,
    this.isLoadingLocation = false,
    this.expectedRadius,
  });
  
  ReportState copyWith({
    String? description,
    LatLng? currentLocation,
    LatLng? selectedLocation,
    bool? isLoadingLocation,
    double? expectedRadius,
  }) => ReportState(
    description: description ?? this.description,
    currentLocation: currentLocation ?? this.currentLocation,
    selectedLocation: selectedLocation ?? this.selectedLocation,
    isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    expectedRadius: expectedRadius ?? this.expectedRadius,
  );
}

