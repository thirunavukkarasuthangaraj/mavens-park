import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import '../theme.dart';
import 'employee_screen.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  final String userName;
  final String empCode;
  final String currentHashedPassword;
  const ForceChangePasswordScreen({
    super.key,
    required this.userName,
    this.empCode = '',
    required this.currentHashedPassword,
  });
  @override
  State<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState
    extends State<ForceChangePasswordScreen> {
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscureNew  = true;
  bool _obscureConf = true;
  bool _loading     = false;

  Future<void> _submit() async {
    final np   = _newCtrl.text.trim();
    final conf = _confCtrl.text.trim();
    if (np.isEmpty || conf.isEmpty) { showError('Fill all fields'); return; }
    if (np.length < 4) { showError('Minimum 4 values required'); return; }
    if (np.length > 10) { showError('Maximum 10 values allowed'); return; }
    if (np != conf)    { showError('Passwords do not match'); return; }

    setState(() => _loading = true);
    final result = await ApiService.changePasswordHashed(
        widget.userName, widget.currentHashedPassword, np);
    setState(() => _loading = false);

    if (result['success'] == true) {
      showSuccess('Password set successfully. Welcome!');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => EmployeeScreen(userName: widget.userName, empCode: widget.empCode)),
        (_) => false,
      );
    } else {
      showError(result['message'] ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgSoft,
        appBar: AppBar(
          title: const Text('Set New Password'),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.orange.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your password was reset by admin.\nPlease set a new password to continue.',
                      style: TextStyle(color: AppColors.textDark,
                          fontSize: 13, height: 1.5),
                    ),
                  ),
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
                  Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.navy,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(widget.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: AppColors.textDark, fontSize: 15)),
                  ]),
                  const Divider(height: 28),

                  _passField('New Password', _newCtrl, _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew), showHint: true),
                  const SizedBox(height: 14),
                  _passField('Confirm Password', _confCtrl, _obscureConf,
                      () => setState(() => _obscureConf = !_obscureConf)),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(_loading ? 'Saving...' : 'Save & Continue',
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
