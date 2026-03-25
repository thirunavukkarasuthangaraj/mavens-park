import 'package:flutter/material.dart';
import '../api_service.dart';
import 'employee_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl     = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  String _error       = '';

  Future<void> _login() async {
    final name     = _nameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter name and password');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final result = await ApiService.login(name, password);
      if (result['success'] == true) {
        final role = result['role'];
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'admin'
                ? const AdminScreen()
                : EmployeeScreen(userName: result['name']),
          ),
        );
      } else {
        setState(() => _error = result['message'] ?? 'Login failed');
      }
    } catch (_) {
      setState(() => _error = 'Connection error. Check your internet.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_parking, size: 80, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text('Parking System',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
