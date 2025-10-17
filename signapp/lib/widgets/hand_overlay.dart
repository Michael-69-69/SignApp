import 'package:flutter/material.dart';

class HandOverlayPainter extends CustomPainter {
  final List<List<double>> landmarks; // normalized [x,y] in 0..1

  HandOverlayPainter(this.landmarks);

  static const List<List<int>> connections = [
    [0,1],[1,2],[2,3],[3,4],      // thumb
    [0,5],[5,6],[6,7],[7,8],      // index
    [0,9],[9,10],[10,11],[11,12], // middle
    [0,13],[13,14],[14,15],[15,16], // ring
    [0,17],[17,18],[18,19],[19,20], // pinky
    [5,9],[9,13],[13,17] // palm arches
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final paintLine = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final paintPoint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (final lm in landmarks) {
      final x = (lm[0] * size.width).clamp(0.0, size.width);
      final y = (lm[1] * size.height).clamp(0.0, size.height);
      points.add(Offset(x, y));
    }

    for (final c in connections) {
      if (c[0] < points.length && c[1] < points.length) {
        canvas.drawLine(points[c[0]], points[c[1]], paintLine);
      }
    }

    for (final p in points) {
      canvas.drawCircle(p, 8.0, paintPoint);
      canvas.drawCircle(p, 12.0, paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant HandOverlayPainter oldDelegate) => oldDelegate.landmarks != landmarks;
}