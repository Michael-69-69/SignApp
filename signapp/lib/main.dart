import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:developer' as developer;
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CameraDescription? firstCamera;
  try {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) firstCamera = cameras.first;
  } catch (e, st) {
    developer.log('availableCameras failed: $e', error: e, stackTrace: st);
  }

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;
  const MyApp({Key? key, this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: camera != null
          ? SignLanguageHomePage(camera: camera!)
          : const Scaffold(
              body: Center(
                child: Text('No camera available'),
              ),
            ),
    );
  }
}