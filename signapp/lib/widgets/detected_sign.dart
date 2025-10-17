import 'package:flutter/material.dart';

class DetectedSign extends StatelessWidget {
  final String signText;

  const DetectedSign({super.key, required this.signText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        signText,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}