import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading        = true;
  int _total           = 0;
  int _parkedCount     = 0;
  int _notParkedCount  = 0;
  List<dynamic> _parked    = [];
  List<dynamic> _notParked = [];
  String _error        = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await ApiService.getDashboard();
      if (result['success'] == true) {
        setState(() {
          _total          = result['total']            ?? 0;
          _parkedCount    = result['parked_count']     ?? 0;
          _notParkedCount = result['not_parked_count'] ?? 0;
          _parked         = result['parked']           ?? [];
          _notParked      = result['not_parked']       ?? [];
        });
      } else {
        setState(() => _error = 'Failed to load dashboard');
      }
    } catch (_) {
      setState(() => _error = 'Connection error.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Reset Password Dialog ─────────────────────────────
  void _showResetPasswordDialog(String empName) {
    final newPassCtrl    = TextEditingController();
    final confirmCtrl    = TextEditingController();
    bool obscure         = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee: $empName',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final np = newPassCtrl.text.trim();
                final cp = confirmCtrl.text.trim();
                if (np.isEmpty) { showError('Please enter a password'); return; }
                if (np.length < 4) { showError('Password must be at least 4 characters'); return; }
                if (np != cp) { showError('Passwords do not match'); return; }
                Navigator.pop(ctx);
                await _resetPassword(empName, np);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword(String empName, String newPassword) async {
    final result = await ApiService.resetPassword(empName, newPassword);
    if (result['success'] == true) {
      showSuccess('Password reset for $empName');
    } else {
      showError(result['message'] ?? 'Failed to reset password');
    }
  }

  // ── Assign Number Dialog ──────────────────────────────
  void _showAssignDialog(String empName, String currentNumber) {
    final ctrl = TextEditingController(text: currentNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: $empName',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Employee Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              final number = ctrl.text.trim();
              if (number.isEmpty) return;
              Navigator.pop(context);
              await _assignNumber(empName, number);
            },
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _assignNumber(String empName, String number) async {
    final result = await ApiService.assignNumber(empName, number);
    if (result['success'] == true) {
      showSuccess('Number $number assigned to $empName');
      _loadDashboard();
    } else {
      showError(result['message'] ?? 'Failed to assign number');
    }
  }

  void _logout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadDashboard, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Parked ($_parkedCount)'),
            Tab(text: 'Not Parked ($_notParkedCount)'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Summary Cards ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _summaryCard('Total\nEmployees', _total, Colors.indigo),
                          const SizedBox(width: 12),
                          _summaryCard('Parked\nToday', _parkedCount, Colors.green),
                          const SizedBox(width: 12),
                          _summaryCard('Not\nParked', _notParkedCount, Colors.orange),
                        ],
                      ),
                    ),

                    // ── Tabs ─────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _parkedList(),
                          _notParkedList(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$count',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Parked List ───────────────────────────────────────
  Widget _parkedList() {
    if (_parked.isEmpty) {
      return const Center(
        child: Text('No employees parked yet today',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _parked.length,
      itemBuilder: (_, i) {
        final emp = _parked[i];
        final number = emp['number']?.toString() ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: number.isNotEmpty
                  ? Text(number,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
            title: Text(emp['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Vehicle: ${emp['vehicle_no'] ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(emp['time'] ?? '',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                _iconBtn(Icons.tag, Colors.indigo,
                    () => _showAssignDialog(emp['name'] ?? '', number)),
                const SizedBox(width: 6),
                _iconBtn(Icons.key, Colors.red,
                    () => _showResetPasswordDialog(emp['name'] ?? '')),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Not Parked List ───────────────────────────────────
  Widget _notParkedList() {
    if (_notParked.isEmpty) {
      return const Center(
        child: Text('All employees have parked today!',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _notParked.length,
      itemBuilder: (_, i) {
        final emp = _notParked[i];
        final number = emp['number']?.toString() ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: number.isNotEmpty
                  ? Text(number,
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold))
                  : const Icon(Icons.cancel, color: Colors.orange),
            ),
            title: Text(emp['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Not parked today'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text('Absent',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                _iconBtn(Icons.tag, Colors.indigo,
                    () => _showAssignDialog(emp['name'] ?? '', number)),
                const SizedBox(width: 6),
                _iconBtn(Icons.key, Colors.red,
                    () => _showResetPasswordDialog(emp['name'] ?? '')),
              ],
            ),
          ),
        );
      },
    );
  }
}
