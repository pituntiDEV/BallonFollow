import 'package:flutter_test/flutter_test.dart';
import '../lib/vision/pid_controller.dart';
import '../lib/services/ble_service.dart';

void main() {
  group('PIDController & Deadband', () {
    test('Error dentro de la zona muerta debe producir velocidad 0.0', () {
      final pid = PIDController(deadband: 0.05);
      // El centro es 0.5, si el balón está en 0.52 (error = 0.02 < 0.05)
      double output = pid.compute(target: 0.52, current: 0.50, dt: 0.033);
      expect(output, equals(0.0));
    });

    test('Balón a la derecha debe producir comando positivo (giro a la derecha)', () {
      final pid = PIDController(kp: 2.0, deadband: 0.03);
      double output = pid.compute(target: 0.80, current: 0.50, dt: 0.033);
      expect(output, greaterThan(0.0));
      expect(output, lessThanOrEqualTo(1.0));
    });

    test('Balón a la izquierda debe producir comando negativo (giro a la izquierda)', () {
      final pid = PIDController(kp: 2.0, deadband: 0.03);
      double output = pid.compute(target: 0.20, current: 0.50, dt: 0.033);
      expect(output, lessThan(0.0));
      expect(output, greaterThanOrEqualTo(-1.0));
    });
  });

  group('BLE Packet Creation Protocol', () {
    test('Paquete binario hacia ESP32 debe tener 6 bytes y checksum válido', () {
      final packet = BleService.createPacket(0.75, 0.0);
      expect(packet.length, equals(6));
      expect(packet[0], equals(0xAA)); // Header
      expect(packet[1], equals(1));    // Dirección Pan = 1 (derecha)
      expect(packet[2], equals((0.75 * 255).round())); // Velocidad ~191

      // Verificar Checksum XOR
      int expectedCs = (packet[0] ^ packet[1] ^ packet[2] ^ packet[3] ^ packet[4]) & 0xFF;
      expect(packet[5], equals(expectedCs));
    });
  });
}
