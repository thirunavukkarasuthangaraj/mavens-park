import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import '../theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userName;
  const ChangePasswordScreen({super.key, required this.userName});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscureOld  = true;
  bool _obscureNew  = true;
  bool _obscureConf = true;
  bool _loading     = false;

  Future<void> _change() async {
    final old  = _oldCtrl.text.trim();
    final np   = _newCtrl.text.trim();
    final conf = _confCtrl.text.trim();
    if (old.isEmpty || np.isEmpty || conf.isEmpty) { showError('Fill all fields'); return; }
    if (np.length < 4) { showError('Minimum 4 values required'); return; }
    if (np.length > 10) { showError('Maximum 10 values allowed'); return; }
    if (np != conf)    { showError('Passwords do not match'); return; }
    if (old == np)     { showError('New password must be different'); return; }

    setState(() => _loading = true);
    final result = await ApiService.changePassword(widget.userName, old, np);
    setState(() => _loading = false);

    if (result['success'] == true) {
      showSuccess('Password changed successfully');
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      showError(result['message'] ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lock_reset, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.userName,
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Update your password',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // Form card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: AppColors.navy.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                _passField('Current Password', _oldCtrl, _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld)),
                const SizedBox(height: 14),
                _passField('New Password', _newCtrl, _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew), showHint: true),
                const SizedBox(height: 14),
                _passField('Confirm New Password', _confCtrl, _obscureConf,
                    () => setState(() => _obscureConf = !_obscureConf)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _change,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.check),
                    label: Text(_loading ? 'Saving...' : 'Change Password',
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggle, {bool showHint = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        helperText: showHint ? 'Minimum 4 values' : null,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navy),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
              color: Colors.grey, size: 20),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.navy, width: 2)),
        filled: true,
        fillColor: AppColors.bgSoft,
      ),
    );
  }
}
