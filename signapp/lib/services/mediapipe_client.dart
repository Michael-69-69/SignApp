import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:typed_data';

class MediaPipeClient {
  final String serverUrl;
  final http.Client _httpClient;

  MediaPipeClient({
    this.serverUrl = 'http://localhost:5000',
  }) : _httpClient = http.Client();

  /// Check if server is reachable
  Future<bool> isServerAvailable() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$serverUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      print('Server check failed: $e');
      return false;
    }
  }

  /// Send image to server and get hand landmarks
  /// Returns list of hands, each containing list of landmarks [x, y, z, confidence]
  Future<List<List<List<double>>>> detectHands(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      
      final response = await _httpClient
          .post(
            Uri.parse('$serverUrl/detect'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['landmarks'] != null) {
          // Convert to List<List<List<double>>>
          final landmarks = (data['landmarks'] as List)
              .map((hand) => (hand as List)
                  .map((landmark) => (landmark as List)
                      .map((val) => (val as num).toDouble())
                      .toList())
                  .toList())
              .toList();
          return landmarks;
        }
      }
      print('Detection failed: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error detecting hands: $e');
      return [];
    }
  }

  /// Detect hand gestures
  /// Returns list of detected gestures with hand label and gesture type
  Future<List<Map<String, dynamic>>> detectGestures(
      Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      
      final response = await _httpClient
          .post(
            Uri.parse('$serverUrl/detect_gesture'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['gestures'] != null) {
          final gestures = List<Map<String, dynamic>>.from(data['gestures']);
          return gestures;
        }
      }
      print('Gesture detection failed: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error detecting gestures: $e');
      return [];
    }
  }

  void dispose() {
    _httpClient.close();
  }
}