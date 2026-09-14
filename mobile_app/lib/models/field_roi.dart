import 'dart:ui';

class FieldROI {
  final List<Offset> points; // 4 puntos normalizados [0.0 - 1.0]

  FieldROI({required this.points});

  factory FieldROI.defaultCourt() {
    return FieldROI(points: [
      const Offset(0.05, 0.15), // Esquina superior izquierda
      const Offset(0.95, 0.15), // Esquina superior derecha
      const Offset(0.98, 0.95), // Esquina inferior derecha
      const Offset(0.02, 0.95), // Esquina inferior izquierda
    ]);
  }

  List<Map<String, double>> toJsonList() {
    return points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList();
  }

  factory FieldROI.fromJsonList(List<dynamic> jsonList) {
    List<Offset> pts = jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return Offset(
        (map['dx'] as num).toDouble(),
        (map['dy'] as num).toDouble(),
      );
    }).toList();
    return FieldROI(points: pts);
  }
}
