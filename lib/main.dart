import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orangeWarm),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}