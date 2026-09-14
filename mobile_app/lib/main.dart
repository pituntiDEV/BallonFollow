import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación en horizontal (Landscape) para campo de visión óptimo en partidos
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Solicitar permisos esenciales en inicio
  await [
    Permission.camera,
    Permission.microphone,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  runApp(const SoccerBallTrackerApp());
}

class SoccerBallTrackerApp extends StatelessWidget {
  const SoccerBallTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soccer Ball Tracker AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0D1310),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
