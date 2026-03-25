import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_screen.dart';

class EmployeeScreen extends StatefulWidget {
  final String userName;
  const EmployeeScreen({super.key, required this.userName});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _vehicleCtrl = TextEditingController();
  bool _loading      = false;
  String _message    = '';
  bool _success      = false;

  Future<void> _park() async {
    final vehicleNo = _vehicleCtrl.text.trim().toUpperCase();
    if (vehicleNo.isEmpty) {
      setState(() { _message = 'Please enter your vehicle number'; _success = false; });
      return;
    }

    setState(() { _loading = true; _message = ''; });

    try {
      final result = await ApiService.parkVehicle(widget.userName, vehicleNo);
      setState(() {
        _success = result['success'] == true;
        _message = result['message'] ?? 'Something went wrong';
      });
      if (_success) _vehicleCtrl.clear();
    } catch (_) {
      setState(() { _message = 'Connection error.'; _success = false; });
    } finally {
      setState(() => _loading = false);
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
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
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
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _success ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(_success ? Icons.check_circle : Icons.error,
                        color: _success ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_message)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
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
