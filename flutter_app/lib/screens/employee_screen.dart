import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class EmployeeScreen extends StatefulWidget {
  final String userName;
  final String empCode;
  const EmployeeScreen({super.key, required this.userName, this.empCode = ''});
  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _vehicleCtrl    = TextEditingController();
  bool _loading         = false;
  bool _parkedToday     = false;
  String _parkedVehicle = '';

  Future<void> _park() async {
    final vehicleNo = _vehicleCtrl.text.trim().toUpperCase();
    if (vehicleNo.isEmpty) { showError('Please enter your vehicle number'); return; }
    setState(() => _loading = true);
    final result = await ApiService.parkVehicle(
        widget.empCode, widget.userName, vehicleNo);
    setState(() => _loading = false);
    if (result['success'] == true) {
      showSuccess('Vehicle parked successfully');
      setState(() { _parkedToday = true; _parkedVehicle = vehicleNo; });
      _vehicleCtrl.clear();
    } else {
      showError(result['message'] ?? 'Failed to park vehicle');
    }
  }

  void _logout() => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Column(
          children: [
            // ── Navy header ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.orange,
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${widget.userName}',
                            style: const TextStyle(fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const Text('Smart Parking System',
                            style: TextStyle(fontSize: 11,
                                color: Colors.white60)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            ChangePasswordScreen(userName: widget.userName))),
                    icon: const Icon(Icons.key_outlined,
                        color: Colors.white70, size: 22),
                    tooltip: 'Change Password',
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Parked today banner ───────────────
                    if (_parkedToday) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 30),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Parked Today',
                                    style: TextStyle(fontWeight: FontWeight.bold,
                                        color: Colors.green, fontSize: 14)),
                                Text('Vehicle: $_parkedVehicle',
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Main park card ────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                            color: AppColors.navy.withOpacity(0.07),
                            blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        children: [
                          // Icon block — navy bg like website
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.directions_car,
                                size: 38, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          const Text('Park Your Vehicle',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          const Text('Enter your vehicle plate number',
                              style: TextStyle(fontSize: 13,
                                  color: AppColors.textGrey)),
                          const SizedBox(height: 24),

                          // Vehicle number input
                          TextField(
                            controller: _vehicleCtrl,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold, letterSpacing: 3),
                            decoration: InputDecoration(
                              labelText: 'Vehicle Number',
                              hintText: 'ABC - 1234',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade300, letterSpacing: 2,
                                  fontWeight: FontWeight.normal, fontSize: 18),
                              prefixIcon: const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: AppColors.navy),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: AppColors.navy, width: 2)),
                              filled: true,
                              fillColor: AppColors.bgSoft,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit — orange like website CTA
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _park,
                              icon: _loading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                  _loading ? 'Submitting...' : 'Submit Parking',
                                  style: const TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
