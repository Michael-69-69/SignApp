import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'landmark_painter.dart';

class CameraView extends StatelessWidget {
  final CameraController controller;
  final List<List<double>> landmarks;

  const CameraView({
    super.key,
    required this.controller,
    required this.landmarks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            CameraPreview(controller),
            CustomPaint(
              painter: LandmarkPainter(
                landmarks: landmarks,
                imageSize: Size(
                  controller.value.previewSize?.height ?? 640,
                  controller.value.previewSize?.width ?? 480,
                ),
              ),
              size: Size.infinite,
            ),
          ],
        ),
      ),
    );
  }
}