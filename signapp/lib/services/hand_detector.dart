import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class HandDetector {
  final Uri serverUri;
  final Duration timeout;

  HandDetector({String serverUrl = 'http://127.0.0.1:5000/detect', this.timeout = const Duration(seconds: 6)})
      : serverUri = Uri.parse(serverUrl);

  /// Convert CameraImage -> JPEG bytes suitable for POSTing to the server.
  Future<Uint8List> cameraImageToJpeg(CameraImage image, {int targetW = 640, int targetH = 480, int quality = 85}) async {
    // Convert camera image to package:image Image
    img.Image imgSrc;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      final bytes = image.planes[0].bytes;
      imgSrc = img.Image.fromBytes(image.width, image.height, bytes, format: img.Format.bgra);
    } else {
      // YUV420 conversion (Android)
      final width = image.width;
      final height = image.height;
      final imgRgb = img.Image(width, height);
      final y = image.planes[0].bytes;
      final u = image.planes[1].bytes;
      final v = image.planes[2].bytes;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      int yp = 0;
      for (int j = 0; j < height; j++) {
        for (int i = 0; i < width; i++) {
          final uvIndex = uvPixelStride * (i >> 1) + uvRowStride * (j >> 1);
          final yv = y[yp];
          final uvU = u[uvIndex];
          final uvV = v[uvIndex];
          yp++;

          int r = (yv + (1.370705 * (uvV - 128))).round();
          int g = (yv - (0.337633 * (uvU - 128)) - (0.698001 * (uvV - 128))).round();
          int b = (yv + (1.732446 * (uvU - 128))).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          imgRgb.setPixelRgba(i, j, r, g, b);
        }
      }
      imgSrc = imgRgb;
    }

    final img.Image resized = img.copyResize(imgSrc, width: targetW, height: targetH);
    final List<int> jpg = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpg);
  }

  /// POST image bytes to the server and parse JSON response.
  /// Expected server response formats (supported):
  /// - List of hands: [ [ [x,y], [x,y], ... ], [ ... ] ]
  /// - Map with key 'hands': { "hands": [ [ [x,y], ... ], ... ] }
  Future<List<List<List<double>>>> detectHandsFromBytes(Uint8List imageBytes) async {
    try {
      final resp = await http
          .post(serverUri, headers: {'Content-Type': 'image/jpeg'}, body: imageBytes)
          .timeout(timeout);

      if (resp.statusCode != 200) {
        throw Exception('Server returned ${resp.statusCode}: ${resp.reasonPhrase}');
      }

      final dynamic decoded = jsonDecode(resp.body);

      // Normalize decoded to List<List<List<double>>>
      if (decoded == null) return [];

      List<List<List<double>>> hands = [];

      if (decoded is List) {
        // assume List of hands
        for (final hand in decoded) {
          if (hand is List) {
            final parsed = _parseHandList(hand);
            if (parsed.isNotEmpty) hands.add(parsed);
          }
        }
      } else if (decoded is Map && decoded.containsKey('hands')) {
        final dh = decoded['hands'];
        if (dh is List) {
          for (final hand in dh) {
            if (hand is List) {
              final parsed = _parseHandList(hand);
              if (parsed.isNotEmpty) hands.add(parsed);
            }
          }
        }
      } else {
        // Try to interpret as single hand list
        if (decoded is List) {
          final parsed = _parseHandList(decoded);
          if (parsed.isNotEmpty) hands.add(parsed);
        }
      }

      return hands;
    } catch (e) {
      // On error return empty list (caller should handle)
      return [];
    }
  }

  /// Convenience: convert CameraImage -> bytes -> send to server -> return first hand landmarks or [].
  Future<List<List<double>>> detectFirstHandFromCameraImage(CameraImage image,
      {int targetW = 640, int targetH = 480}) async {
    final bytes = await cameraImageToJpeg(image, targetW: targetW, targetH: targetH);
    final allHands = await detectHandsFromBytes(bytes);
    if (allHands.isNotEmpty) return allHands.first;
    return [];
  }

  /// Helper to parse a JSON hand entry into List<[x,y]> (ensures doubles).
  List<List<double>> _parseHandList(dynamic hand) {
    final List<List<double>> parsed = [];
    if (hand is! List) return parsed;
    for (final pt in hand) {
      if (pt is List && pt.length >= 2) {
        final dynamic x = pt[0];
        final dynamic y = pt[1];
        final double? xd = (x is num) ? x.toDouble() : double.tryParse(x.toString());
        final double? yd = (y is num) ? y.toDouble() : double.tryParse(y.toString());
        if (xd != null && yd != null) parsed.add([xd, yd]);
      }
    }
    return parsed;
  }

  void dispose() {
    // nothing to close for http client usage
  }
}