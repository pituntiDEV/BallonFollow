import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field_roi.dart';
import '../widgets/field_roi_painter.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({Key? key}) : super(key: key);

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  List<Offset> points = FieldROI.defaultCourt().points;
  int? selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _loadSavedROI();
  }

  Future<void> _loadSavedROI() async {
    final prefs = await SharedPreferences.getInstance();
    final roiString = prefs.getString('saved_field_roi');
    if (roiString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(roiString);
        setState(() {
          points = FieldROI.fromJsonList(decoded).points;
        });
      } catch (e) {
        debugPrint("Error loading ROI: $e");
      }
    }
  }

  Future<void> _saveROI() async {
    final prefs = await SharedPreferences.getInstance();
    final roi = FieldROI(points: points);
    final jsonString = jsonEncode(roi.toJsonList());
    await prefs.setString('saved_field_roi', jsonString);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Calibración de cancha guardada correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, roi);
    }
  }

  void _resetToDefault() {
    setState(() {
      points = FieldROI.defaultCourt().points;
    });
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final touch = details.localPosition;
    int closestIndex = -1;
    double minDistance = 50.0; // Umbral táctil en píxeles

    for (int i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
      double distance = (touch - p).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    setState(() {
      selectedPointIndex = closestIndex != -1 ? closestIndex : null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (selectedPointIndex == null) return;

    final touch = details.localPosition;
    double normX = (touch.dx / size.width).clamp(0.0, 1.0);
    double normY = (touch.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      points[selectedPointIndex!] = Offset(normX, normY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      selectedPointIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Calibración de Cancha (ROI)"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Restablecer a valores por defecto",
            onPressed: _resetToDefault,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Guardar Calibración",
            onPressed: _saveROI,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // Fondo ilustrativo o feed de cámara
              Container(
                color: const Color(0xFF1E2D24),
                child: const Center(
                  child: Text(
                    "Arrastra los 4 puntos para enmarcar las líneas de la cancha",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Área interactiva de calibración
              GestureDetector(
                onPanStart: (details) => _onPanStart(details, size),
                onPanUpdate: (details) => _onPanUpdate(details, size),
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  size: size,
                  painter: FieldRoiPainter(
                    normalizedPoints: points,
                    selectedIndex: selectedPointIndex,
                    isInteractive: true,
                  ),
                ),
              ),

              // Barra inferior con instrucciones
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Los balones detectados fuera de esta área verde serán ignorados.",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _saveROI,
                        child: const Text("Listo", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
