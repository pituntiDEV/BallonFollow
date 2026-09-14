import 'dart:math';

class PIDController {
  final double kp;
  final double ki;
  final double kd;
  final double deadband; // Margen en el que el motor no se mueve para evitar vibraciones

  double _integral = 0.0;
  double _prevError = 0.0;

  PIDController({
    this.kp = 2.0,
    this.ki = 0.03,
    this.kd = 0.2,
    this.deadband = 0.04,
  });

  void reset() {
    _integral = 0.0;
    _prevError = 0.0;
  }

  /// Calcula la salida de control normalizada [-1.0 a 1.0].
  /// [target]: Posición del balón (ej. 0.8 si está a la derecha).
  /// [current]: Centro deseado de la pantalla (normalmente 0.5).
  /// [dt]: Intervalo de tiempo en segundos.
  double compute({required double target, required double current, required double dt}) {
    double error = target - current;

    // Si el error está dentro de la zona muerta, apagar el motor
    if (error.abs() < deadband) {
      _integral = 0.0;
      _prevError = 0.0;
      return 0.0;
    }

    _integral += error * dt;
    // Anti-windup
    _integral = _integral.clamp(-0.5, 0.5);

    double derivative = (dt > 0) ? (error - _prevError) / dt : 0.0;
    _prevError = error;

    double output = (kp * error) + (ki * _integral) + (kd * derivative);

    // Limitar entre -1.0 y 1.0
    return output.clamp(-1.0, 1.0);
  }
}
