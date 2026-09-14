import 'package:flutter/material.dart';

class FieldRoiPainter extends CustomPainter {
  final List<Offset> normalizedPoints;
  final int? selectedIndex;
  final bool isInteractive;

  FieldRoiPainter({
    required this.normalizedPoints,
    this.selectedIndex,
    this.isInteractive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.length < 3) return;

    List<Offset> screenPoints = normalizedPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // Relleno translúcido de la cancha
    final fillPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Línea de contorno
    final strokePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(screenPoints[0].dx, screenPoints[0].dy);
    for (int i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Dibujar vértices interactivos
    if (isInteractive) {
      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final handleStroke = Paint()
        ..color = Colors.green
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < screenPoints.length; i++) {
        final p = screenPoints[i];
        bool isSelected = (i == selectedIndex);
        double radius = isSelected ? 14.0 : 9.0;

        canvas.drawCircle(p, radius, handlePaint);
        canvas.drawCircle(p, radius, handleStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FieldRoiPainter oldDelegate) {
    return true;
  }
}
