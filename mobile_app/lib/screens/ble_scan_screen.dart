import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({Key? key}) : super(key: key);

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  final BleService _bleService = BleService();
  List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    _scanSubscription?.cancel();
    _scanSubscription = _bleService.scanDevices().listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bleService.stopScan();
    super.dispose();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _bleService.stopScan();
    bool success = await _bleService.connect(device);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Conectado exitosamente a ${device.platformName}"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No se pudo conectar al dispositivo ESP32"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Conectar a Soporte ESP32"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _bleService.stopScan : _startScan,
          )
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _bleService.statusMessageNotifier,
            builder: (context, msg, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.blueGrey.shade900,
                child: Text(
                  "Estado: $msg",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          if (_isScanning) const LinearProgressIndicator(color: Colors.greenAccent),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? "Buscando dispositivos Bluetooth..."
                          : "No se encontraron dispositivos.\nAsegúrate de que el ESP32 esté encendido.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final name = result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : "Dispositivo desconocido";
                      final isTracker = name.contains("BallTracker") || name.contains("ESP32");

                      return Card(
                        color: isTracker ? const Color(0xFF1F3A2B) : const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: isTracker ? Colors.greenAccent : Colors.grey,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isTracker ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            "${result.device.remoteId}  |  RSSI: ${result.rssi} dBm",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTracker ? Colors.green : Colors.blueGrey,
                            ),
                            onPressed: () => _connectToDevice(result.device),
                            child: const Text("Conectar", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
