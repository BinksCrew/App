import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binkscrew',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      themeMode: ThemeMode.light,
      home: UpgradeAlert(
        child: const WelcomeScreen(),
      ),
    );
  }
}
