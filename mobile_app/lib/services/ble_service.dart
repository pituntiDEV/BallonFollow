import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String targetDeviceName = "BallTracker-ESP32";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charRxUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> statusMessageNotifier = ValueNotifier<String>("Desconectado");

  bool get isConnected => isConnectedNotifier.value;

  /// Inicia escaneo de dispositivos BLE
  Stream<List<ScanResult>> scanDevices() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      androidUsesFineLocation: true,
    );
    return FlutterBluePlus.scanResults;
  }

  /// Detener escaneo
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Conectar a un dispositivo
  Future<bool> connect(BluetoothDevice device) async {
    try {
      statusMessageNotifier.value = "Conectando a ${device.platformName}...";
      await device.connect(timeout: const Duration(seconds: 6), autoConnect: false);
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == charRxUuid.toLowerCase()) {
              _rxCharacteristic = char;
              break;
            }
          }
        }
      }

      if (_rxCharacteristic != null) {
        isConnectedNotifier.value = true;
        statusMessageNotifier.value = "Conectado a ${device.platformName}";
        
        // Escuchar desconexión
        device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _handleDisconnect();
          }
        });
        return true;
      } else {
        statusMessageNotifier.value = "Servicio de seguimiento no encontrado";
        await device.disconnect();
        return false;
      }
    } catch (e) {
      debugPrint("[BLE Error] $e");
      statusMessageNotifier.value = "Error de conexión: $e";
      isConnectedNotifier.value = false;
      return false;
    }
  }

  void _handleDisconnect() {
    _connectedDevice = null;
    _rxCharacteristic = null;
    isConnectedNotifier.value = false;
    statusMessageNotifier.value = "Dispositivo desconectado";
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _handleDisconnect();
    }
  }

  /// Empaqueta y envía comando de velocidad de motor [-1.0 a 1.0] hacia el ESP32
  Future<void> sendMotorCommand({required double panSpeedNormalized, double tiltSpeedNormalized = 0.0}) async {
    if (_rxCharacteristic == null || !isConnected) return;

    List<int> packet = createPacket(panSpeedNormalized, tiltSpeedNormalized);

    try {
      await _rxCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      debugPrint("[BLE TX Error] $e");
    }
  }

  /// Construye el paquete de 6 bytes:
  /// [0xAA, panDir, panSpeed, tiltDir, tiltSpeed, checksum]
  static List<int> createPacket(double panSpeedNormalized, double tiltSpeedNormalized) {
    int panDir = panSpeedNormalized >= 0 ? 1 : 0;
    int panSpeed = (panSpeedNormalized.abs() * 255.0).round().clamp(0, 255);

    int tiltDir = tiltSpeedNormalized >= 0 ? 1 : 0;
    int tiltSpeed = (tiltSpeedNormalized.abs() * 255.0).round().clamp(0, 255);

    int header = 0xAA;
    int checksum = (header ^ panDir ^ panSpeed ^ tiltDir ^ tiltSpeed) & 0xFF;

    return [header, panDir, panSpeed, tiltDir, tiltSpeed, checksum];
  }
}
