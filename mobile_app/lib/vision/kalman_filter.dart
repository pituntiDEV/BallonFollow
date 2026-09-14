import 'dart:ui';

class KalmanFilter2D {
  final double dt;
  final double processNoise;
  final double measurementNoise;

  double _x = 0.5;
  double _y = 0.5;
  double _vx = 0.0;
  double _vy = 0.0;

  double _pPos = 1.0;
  double _pVel = 1.0;
  bool _initialized = false;

  KalmanFilter2D({
    this.dt = 0.033,
    this.processNoise = 0.01,
    this.measurementNoise = 0.04,
  });

  bool get isInitialized => _initialized;
  Offset get currentPosition => Offset(_x, _y);
  Offset get currentVelocity => Offset(_vx, _vy);

  void reset() {
    _x = 0.5;
    _y = 0.5;
    _vx = 0.0;
    _vy = 0.0;
    _pPos = 1.0;
    _pVel = 1.0;
    _initialized = false;
  }

  /// Predicción de posición cuando se pierde la detección temporalmente (ej. oclusión por jugadores)
  Offset predict() {
    _x += _vx * dt;
    _y += _vy * dt;
    _pPos += processNoise;
    _pVel += processNoise * 2.0;

    // Limitar al rango visual [0.0, 1.0]
    _x = _x.clamp(0.0, 1.0);
    _y = _y.clamp(0.0, 1.0);

    return Offset(_x, _y);
  }

  /// Actualización y corrección de estado cuando se recibe una detección de IA
  Offset update(Offset measurement) {
    if (!_initialized) {
      _x = measurement.dx;
      _y = measurement.dy;
      _initialized = true;
      return measurement;
    }

    // Ganancias de Kalman
    double kPos = _pPos / (_pPos + measurementNoise);
    double kVel = _pVel / (_pVel + measurementNoise * 2.0);

    double errorX = measurement.dx - _x;
    double errorY = measurement.dy - _y;

    // Actualizar velocidades estimadas
    _vx += kVel * (errorX / dt - _vx);
    _vy += kVel * (errorY / dt - _vy);

    // Actualizar posiciones
    _x += kPos * errorX;
    _y += kPos * errorY;

    // Actualizar covarianzas de error
    _pPos = (1.0 - kPos) * _pPos;
    _pVel = (1.0 - kVel) * _pVel;

    return Offset(_x, _y);
  }
}
