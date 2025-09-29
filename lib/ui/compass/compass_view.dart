import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';

class CompassState {
  final double headingDegrees; // 0..360, 0 = North
  final String windFromLabel; // e.g., "Northwest"
  final String riskLabel; // e.g., "Highest Risk"
  final String guidance; // e.g., "Head Southeast for cleaner air."

  const CompassState({
    required this.headingDegrees,
    required this.windFromLabel,
    required this.riskLabel,
    required this.guidance,
  });

  CompassState copyWith({double? headingDegrees, String? windFromLabel, String? riskLabel, String? guidance}) =>
      CompassState(
        headingDegrees: headingDegrees ?? this.headingDegrees,
        windFromLabel: windFromLabel ?? this.windFromLabel,
        riskLabel: riskLabel ?? this.riskLabel,
        guidance: guidance ?? this.guidance,
      );
}

class CompassViewModel extends StateNotifier<CompassState> {
  CompassViewModel()
      : super(const CompassState(
          headingDegrees: 315, // NW as default
          windFromLabel: 'Northwest',
          riskLabel: 'Highest Risk',
          guidance: 'Head Southeast for cleaner air.',
        ));

  // Call this from real sensors later
  void updateHeading(double degrees, {String? windFrom, String? risk, String? tip}) {
    state = state.copyWith(
      headingDegrees: degrees % 360,
      windFromLabel: windFrom,
      riskLabel: risk,
      guidance: tip,
    );
  }
}

final compassProvider = StateNotifierProvider<CompassViewModel, CompassState>((ref) => CompassViewModel());

class CompassView extends ConsumerWidget {
  const CompassView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(compassProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoke Compass'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.settings, color: AppPalette.white),
          ),
        ],
        backgroundColor: AppPalette.backgroundDarker,
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _CompassGauge(heading: s.headingDegrees, riskLabel: s.riskLabel),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
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
  const _CompassGauge({required this.heading, required this.riskLabel});

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
            painter: _GaugePainter(),
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
            ],
          ),
          // Cardinal letters
          Positioned(top: 18, child: const _Cardinal('N')),
          Positioned(bottom: 18, child: const _Cardinal('S')),
          Positioned(left: 18, child: const _Cardinal('W')),
          Positioned(right: 18, child: const _Cardinal('E')),
        ],
      ),
    );
  }

  static String _toCardinal(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((deg % 360) / 45).round() % 8;
    return dirs[index];
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
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2.2;

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    // Left orange arc (risk)
    ringPaint.color = AppPalette.orange;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        degToRad(140), degToRad(80), false, ringPaint);

    // Right green arc (safe)
    ringPaint.color = AppPalette.green;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        degToRad(-40), degToRad(80), false, ringPaint);

    // Inner vignette circle
    final Paint inner = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFF2C2C2E), Color(0xFF121212)], stops: [0.4, 1.0])
          .createShader(Rect.fromCircle(center: center, radius: radius + 40));
    canvas.drawCircle(center, radius + 10, inner);
  }

  double degToRad(double deg) => deg * 3.1415926535 / 180.0;

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



