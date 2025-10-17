import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../widgets/camera_view.dart';
import '../widgets/detected_sign.dart';
import '../widgets/bottom_nav_bar.dart';

class SignLanguageHomePage extends StatefulWidget {
  // 1. Add a camera property to the widget
  final CameraDescription camera;

  const SignLanguageHomePage({super.key, required this.camera});

  @override
  State<SignLanguageHomePage> createState() => _SignLanguageHomePageState();
}

class _SignLanguageHomePageState extends State<SignLanguageHomePage> {
  // Use 'late' because it will be initialized in initState
  late CameraController _cameraController;
  Interpreter? _handLandmarksInterpreter;
  Interpreter? _gestureClassifierInterpreter;
  String _detectedSign = "Thank you";
  int _selectedIndex = 1;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModels();
  }

  Future<void> _initializeCamera() async {
    // 2. Use the camera passed from the widget
    _cameraController = CameraController(widget.camera, ResolutionPreset.medium);
    
    try {
      await _cameraController.initialize();
      if (!mounted) return;

      _cameraController.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _runModel(image);
        }
      });

    } catch (e) {
      print("Error initializing camera: $e");
    }

    // 3. Update the UI to show the camera feed
    setState(() {});
  }

  Future<void> _loadModels() async {
    try {
      _handLandmarksInterpreter =
          await Interpreter.fromAsset('hand_landmarks_detector.tflite');
      _gestureClassifierInterpreter =
          await Interpreter.fromAsset('canned_gesture_classifier.tflite');
      print("Models loaded successfully");
    } catch (e) {
      print("Failed to load models: $e");
    }
  }

  Future<void> _runModel(CameraImage image) async {
    // TODO: Implement the model inference logic here.
    
    await Future.delayed(const Duration(milliseconds: 100));

    _isDetecting = false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _handLandmarksInterpreter?.close();
    _gestureClassifierInterpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. Check if the controller is initialized before building the preview
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
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
            child: CameraView(controller: _cameraController),
          ),
          Expanded(
            flex: 2,
            child: DetectedSign(signText: _detectedSign),
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