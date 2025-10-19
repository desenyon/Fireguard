import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../utils/constants/palette.dart';
import '../../services/weather_service.dart';

class CompassState {
  final double headingDegrees; // 0..360, 0 = North
  final String windFromLabel; // e.g., "Northwest"
  final String riskLabel; // e.g., "Highest Risk"
  final String guidance; // e.g., "Head Southeast for cleaner air."
  final WeatherData? weatherData;
  final bool isLoadingWeather;
  final String? errorMessage;
  final double? smokeFreeDirection; // Direction to move for cleaner air
  final Position? currentPosition;

  const CompassState({
    required this.headingDegrees,
    required this.windFromLabel,
    required this.riskLabel,
    required this.guidance,
    this.weatherData,
    this.isLoadingWeather = false,
    this.errorMessage,
    this.smokeFreeDirection,
    this.currentPosition,
  });

  CompassState copyWith({
    double? headingDegrees,
    String? windFromLabel,
    String? riskLabel,
    String? guidance,
    WeatherData? weatherData,
    bool? isLoadingWeather,
    String? errorMessage,
    double? smokeFreeDirection,
    Position? currentPosition,
  }) =>
      CompassState(
        headingDegrees: headingDegrees ?? this.headingDegrees,
        windFromLabel: windFromLabel ?? this.windFromLabel,
        riskLabel: riskLabel ?? this.riskLabel,
        guidance: guidance ?? this.guidance,
        weatherData: weatherData ?? this.weatherData,
        isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
        errorMessage: errorMessage ?? this.errorMessage,
        smokeFreeDirection: smokeFreeDirection ?? this.smokeFreeDirection,
        currentPosition: currentPosition ?? this.currentPosition,
      );
}

class CompassViewModel extends StateNotifier<CompassState> {
  StreamSubscription? _compassSub;
  Timer? _weatherUpdateTimer;

  CompassViewModel()
      : super(const CompassState(
          headingDegrees: 315, 
          windFromLabel: 'Northwest',
          riskLabel: 'Highest Risk',
          guidance: 'Head Southeast for cleaner air.',
        )) {
    _startCompass();
    _requestLocationAndWeather();
    _startWeatherUpdates();
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final double? heading = event.heading;
      if (heading == null) return;
      updateHeading(heading);
    });
  }

  Future<void> _requestLocationAndWeather() async {
    try {
     
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            errorMessage: 'Location permission denied. Please enable location access.',
            isLoadingWeather: false,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          errorMessage: 'Location permission permanently denied. Please enable in settings.',
          isLoadingWeather: false,
        );
        return;
      }

      // Get current position
      state = state.copyWith(isLoadingWeather: true, errorMessage: null);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      state = state.copyWith(currentPosition: position);
      await _fetchWeatherData(position);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to get location: $e',
        isLoadingWeather: false,
      );
    }
  }

  Future<void> _fetchWeatherData(Position position) async {
    try {
      final weatherData = await WeatherService.getWeatherData(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (weatherData != null) {
        final smokeFreeDirection = weatherData.getSmokeFreeDirection();
        state = state.copyWith(
          weatherData: weatherData,
          windFromLabel: weatherData.windDirectionLabel,
          riskLabel: weatherData.getRiskLevel(),
          guidance: weatherData.getGuidanceMessage(),
          smokeFreeDirection: smokeFreeDirection,
          isLoadingWeather: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Unable to fetch weather data. Using default guidance.',
          isLoadingWeather: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Weather data error: $e',
        isLoadingWeather: false,
      );
    }
  }

  void _startWeatherUpdates() {
    // Update weather data every 5 minutes
    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state.currentPosition != null) {
        _fetchWeatherData(state.currentPosition!);
      }
    });
  }

  // Manual refresh method
  Future<void> refreshWeatherData() async {
    if (state.currentPosition != null) {
      await _fetchWeatherData(state.currentPosition!);
    } else {
      await _requestLocationAndWeather();
    }
  }

  // Can be used for external/manual updates if needed.
  void updateHeading(double degrees, {String? windFrom, String? risk, String? tip}) {
    state = state.copyWith(
      headingDegrees: degrees % 360,
      windFromLabel: windFrom,
      riskLabel: risk,
      guidance: tip,
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _weatherUpdateTimer?.cancel();
    super.dispose();
  }
}

final compassProvider = StateNotifierProvider<CompassViewModel, CompassState>((ref) => CompassViewModel());

class CompassView extends ConsumerWidget {
  const CompassView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(compassProvider);
    final viewModel = ref.read(compassProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoke Compass'),
        backgroundColor: AppPalette.backgroundDarker,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: s.isLoadingWeather ? null : () => viewModel.refreshWeatherData(),
            tooltip: 'Refresh weather data',
          ),
        ],
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Column(
        children: [
          const SizedBox(height: 16),
          
          // Loading indicator
          if (s.isLoadingWeather)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading weather data...',
                    style: TextStyle(color: AppPalette.lightGrayLight),
                  ),
                ],
              ),
            ),
          
          // Error message
          if (s.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppPalette.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.errorMessage!,
                      style: const TextStyle(color: AppPalette.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: Center(
              child: _CompassGauge(
                heading: s.headingDegrees,
                riskLabel: s.riskLabel,
                smokeFreeDirection: s.smokeFreeDirection,
                weatherData: s.weatherData,
                
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                if (s.weatherData != null) ...[
             
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.backgroundDarker.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeatherInfoItem(
                          icon: Icons.air,
                          label: 'Wind',
                          value: '${s.weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                        ),
                        _WeatherInfoItem(
                          icon: Icons.thermostat,
                          label: 'Temp',
                          value: '${s.weatherData!.temperature.toStringAsFixed(1)}°C',
                        ),
                        _WeatherInfoItem(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value: '${s.weatherData!.humidity.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: AppPalette.white, fontSize: 16, height: 1.4),
                    children: [
                      const TextSpan(text: 'Wind from '),
                      TextSpan(text: s.windFromLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' is carrying smoke.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.guidance,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppPalette.greenBright, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CompassGauge extends StatelessWidget {
  final double heading; // 0..360
  final String riskLabel;
  final double? smokeFreeDirection;
  final WeatherData? weatherData;
  
  const _CompassGauge({
    required this.heading,
    required this.riskLabel,
    this.smokeFreeDirection,
    this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.78;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadowed circle backdrop
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x33000000), blurRadius: 40, spreadRadius: 4),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              smokeFreeDirection: smokeFreeDirection,
              weatherData: weatherData,
            ),
          ),
          // Center reading
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TrianglePointer(angleDegrees: heading, size: size * 0.12),
              const SizedBox(height: 8),
              Text(_toCardinal(heading), style: const TextStyle(color: AppPalette.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(riskLabel, style: const TextStyle(color: AppPalette.lightGrayLight, fontSize: 13)),
              if (weatherData != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getAirQualityColor(weatherData!.airQualityIndex).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAirQualityColor(weatherData!.airQualityIndex),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    weatherData!.airQualityDescription,
                    style: TextStyle(
                      color: _getAirQualityColor(weatherData!.airQualityIndex),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Cardinal letters
          Positioned(top: 18, child: const _Cardinal('N')),
          Positioned(bottom: 18, child: const _Cardinal('S')),
          Positioned(left: 18, child: const _Cardinal('W')),
          Positioned(right: 18, child: const _Cardinal('E')),
          
          // Smoke-free direction indicator
          if (smokeFreeDirection != null)
            Positioned(
              child: _SmokeFreeIndicator(
                direction: smokeFreeDirection!,
                size: size,
              ),
            ),
          
          // Air quality directional labels
          if (weatherData != null) ...[
            // Good air quality label
            // Positioned(
            //   child: _AirQualityLabel(
            //     direction: (weatherData!.windDirection + 180) % 360,
            //     label: 'Good Air',
            //     color: AppPalette.green,
            //     size: size,
            //   ),
            // ),
            // // Bad air quality label
            // Positioned(
            //   child: _AirQualityLabel(
            //     direction: weatherData!.windDirection,
            //     label: 'Bad Air',
            //     color: AppPalette.red,
            //     size: size,
            //   ),
            // ),
          ],
        ],
      ),
    );
  }

  static String _toCardinal(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((deg % 360) / 45).round() % 8;
    return dirs[index];
  }

  static Color _getAirQualityColor(double aqi) {
    if (aqi <= 1) return AppPalette.green;
    if (aqi <= 2) return AppPalette.greenBright;
    if (aqi <= 3) return AppPalette.orange;
    if (aqi <= 4) return AppPalette.red;
    return AppPalette.red;
  }
}

class _Cardinal extends StatelessWidget {
  final String c;
  const _Cardinal(this.c);
  @override
  Widget build(BuildContext context) {
    return Text(c, style: const TextStyle(color: AppPalette.lightGrayLight, fontSize: 12));
  }
}

class _GaugePainter extends CustomPainter {
  final double? smokeFreeDirection;
  final WeatherData? weatherData;
  
  const _GaugePainter({
    this.smokeFreeDirection,
    this.weatherData,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2.2;

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round;

    // Dynamic air quality arcs based on wind direction and air quality
    if (weatherData != null) {
      _drawDynamicAirQualityArcs(canvas, center, radius, ringPaint);
    } else {
      // Default static arcs
      ringPaint.color = AppPalette.orange;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          degToRad(140), degToRad(80), false, ringPaint);

      ringPaint.color = AppPalette.green;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          degToRad(-40), degToRad(80), false, ringPaint);
    }

    // Smoke-free direction indicator
    if (smokeFreeDirection != null) {
      final smokeFreeRad = degToRad(smokeFreeDirection!);
      final smokeFreePaint = Paint()
        ..color = AppPalette.greenBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      
      // Draw arrow pointing to smoke-free direction
      final arrowLength = radius - 20;
      final arrowStart = Offset(
        center.dx + (arrowLength - 30) * math.cos(smokeFreeRad),
        center.dy + (arrowLength - 30) * math.sin(smokeFreeRad),
      );
      final arrowEnd = Offset(
        center.dx + arrowLength * math.cos(smokeFreeRad),
        center.dy + arrowLength * math.sin(smokeFreeRad),
      );
      
      canvas.drawLine(arrowStart, arrowEnd, smokeFreePaint);
      
      // Draw arrowhead
      final arrowHeadSize = 8.0;
      final arrowHead1 = Offset(
        arrowEnd.dx - arrowHeadSize * math.cos(smokeFreeRad - math.pi / 6),
        arrowEnd.dy - arrowHeadSize * math.sin(smokeFreeRad - math.pi / 6),
      );
      final arrowHead2 = Offset(
        arrowEnd.dx - arrowHeadSize * math.cos(smokeFreeRad + math.pi / 6),
        arrowEnd.dy - arrowHeadSize * math.sin(smokeFreeRad + math.pi / 6),
      );
      
      canvas.drawLine(arrowEnd, arrowHead1, smokeFreePaint);
      canvas.drawLine(arrowEnd, arrowHead2, smokeFreePaint);
    }

    // Inner vignette circle
    final Paint inner = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFF2C2C2E), Color(0xFF121212)], stops: [0.4, 1.0])
          .createShader(Rect.fromCircle(center: center, radius: radius + 40));
    canvas.drawCircle(center, radius + 10, inner);
  }

  void _drawDynamicAirQualityArcs(Canvas canvas, Offset center, double radius, Paint ringPaint) {
    final windDirection = weatherData!.windDirection;
    final airQualityIndex = weatherData!.airQualityIndex;
    
    // Calculate the direction where smoke is coming from (wind direction)
    final smokeDirection = windDirection;
    
    // Calculate the direction of good air quality (opposite to wind direction)
    final goodAirDirection = (smokeDirection + 180) % 360;
    
    // Determine arc sizes based on air quality
    double goodArcSize, badArcSize;
    Color goodColor, badColor;
    
    if (airQualityIndex <= 2) {
      // Good air quality - larger green arc
      goodArcSize = 120; // degrees
      badArcSize = 60;
      goodColor = AppPalette.green;
      badColor = AppPalette.orange;
    } else if (airQualityIndex <= 3) {
      // Moderate air quality - balanced arcs
      goodArcSize = 90;
      badArcSize = 90;
      goodColor = AppPalette.green;
      badColor = AppPalette.orange;
    } else {
      // Poor air quality - larger red arc
      goodArcSize = 60;
      badArcSize = 120;
      goodColor = AppPalette.green;
      badColor = AppPalette.red;
    }
    
    // Draw good air quality arc (green)
    ringPaint.color = goodColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degToRad(goodAirDirection - goodArcSize / 2),
      degToRad(goodArcSize),
      false,
      ringPaint,
    );
    
    // Draw bad air quality arc (red/orange)
    ringPaint.color = badColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degToRad(smokeDirection - badArcSize / 2),
      degToRad(badArcSize),
      false,
      ringPaint,
    );
    
    // Add red circle ring for very bad air quality
    if (airQualityIndex >= 4) {
      final Paint redRingPaint = Paint()
        ..color = AppPalette.red.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      
      // Draw red ring on the bad air quality side
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 15),
        degToRad(smokeDirection - badArcSize / 2),
        degToRad(badArcSize),
        false,
        redRingPaint,
      );
      
      // Add inner red ring for extra emphasis
      final Paint innerRedRingPaint = Paint()
        ..color = AppPalette.red.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        degToRad(smokeDirection - badArcSize / 2),
        degToRad(badArcSize),
        false,
        innerRedRingPaint,
      );
    }
    
    // Add green glow for good air quality
    if (airQualityIndex <= 2) {
      final Paint greenGlowPaint = Paint()
        ..color = AppPalette.green.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 10),
        degToRad(goodAirDirection - goodArcSize / 2),
        degToRad(goodArcSize),
        false,
        greenGlowPaint,
      );
    }
  }

  double degToRad(double deg) => deg * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglePointer extends StatelessWidget {
  final double angleDegrees;
  final double size;
  const _TrianglePointer({required this.angleDegrees, required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * 3.1415926535 / 180.0,
      child: CustomPaint(
        size: Size.square(size),
        painter: _TrianglePainter(),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path();
    p.moveTo(size.width / 2, 0);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();

    final Paint paint = Paint()
      ..color = AppPalette.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmokeFreeIndicator extends StatelessWidget {
  final double direction;
  final double size;
  
  const _SmokeFreeIndicator({
    required this.direction,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: direction * math.pi / 180.0,
      child: Container(
        width: size * 0.15,
        height: size * 0.15,
        decoration: BoxDecoration(
          color: AppPalette.greenBright.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.greenBright, width: 2),
        ),
        child: const Center(
          child: Icon(
            Icons.air,
            color: AppPalette.greenBright,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _WeatherInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _WeatherInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppPalette.lightGrayLight, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.lightGrayLight,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppPalette.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AirQualityLabel extends StatelessWidget {
  final double direction;
  final String label;
  final Color color;
  final double size;
  
  const _AirQualityLabel({
    required this.direction,
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.35;
    final x = radius * math.cos(direction * math.pi / 180.0);
    final y = radius * math.sin(direction * math.pi / 180.0);
    
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}



