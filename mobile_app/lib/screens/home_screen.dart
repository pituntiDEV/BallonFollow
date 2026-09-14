import 'package:flutter/material.dart';
import '../models/field_roi.dart';
import '../services/ble_service.dart';
import 'ble_scan_screen.dart';
import 'calibration_screen.dart';
import 'tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  FieldROI _currentRoi = FieldROI.defaultCourt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1310),
      appBar: AppBar(
        title: const Text("Soccer Ball Tracker AI"),
        backgroundColor: const Color(0xFF141F1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: "Escanear ESP32",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BleScanScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Estado BLE
            ValueListenableBuilder<bool>(
              valueListenable: _bleService.isConnectedNotifier,
              builder: (context, isConnected, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFF163824) : const Color(0xFF381F1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? Colors.greenAccent : Colors.redAccent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected ? "Soporte ESP32 Conectado" : "Soporte ESP32 Desconectado",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              isConnected
                                  ? "Listo para transmitir movimientos en tiempo real"
                                  : "Toca aquí para escanear y conectar por Bluetooth",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (!isConnected)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BleScanScreen()),
                            );
                          },
                          child: const Text("Conectar", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Tarjeta Principal: Iniciar Seguimiento
            Card(
              color: const Color(0xFF1C2C23),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackerScreen(fieldRoi: _currentRoi),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Colors.greenAccent, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Iniciar Grabación & Seguimiento",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Abre la cámara con IA activa para seguir el balón automáticamente dentro de la cancha.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón de Calibración de Cancha
            Card(
              color: const Color(0xFF18221D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.crop_free, color: Colors.amberAccent, size: 30),
                title: const Text(
                  "Calibrar Cancha de Fútbol",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Delimita las 4 esquinas visibles para ignorar balones fuera del terreno.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () async {
                  final result = await Navigator.push<FieldROI>(
                    context,
                    MaterialPageRoute(builder: (_) => const CalibrationScreen()),
                  );
                  if (result != null) {
                    setState(() {
                      _currentRoi = result;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // Tarjeta de Guía Rápida
            Card(
              color: const Color(0xFF141A17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "💡 Pasos recomendados:",
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1. Coloca el trípode a mitad de cancha en una posición elevada.\n"
                      "2. Enciende el ESP32 y conéctate por Bluetooth desde la app.\n"
                      "3. Abre 'Calibrar Cancha' y ajusta los 4 puntos a las líneas del campo.\n"
                      "4. Pulsa 'Iniciar Grabación' para que el soporte centre el balón.",
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
