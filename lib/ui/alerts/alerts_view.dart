import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';

import '../../services/user_service.dart';

class AlertItem {
  final String name;
  final String updatedAgo;
  final double milesAway;

  const AlertItem({required this.name, required this.updatedAgo, required this.milesAway});
}

class AlertsState {
  final List<AlertItem> alerts;
  final double radiusMiles;

  const AlertsState({required this.alerts, required this.radiusMiles});

  AlertsState copyWith({List<AlertItem>? alerts, double? radiusMiles}) =>
      AlertsState(alerts: alerts ?? this.alerts, radiusMiles: radiusMiles ?? this.radiusMiles);
}

class AlertsViewModel extends StateNotifier<AlertsState> {
  AlertsViewModel()
      : super(
          const AlertsState(
            alerts: <AlertItem>[
              AlertItem(name: 'Creek Fire', updatedAgo: 'Updated 2 hours ago', milesAway: 1.2),
              AlertItem(name: 'River Fire', updatedAgo: 'Updated 4 hours ago', milesAway: 5.8),
              AlertItem(name: 'Lake Fire', updatedAgo: 'Updated 6 hours ago', milesAway: 9.3),
            ],
            radiusMiles: 10,
          ),
        ) {
    _loadSavedRadius();
  }

  Future<void> _loadSavedRadius() async {
    try {
      final double? savedRadius = await UserService.getAlertRadius();
      if (savedRadius != null) {
        state = state.copyWith(radiusMiles: savedRadius);
      }
    } catch (e) {
      // If loading fails, keep the default value
      debugPrint('Failed to load saved alert radius: $e');
    }
  }

  Future<void> updateRadius(double miles) async {
    state = state.copyWith(radiusMiles: miles);
    try {
      await UserService.updateAlertRadius(miles);
    } catch (e) {
      debugPrint('Failed to save alert radius: $e');
      // Optionally show a snackbar or handle the error
    }
  }
}

final alertsProvider = StateNotifierProvider<AlertsViewModel, AlertsState>((ref) => AlertsViewModel());

class AlertsView extends ConsumerWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlertsState s = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: AppPalette.backgroundDarker,
      ),
      backgroundColor: AppPalette.screenBackground,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
         
          const _SectionTitle('Recent Alerts'),
          const SizedBox(height: 8),
          for (final a in s.alerts) _AlertCard(item: a),
          const SizedBox(height: 20),
          const _SectionTitle('Alert Radius'),
          const SizedBox(height: 8),
          _RadiusCard(
            value: s.radiusMiles,
            onChanged: (v) => ref.read(alertsProvider.notifier).updateRadius(v),
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
                Text(
                  item.updatedAgo,
                  style: const TextStyle(color: AppPalette.lightGrayLight, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.milesAway.toStringAsFixed(1)} mi',
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
              Text('${value.toStringAsFixed(0)} miles', style: const TextStyle(color: AppPalette.orange, fontSize: 14, fontWeight: FontWeight.w700)),
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
              max: 50,
              value: value.clamp(1, 50),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}


