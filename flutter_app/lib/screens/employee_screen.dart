import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class EmployeeScreen extends StatefulWidget {
  final String userName;
  const EmployeeScreen({super.key, required this.userName});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _vehicleCtrl = TextEditingController();
  bool _loading      = false;

  Future<void> _park() async {
    final vehicleNo = _vehicleCtrl.text.trim().toUpperCase();
    if (vehicleNo.isEmpty) {
      showError('Please enter your vehicle number');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.parkVehicle(widget.userName, vehicleNo);

    setState(() => _loading = false);

    if (result['success'] == true) {
      showSuccess('Vehicle parked successfully');
      _vehicleCtrl.clear();
    } else {
      showError(result['message'] ?? 'Failed to park vehicle');
    }
  }

  void _logout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.userName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(userName: widget.userName),
              ),
            ),
            icon: const Icon(Icons.key),
            tooltip: 'Change Password',
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      backgroundColor: Colors.indigo.shade50,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            const Text('Park Your Vehicle',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _vehicleCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. ABC-1234',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _park,
                icon: const Icon(Icons.check),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Parking', style: TextStyle(fontSize: 16)),
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
}
