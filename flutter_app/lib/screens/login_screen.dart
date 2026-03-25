import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../utils/hash.dart';
import '../utils/toast.dart';
import '../theme.dart';
import 'employee_screen.dart';
import 'admin_screen.dart';
import 'force_change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    final code = _codeCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (code.isEmpty || password.isEmpty) {
      showError('Please enter employee code and password');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.login(code, password);
    setState(() => _loading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      final role = result['role'];
      final mustChange = result['must_change'] == true;
      final name = result['name'] ?? '';
      final empCode = result['emp_code'] ?? '';

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role);
      await prefs.setString('name', name);
      await prefs.setString('emp_code', empCode);

      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else if (mustChange) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ForceChangePasswordScreen(
                      userName: name,
                      currentHashedPassword: hashPassword(password),
                    )));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => EmployeeScreen(
                      userName: name,
                      empCode: empCode,
                    )));
      }
    } else {
      showError(result['message'] ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Navy header (matches website hero) ─────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 40),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo circle
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.orange.withOpacity(0.6), width: 2),
                      ),
                      child: const Icon(Icons.local_parking,
                          size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mavens-i Parking',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    // Orange badge — like their orange banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Mavens-i Softech Solution Pvt Ltd',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Login form ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign In',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    const Text('Enter your employee code and password',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textGrey)),
                    const SizedBox(height: 28),

                    // Employee Code field
                    TextField(
                      controller: _codeCtrl,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        TextInputFormatter.withFunction((old, new_) =>
                            new_.copyWith(text: new_.text.toUpperCase())),
                      ],
                      decoration: _inputDecoration(
                        label: 'Employee Code',
                        hint: 'M0123',
                        icon: Icons.badge_outlined,
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      maxLength: 10,
                      inputFormatters: [LengthLimitingTextInputFormatter(10)],
                      onSubmitted: (_) => _login(),
                      decoration: _inputDecoration(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 28),

                    // Sign In button — orange like website Contact button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign In',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('©2026 Mavens-i Softech Solution Pvt Ltd',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.navy, size: 20),
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: AppColors.textGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 2)),
      filled: true,
      fillColor: AppColors.bgSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
