import 'package:flutter/material.dart';
import '../models/ball_detection.dart';

class TrackingOverlay extends StatelessWidget {
  final BallDetection? detection;
  final Offset? kalmanSmoothedPosition;
  final double deadband;
  final double motorSpeed;

  const TrackingOverlay({
    Key? key,
    required this.detection,
    required this.kalmanSmoothedPosition,
    this.deadband = 0.04,
    this.motorSpeed = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        detection: detection,
        kalmanPosition: kalmanSmoothedPosition,
        deadband: deadband,
        motorSpeed: motorSpeed,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final BallDetection? detection;
  final Offset? kalmanPosition;
  final double deadband;
  final double motorSpeed;

  _OverlayPainter({
    required this.detection,
    required this.kalmanPosition,
    required this.deadband,
    required this.motorSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);

    // 1. Dibujar mira central (Crosshair)
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(center.dx - 20, center.dy), Offset(center.dx + 20, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx, center.dy + 20), crosshairPaint);

    // 2. Dibujar zona muerta (Deadband vertical lines)
    final deadbandWidth = size.width * deadband;
    final deadbandPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: deadbandWidth * 2, height: size.height * 0.8),
      deadbandPaint,
    );

    // 3. Dibujar detección del balón
    if (detection != null) {
      final rect = Rect.fromLTWH(
        detection!.x * size.width,
        detection!.y * size.height,
        detection!.width * size.width,
        detection!.height * size.height,
      );

      final boxColor = detection!.isInsideCourt ? Colors.greenAccent : Colors.orangeAccent;

      final boxPaint = Paint()
        ..color = boxColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), boxPaint);

      // Etiqueta de texto
      final textSpan = TextSpan(
        text: detection!.isInsideCourt
            ? "BALÓN ${(detection!.confidence * 100).toInt()}%"
            : "FUERA DE CANCHA",
        style: TextStyle(
          color: boxColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black87,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, (rect.top - 18).clamp(0.0, size.height)));
    }

    // 4. Dibujar posición suavizada de Kalman (Punto cian)
    if (kalmanPosition != null) {
      final kPos = Offset(kalmanPosition!.dx * size.width, kalmanPosition!.dy * size.height);
      final dotPaint = Paint()..color = Colors.cyanAccent;
      canvas.drawCircle(kPos, 5.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return true;
  }
}
