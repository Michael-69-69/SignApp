import 'package:flutter/material.dart';

class LandmarkPainter extends CustomPainter {
  final List<List<double>> landmarks;
  final Size imageSize;

  // Hand landmark connections (MediaPipe format)
  static const List<List<int>> connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index finger
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle finger
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Ring finger
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Pinky finger
    [0, 17], [17, 18], [18, 19], [19, 20],
  ];

  LandmarkPainter({
    required this.landmarks,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    // Draw connections (lines)
    for (final connection in connections) {
      final startIdx = connection[0];
      final endIdx = connection[1];

      if (startIdx < landmarks.length && endIdx < landmarks.length) {
        final start = landmarks[startIdx];
        final end = landmarks[endIdx];

        final startX = start[0] * scaleX;
        final startY = start[1] * scaleY;
        final endX = end[0] * scaleX;
        final endY = end[1] * scaleY;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }
    }

    // Draw circles (joints)
    for (final landmark in landmarks) {
      final x = landmark[0] * scaleX;
      final y = landmark[1] * scaleY;

      canvas.drawCircle(
        Offset(x, y),
        6,
        circlePaint,
      );

      // Draw green border around circles
      canvas.drawCircle(
        Offset(x, y),
        8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LandmarkPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}