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
  final String type; // 'satellite' or 'user_report'
  final String? reporterEmail;

  const AlertItem({
    required this.name, 
    required this.updatedAgo, 
    required this.kilometersAway,
    required this.severity,
    required this.id,
    required this.type,
    this.reporterEmail,
  });

  factory AlertItem.fromFireAlert(FireAlert alert) {
    return AlertItem(
      name: alert.name,
      updatedAgo: alert.timeAgo,
      kilometersAway: alert.distanceKm,
      severity: alert.severity,
      id: alert.id,
      type: alert.type,
      reporterEmail: alert.reporterEmail,
    );
  }
}

class AlertsState {
  final List<AlertItem> alerts;
  final double radiusMiles;
  final bool isLoading;
  final String? errorMessage;

  const AlertsState({
    required this.alerts, 
    required this.radiusMiles,
    this.isLoading = false,
    this.errorMessage,
  });

  AlertsState copyWith({
    List<AlertItem>? alerts, 
    double? radiusMiles,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AlertsState(
        alerts: alerts ?? this.alerts, 
        radiusMiles: radiusMiles ?? this.radiusMiles,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class AlertsViewModel extends StateNotifier<AlertsState> {
  AlertsViewModel()
      : super(
          const AlertsState(
            alerts: <AlertItem>[],
            radiusMiles: 10, // Default 10 miles
            isLoading: false,
          ),
        ) {
    _loadSavedRadius();
    _loadFireAlerts();
  }

  Future<void> _loadSavedRadius() async {
    try {
      final double? savedRadiusKm = await UserService.getAlertRadius();
      if (savedRadiusKm != null) {
        // Convert saved kilometers to miles
        final double radiusMiles = savedRadiusKm * 0.621371;
        state = state.copyWith(radiusMiles: radiusMiles);
      }
    } catch (e) {
      // If loading fails, keep the default value
      debugPrint('Failed to load saved alert radius: $e');
    }
  }

  Future<void> updateRadius(double miles) async {
    state = state.copyWith(radiusMiles: miles);
    try {
      // Convert miles to kilometers for storage
      final double radiusKm = miles * 1.60934;
      await UserService.updateAlertRadius(radiusKm);
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
                    const _SectionTitle('Fire Alerts & Community Reports'),
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
                              'No fire alerts or community reports in your area',
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
                      value: s.radiusMiles,
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
        border: item.type == 'user_report' 
            ? Border.all(color: AppPalette.orange.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.type == 'user_report' 
                  ? const Color(0x33FF6B00)
                  : const Color(0x33FF6B00),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                item.type == 'user_report' 
                    ? Icons.people 
                    : Icons.satellite_alt,
                color: item.type == 'user_report' 
                    ? AppPalette.orange 
                    : AppPalette.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(color: AppPalette.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.type == 'user_report')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppPalette.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMMUNITY',
                          style: TextStyle(
                            color: AppPalette.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
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
                    if (item.type == 'user_report' && item.reporterEmail != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'by ${item.reporterEmail!.split('@')[0]}',
                        style: const TextStyle(color: AppPalette.lightGrayLight, fontSize: 12),
                      ),
                    ],
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

class _RadiusCard extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _RadiusCard({required this.value, required this.onChanged});

  @override
  State<_RadiusCard> createState() => _RadiusCardState();
}

class _RadiusCardState extends State<_RadiusCard> {
  late double _tempValue;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.value;
  }

  @override
  void didUpdateWidget(_RadiusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _tempValue = widget.value;
      _hasUnsavedChanges = false;
    }
  }

  void _onSliderChanged(double newValue) {
    setState(() {
      _tempValue = newValue;
      _hasUnsavedChanges = _tempValue != widget.value;
    });
  }

  void _onSave() {
    widget.onChanged(_tempValue);
    setState(() {
      _hasUnsavedChanges = false;
    });
  }

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
              Text('${_tempValue.toStringAsFixed(0)} mi', style: const TextStyle(color: AppPalette.orange, fontSize: 14, fontWeight: FontWeight.w700)),
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
              max: 50, // 50 miles max (roughly 80 km)
              value: _tempValue.clamp(1, 50),
              onChanged: _onSliderChanged,
            ),
          ),
          if (_hasUnsavedChanges) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: AppPalette.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save & Update Alerts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


