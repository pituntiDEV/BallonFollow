import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import '../lib/vision/polygon_checker.dart';

void main() {
  group('PolygonChecker (Cancha ROI)', () {
    final courtPolygon = [
      const Offset(0.10, 0.20),
      const Offset(0.90, 0.20),
      const Offset(0.95, 0.90),
      const Offset(0.05, 0.90),
    ];

    test('Punto en el centro debe estar DENTRO de la cancha', () {
      const centerPoint = Offset(0.50, 0.50);
      expect(PolygonChecker.isPointInside(centerPoint, courtPolygon), isTrue);
    });

    test('Punto fuera de las bandas debe estar FUERA de la cancha', () {
      const outsidePoint = Offset(0.02, 0.05); // Fuera arriba-izquierda
      expect(PolygonChecker.isPointInside(outsidePoint, courtPolygon), isFalse);
    });

    test('Punto en gradas derechas debe estar FUERA de la cancha', () {
      const standsPoint = Offset(0.98, 0.50);
      expect(PolygonChecker.isPointInside(standsPoint, courtPolygon), isFalse);
    });
  });
}
