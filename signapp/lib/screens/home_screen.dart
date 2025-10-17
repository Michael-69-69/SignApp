import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:typed_data';
import '../widgets/camera_view.dart';
import '../widgets/detected_sign.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/mediapipe_client.dart';

class SignLanguageHomePage extends StatefulWidget {
  final CameraDescription? camera;

  const SignLanguageHomePage({super.key, this.camera});

  @override
  State<SignLanguageHomePage> createState() => _SignLanguageHomePageState();
}

class _SignLanguageHomePageState extends State<SignLanguageHomePage> {
  late CameraController _cameraController;
  late MediaPipeClient _mediaPipeClient;
  String _detectedSign = "Initializing...";
  int _selectedIndex = 1;
  bool _isDetecting = false;
  bool _serverAvailable = false;
  List<List<double>> _landmarks = [];
  Timer? _inferenceTimer;

  @override
  void initState() {
    super.initState();
    _initializeMediaPipe();
    _initializeCamera();
  }

  Future<void> _initializeMediaPipe() async {
    _mediaPipeClient = MediaPipeClient();
    
    // Check if server is available
    final available = await _mediaPipeClient.isServerAvailable();
    setState(() {
      _serverAvailable = available;
      if (!available) {
        _detectedSign = "Server not available - Start Python server";
      }
    });
    
    print("MediaPipe server available: $available");
  }

  Future<void> _initializeCamera() async {
    if (widget.camera == null) {
      setState(() {
        _detectedSign = "No camera available";
      });
      return;
    }

    _cameraController = CameraController(
      widget.camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try {
      await _cameraController.initialize();
      if (!mounted) return;

      if (_serverAvailable) {
        // Start periodic inference
        _startInference();
        setState(() {
          _detectedSign = "Ready - show your hand";
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        _detectedSign = "Camera initialization failed";
      });
    }
  }

  void _startInference() {
    _inferenceTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (!_isDetecting && _serverAvailable && mounted) {
        _isDetecting = true;
        try {
          final image = await _cameraController.takePicture();
          final bytes = await image.readAsBytes();
          
          final landmarks = await _mediaPipeClient.detectHands(bytes);
          
          if (mounted) {
            setState(() {
              if (landmarks.isNotEmpty) {
                // Flatten landmarks for display (take first hand)
                _landmarks = landmarks[0];
                _detectedSign = "Hand detected";
              } else {
                _landmarks = [];
                _detectedSign = "No hand detected";
              }
            });
          }
        } catch (e) {
          print("Error running inference: $e");
        }
        _isDetecting = false;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _inferenceTimer?.cancel();
    _cameraController.dispose();
    _mediaPipeClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign Language Detector')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_detectedSign),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 30),
            onPressed: () {
              // TODO: Implement camera switching
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: CameraView(
              controller: _cameraController,
              landmarks: _landmarks,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DetectedSign(signText: _detectedSign),
                const SizedBox(height: 10),
                Text(
                  _serverAvailable ? "✓ Server connected" : "✗ Server not connected",
                  style: TextStyle(
                    color: _serverAvailable ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}