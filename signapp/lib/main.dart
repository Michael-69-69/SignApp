import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import the camera package
import 'screens/home_screen.dart';

// Make main() async to use 'await'
Future<void> main() async {
  // 1. Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // 3. Get the first camera from the list (usually the laptop webcam).
  final firstCamera = cameras.first;

  // 4. Run the app and pass the camera to it.
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  // Receive the camera
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Pass the camera down to the home page
      home: SignLanguageHomePage(camera: camera),
    );
  }
}