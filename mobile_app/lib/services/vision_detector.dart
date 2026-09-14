import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/ball_detection.dart';
import '../vision/polygon_checker.dart';

class VisionDetector {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  // Dimensiones estándar de entrada de YOLOv8
  static const int inputSize = 640;
  static const double minConfidenceThreshold = 0.35;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // Opciones de aceleración por hardware
      // options.addDelegate(GpuDelegateV2()); o CoreMLDelegate() en iOS
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ball_detector.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();
      _isModelLoaded = true;
      debugPrint("[VisionDetector] Modelo YOLO TFLite cargado correctamente.");
    } catch (e) {
      debugPrint("[VisionDetector] Error cargando modelo: $e");
      _isModelLoaded = false;
    }
  }

  /// Procesa los bytes de imagen RGB preprocesados y retorna la mejor detección de balón.
  BallDetection? detectBall({
    required List<List<List<double>>> inputTensor,
    required List<Offset> courtPolygon,
  }) {
    if (!_isModelLoaded || _interpreter == null) return null;

    // Supongamos formato de salida estándar YOLOv8: [1, 5, 8400] o [1, 8400, 5] (x, y, w, h, conf)
    var outputTensor = List.filled(1 * 5 * 8400, 0.0).reshape([1, 5, 8400]);

    try {
      _interpreter!.run(inputTensor, outputTensor);

      double bestConf = 0.0;
      double bestX = 0.0;
      double bestY = 0.0;
      double bestW = 0.0;
      double bestH = 0.0;

      // Iterar sobre las 8400 cajas candidatas
      for (int i = 0; i < 8400; i++) {
        double conf = outputTensor[0][4][i];
        if (conf > minConfidenceThreshold && conf > bestConf) {
          bestConf = conf;
          bestX = outputTensor[0][0][i] / inputSize;
          bestY = outputTensor[0][1][i] / inputSize;
          bestW = outputTensor[0][2][i] / inputSize;
          bestH = outputTensor[0][3][i] / inputSize;
        }
      }

      if (bestConf >= minConfidenceThreshold) {
        double left = (bestX - bestW / 2.0).clamp(0.0, 1.0);
        double top = (bestY - bestH / 2.0).clamp(0.0, 1.0);

        Offset ballCenter = Offset(bestX, bestY);
        bool isInside = PolygonChecker.isPointInside(ballCenter, courtPolygon);

        return BallDetection(
          x: left,
          y: top,
          width: bestW,
          height: bestH,
          confidence: bestConf,
          isInsideCourt: isInside,
        );
      }
    } catch (e) {
      debugPrint("[VisionDetector Inferencia Error] $e");
    }

    return null;
  }

  void close() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
