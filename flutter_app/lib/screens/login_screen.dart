import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/hash.dart';
import 'employee_screen.dart';
import 'admin_screen.dart';
import 'force_change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl     = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;
  String _error       = '';

  Future<void> _login() async {
    final code     = _codeCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (code.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter employee code and password');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final result = await ApiService.login(code, password);

      if (result['success'] == true) {
        final role       = result['role'];
        final mustChange = result['must_change'] == true;

        if (!mounted) return;

        if (role == 'admin') {
          // Admin never gets forced password change
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          );
        } else if (mustChange) {
          // Employee must set a new password before continuing
          // Pass the already-hashed password so ForceChange can verify it
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ForceChangePasswordScreen(
                userName:              result['name'],
                currentHashedPassword: hashPassword(password),
              ),
            ),
          );
        } else {
          // Normal employee login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeScreen(userName: result['name']),
            ),
          );
        }
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
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo)),
              const SizedBox(height: 32),

              // Employee Code
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Employee Code',
                  hintText: 'e.g. 101',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error,
                          style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),

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
