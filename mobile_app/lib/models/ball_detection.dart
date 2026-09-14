class BallDetection {
  final double x; // Coordenada X normalizada [0.0 - 1.0]
  final double y; // Coordenada Y normalizada [0.0 - 1.0]
  final double width;
  final double height;
  final double confidence;
  final bool isInsideCourt;

  BallDetection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    this.isInsideCourt = true,
  });

  double get centerX => x + (width / 2.0);
  double get centerY => y + (height / 2.0);

  BallDetection copyWith({bool? isInsideCourt}) {
    return BallDetection(
      x: x,
      y: y,
      width: width,
      height: height,
      confidence: confidence,
      isInsideCourt: isInsideCourt ?? this.isInsideCourt,
    );
  }
}
