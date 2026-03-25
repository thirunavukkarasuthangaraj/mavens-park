import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() => runApp(const ParkingApp());

class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mavens Park',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const LoginScreen(),
    );
  }
}
