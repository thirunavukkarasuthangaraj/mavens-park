import 'package:flutter/material.dart';
import '../api_service.dart';
import 'employee_screen.dart';

/// Shown when must_change == true. User cannot go back or skip.
class ForceChangePasswordScreen extends StatefulWidget {
  final String userName;
  final String currentHashedPassword; // the temp password hash from login
  const ForceChangePasswordScreen({
    super.key,
    required this.userName,
    required this.currentHashedPassword,
  });

  @override
  State<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscureNew    = true;
  bool _obscureConf   = true;
  bool _loading       = false;
  String _error       = '';

  Future<void> _submit() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (newPass.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      // We use changePassword but pass the already-hashed temp password as old
      final result = await ApiService.changePasswordHashed(
        widget.userName,
        widget.currentHashedPassword, // old = temp hashed password
        newPass,                      // new = plain (will be hashed inside)
      );

      if (result['success'] == true) {
        if (!mounted) return;
        // Replace entire stack — go to employee home, can't go back to this screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => EmployeeScreen(userName: widget.userName)),
          (_) => false,
        );
      } else {
        setState(() => _error = result['message'] ?? 'Failed');
      }
    } catch (_) {
      setState(() => _error = 'Connection error.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // block back button
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          title: const Text('Set New Password'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // hide back arrow
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.lock_reset, size: 72, color: Colors.indigo),
              const SizedBox(height: 12),

              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your password was reset by admin.\nPlease set a new password to continue.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // New password
              TextField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConf,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConf ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConf = !_obscureConf),
                  ),
                ),
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
                      Expanded(child: Text(_error,
                          style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Continue',
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
      ),
    );
  }
}
