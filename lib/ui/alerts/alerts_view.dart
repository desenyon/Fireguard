import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants/palette.dart';
import '../../services/user_service.dart';
import '../../services/fire_alerts_service.dart';

class AlertItem {
  final String name;
  final String updatedAgo;
  final double kilometersAway;
  final String severity;
  final String id;

  const AlertItem({
    required this.name, 
    required this.updatedAgo, 
    required this.kilometersAway,
    required this.severity,
    required this.id,
  });

  factory AlertItem.fromFireAlert(FireAlert alert) {
    return AlertItem(
      name: alert.name,
      updatedAgo: alert.timeAgo,
      kilometersAway: alert.distanceKm,
      severity: alert.severity,
      id: alert.id,
    );
  }
}

class AlertsState {
  final List<AlertItem> alerts;
  final double radiusKilometers;
  final bool isLoading;
  final String? errorMessage;

  const AlertsState({
    required this.alerts, 
    required this.radiusKilometers,
    this.isLoading = false,
    this.errorMessage,
  });

  AlertsState copyWith({
    List<AlertItem>? alerts, 
    double? radiusKilometers,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AlertsState(
        alerts: alerts ?? this.alerts, 
        radiusKilometers: radiusKilometers ?? this.radiusKilometers,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class AlertsViewModel extends StateNotifier<AlertsState> {
  AlertsViewModel()
      : super(
          const AlertsState(
            alerts: <AlertItem>[],
            radiusKilometers: 16,
            isLoading: false,
          ),
        ) {
    _loadSavedRadius();
    _loadFireAlerts();
  }

  Future<void> _loadSavedRadius() async {
    try {
      final double? savedRadius = await UserService.getAlertRadius();
      if (savedRadius != null) {
        state = state.copyWith(radiusKilometers: savedRadius);
      }
    } catch (e) {
      // If loading fails, keep the default value
      debugPrint('Failed to load saved alert radius: $e');
    }
  }

  Future<void> updateRadius(double kilometers) async {
    state = state.copyWith(radiusKilometers: kilometers);
    try {
      await UserService.updateAlertRadius(kilometers);
      // Reload alerts with new radius
      _loadFireAlerts();
    } catch (e) {
      debugPrint('Failed to save alert radius: $e');
      // Optionally show a snackbar or handle the error
    }
  }

  Future<void> _loadFireAlerts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final fireAlerts = await FireAlertsService.getFireAlerts();
      final alertItems = fireAlerts.map((alert) => AlertItem.fromFireAlert(alert)).toList();
      
      state = state.copyWith(
        alerts: alertItems,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to load fire alerts: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load fire alerts. Please try again.',
      );
    }
  }

  Future<void> refreshAlerts() async {
    await FireAlertsService.refreshAlerts();
    await _loadFireAlerts();
  }
}

final alertsProvider = StateNotifierProvider<AlertsViewModel, AlertsState>((ref) => AlertsViewModel());

class AlertsView extends ConsumerWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlertsState s = ref.watch(alertsProvider);
    final viewModel = ref.read(alertsProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Alerts'),
        backgroundColor: AppPalette.backgroundDarker,
        actions: [
          IconButton(
            onPressed: s.isLoading ? null : () => viewModel.refreshAlerts(),
            icon: s.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: AppPalette.screenBackground,
      body: s.isLoading && s.alerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading fire alerts...', style: TextStyle(color: AppPalette.white)),
                ],
              ),
            )
          : s.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppPalette.orange, size: 48),
                      const SizedBox(height: 16),
                      Text(s.errorMessage!, style: const TextStyle(color: AppPalette.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.refreshAlerts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _SectionTitle('Nearby Fire Alerts'),
                    const SizedBox(height: 8),
                    if (s.alerts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppPalette.mediumGray,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_outline, color: AppPalette.green, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'No fire alerts in your area',
                              style: TextStyle(color: AppPalette.white, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You\'re safe! Check back later for updates.',
                              style: TextStyle(color: AppPalette.lightGrayLight, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ...s.alerts.map((a) => _AlertCard(item: a)),
                    const SizedBox(height: 20),
                    const _SectionTitle('Alert Radius'),
                    const SizedBox(height: 8),
                    _RadiusCard(
                      value: s.radiusKilometers,
                      onChanged: (v) => viewModel.updateRadius(v),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppPalette.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem item;
  const _AlertCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.mediumGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0x33FF6B00),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department, color: AppPalette.orange),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: AppPalette.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(item.severity).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.severity,
                        style: TextStyle(
                          color: _getSeverityColor(item.severity),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.updatedAgo,
                      style: const TextStyle(color: AppPalette.lightGrayLight, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.kilometersAway.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppPalette.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              const Text('away', style: TextStyle(color: AppPalette.lightGrayLight, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return AppPalette.lightGrayLight;
    }
  }
}

class _RadiusCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _RadiusCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.mediumGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Within', style: TextStyle(color: AppPalette.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${value.toStringAsFixed(0)} km', style: const TextStyle(color: AppPalette.orange, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3A3A3C),
              inactiveTrackColor: const Color(0xFF3A3A3C),
              thumbColor: AppPalette.orange,
              overlayColor: const Color(0x33FF6B00),
            ),
            child: Slider(
              min: 1,
              max: 80,
              value: value.clamp(1, 80),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}


