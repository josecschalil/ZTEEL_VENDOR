import 'package:flutter/material.dart';
import 'package:frontend/screens/splash_screen.dart';

void main() {
  runApp(const ZteeelApp());
}

class ZteeelApp extends StatelessWidget {
  const ZteeelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zteeel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE87722)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
