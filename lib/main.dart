import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'services/firebase_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        Provider(create: (_) => FirebaseService()),
      ],
      child: const SmartRacketApp(),
    ),
  );
}

class SmartRacketApp extends StatelessWidget {
  const SmartRacketApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Smart Racket',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    home: const HomeScreen(),
  );
}
}
