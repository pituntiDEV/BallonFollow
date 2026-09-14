import 'dart:ui';

class PolygonChecker {
  /// Retorna true si el punto [point] está dentro del polígono [polygon].
  /// Utiliza el algoritmo de Ray-Casting (prueba de rayos horizontal).
  static bool isPointInside(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return true; // Si no hay polígono válido, asumir dentro

    bool inside = false;
    final int n = polygon.length;
    double px = point.dx;
    double py = point.dy;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      double xi = polygon[i].dx;
      double yi = polygon[i].dy;
      double xj = polygon[j].dx;
      double yj = polygon[j].dy;

      bool intersect = ((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }
}
