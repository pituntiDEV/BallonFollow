import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/ball_detection.dart';
import '../models/field_roi.dart';
import '../services/ble_service.dart';
import '../services/vision_detector.dart';
import '../vision/kalman_filter.dart';
import '../vision/pid_controller.dart';
import '../vision/polygon_checker.dart';
import '../widgets/tracking_overlay.dart';
import '../widgets/field_roi_painter.dart';

class TrackerScreen extends StatefulWidget {
  final FieldROI fieldRoi;

  const TrackerScreen({Key? key, required this.fieldRoi}) : super(key: key);

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final BleService _bleService = BleService();
  final VisionDetector _visionDetector = VisionDetector();
  final KalmanFilter2D _kalman = KalmanFilter2D(dt: 0.033);
  final PIDController _pid = PIDController(kp: 2.0, ki: 0.02, kd: 0.15, deadband: 0.04);

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isTrackingActive = true;
  bool _isRecording = false;

  BallDetection? _currentDetection;
  Offset? _kalmanSmoothedPosition;
  double _currentMotorSpeed = 0.0;
  int _fpsCounter = 0;
  Timer? _fpsTimer;

  // Contador de frames sin detección para predicción Kalman
  int _consecutiveLostFrames = 0;
  static const int maxPredictFrames = 15; // ~0.5s a 30fps

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    await _visionDetector.loadModel();
    await _initCamera();

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _fpsCounter = 0;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });

          // Iniciar procesamiento de imágenes en tiempo real
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint("[Camera Init Error] $e");
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;

    bool isProcessing = false;

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isTrackingActive || isProcessing) return;
      isProcessing = true;
      _fpsCounter++;

      try {
        // En una implementación de producción nativa, pasamos el puntero de bytes
        // o ejecutamos la inferencia con TFLite.
        // Aquí simulamos la detección del centro de balón con los filtros integrados
        _processFrameDetection();
      } finally {
        isProcessing = false;
      }
    });
  }

  void _processFrameDetection() {
    // Si tenemos detección válida
    if (_currentDetection != null) {
      final ballPoint = Offset(_currentDetection!.centerX, _currentDetection!.centerY);
      bool isInside = PolygonChecker.isPointInside(ballPoint, widget.fieldRoi.points);

      if (isInside) {
        _consecutiveLostFrames = 0;
        final smoothed = _kalman.update(ballPoint);

        // Calcular comando de control con PID respecto al centro (0.5)
        double motorCmd = _pid.compute(
          target: smoothed.dx,
          current: 0.5,
          dt: 0.033,
        );

        _currentMotorSpeed = motorCmd;
        _bleService.sendMotorCommand(panSpeedNormalized: motorCmd);

        setState(() {
          _kalmanSmoothedPosition = smoothed;
        });
      } else {
        // Balón fuera de la cancha: no mover el soporte
        _currentMotorSpeed = 0.0;
        _bleService.sendMotorCommand(panSpeedNormalized: 0.0);
      }
    } else {
      // Si no hay detección directa, usar predicción de Kalman durante oclusión
      if (_consecutiveLostFrames < maxPredictFrames && _kalman.isInitialized) {
        _consecutiveLostFrames++;
        final predicted = _kalman.predict();

        double motorCmd = _pid.compute(
          target: predicted.dx,
          current: 0.5,
          dt: 0.033,
        );

        _currentMotorSpeed = motorCmd;
        _bleService.sendMotorCommand(panSpeedNormalized: motorCmd);

        setState(() {
          _kalmanSmoothedPosition = predicted;
        });
      } else {
        // Demasiados frames perdidos: frenar motor suavemente
        _currentMotorSpeed = 0.0;
        _bleService.sendMotorCommand(panSpeedNormalized: 0.0);
        setState(() {
          _kalmanSmoothedPosition = null;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (_isRecording) {
      try {
        final file = await _cameraController!.stopVideoRecording();
        setState(() => _isRecording = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎬 Grabación guardada en: ${file.path}")),
          );
        }
      } catch (e) {
        debugPrint("Error deteniendo grabación: $e");
      }
    } else {
      try {
        await _cameraController!.startVideoRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        debugPrint("Error iniciando grabación: $e");
      }
    }
  }

  void _manualJog(double speed) {
    _bleService.sendMotorCommand(panSpeedNormalized: speed);
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _cameraController?.dispose();
    _visionDetector.close();
    _bleService.sendMotorCommand(panSpeedNormalized: 0.0); // Frenar motor al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Vista de Cámara
          if (_isCameraReady && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),

          // 2. Capa visual del contorno de la cancha
          CustomPaint(
            size: Size.infinite,
            painter: FieldRoiPainter(
              normalizedPoints: widget.fieldRoi.points,
              isInteractive: false,
            ),
          ),

          // 3. Capa de seguimiento (Bounding box, crosshair, deadband)
          TrackingOverlay(
            detection: _currentDetection,
            kalmanSmoothedPosition: _kalmanSmoothedPosition,
            deadband: _pid.deadband,
            motorSpeed: _currentMotorSpeed,
          ),

          // 4. Panel superior de Telemetría
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: _bleService.isConnected ? Colors.greenAccent : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _bleService.isConnected ? "ESP32 ONLINE" : "OFFLINE",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    "Motor: ${(_currentMotorSpeed * 100).toInt()}%",
                    style: TextStyle(
                      color: _currentMotorSpeed.abs() > 0.05 ? Colors.greenAccent : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (_isRecording)
                    Row(
                      children: const [
                        Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text("REC", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // 5. Botones de Control Inferiores
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Controles manuales (Jog)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _manualJog(-0.6),
                      onTapUp: (_) => _manualJog(0.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Botón de Grabación
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          color: _isRecording ? Colors.white : Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTapDown: (_) => _manualJog(0.6),
                      onTapUp: (_) => _manualJog(0.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Interruptor de modo automático
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text("Auto-Seguimiento IA", style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isTrackingActive,
                            activeColor: Colors.greenAccent,
                            onChanged: (val) {
                              setState(() => _isTrackingActive = val);
                              if (!val) _bleService.sendMotorCommand(panSpeedNormalized: 0.0);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
