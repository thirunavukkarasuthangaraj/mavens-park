import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userName;
  const ChangePasswordScreen({super.key, required this.userName});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscureOld    = true;
  bool _obscureNew    = true;
  bool _obscureConf   = true;
  bool _loading       = false;
  String _error       = '';

  Future<void> _changePassword() async {
    final oldPass  = _oldPassCtrl.text.trim();
    final newPass  = _newPassCtrl.text.trim();
    final confirm  = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      showError('Please fill all fields');
      return;
    }
    if (newPass.length < 4) {
      showError('New password must be at least 4 characters');
      return;
    }
    if (newPass != confirm) {
      showError('New passwords do not match');
      return;
    }
    if (oldPass == newPass) {
      showError('New password must be different from current');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final result = await ApiService.changePassword(
          widget.userName, oldPass, newPass);

      if (result['success'] == true) {
        showSuccess('Password changed successfully');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        showError(result['message'] ?? 'Failed to change password');
      }
    } catch (_) {
      setState(() => _error = 'Connection error.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_reset, size: 72, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(widget.userName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 32),

            // Current password
            _passwordField(
              controller: _oldPassCtrl,
              label: 'Current Password',
              icon: Icons.lock_outline,
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),

            // New password
            _passwordField(
              controller: _newPassCtrl,
              label: 'New Password',
              icon: Icons.lock,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),

            // Confirm new password
            _passwordField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              icon: Icons.lock,
              obscure: _obscureConf,
              onToggle: () => setState(() => _obscureConf = !_obscureConf),
            ),
            const SizedBox(height: 12),

            if (_error.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _changePassword,
                icon: const Icon(Icons.check),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Change Password',
                        style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
