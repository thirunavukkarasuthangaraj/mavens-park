import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/employee_screen.dart';
import 'screens/admin_screen.dart';
import 'theme.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() => runApp(const ParkingApp());

class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mavens-i Parking',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const SplashRouter(),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs   = await SharedPreferences.getInstance();
    final role    = prefs.getString('role');
    final name    = prefs.getString('name');
    final empCode = prefs.getString('emp_code') ?? '';

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminScreen()));
    } else if (role == 'employee' && name != null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => EmployeeScreen(
            userName: name, empCode: empCode)));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A2744),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
