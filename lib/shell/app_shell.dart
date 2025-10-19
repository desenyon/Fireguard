import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants/palette.dart';
import '../ui/alerts/alerts_view.dart';
import '../ui/compass/compass_view.dart';
import '../ui/map/map_view.dart';
import '../ui/report/report_view.dart';
import '../ui/ai/ai_companion_view.dart';

final bottomIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _tabs = <Widget>[
    MapView(),
    CompassView(),
    AlertsView(),
    ReportView(),
    AiCompanionView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(bottomIndexProvider);
    return Scaffold(
      body: _tabs[index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppPalette.navBarBackground),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => ref.read(bottomIndexProvider.notifier).state = i,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
              BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Compass'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Report'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
            ],
          ),
        ),
      ),
    );
  }
}


