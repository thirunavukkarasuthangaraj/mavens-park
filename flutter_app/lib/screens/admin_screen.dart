import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../utils/toast.dart';
import '../theme.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading        = true;
  int _total           = 0;
  int _parkedCount     = 0;
  int _notParkedCount  = 0;
  List<dynamic> _parked    = [];
  List<dynamic> _notParked = [];
  String _error        = '';
  DateTime _selectedDate = DateTime.now();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<dynamic> get _filteredParked => _parked.where(_matchSearch).toList();
  List<dynamic> get _filteredNotParked => _notParked.where(_matchSearch).toList();

  bool _matchSearch(dynamic emp) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return (emp['name']?.toString().toLowerCase().contains(q) ?? false) ||
           (emp['emp_code']?.toString().toLowerCase().contains(q) ?? false) ||
           (emp['number']?.toString().toLowerCase().contains(q) ?? false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  String _toAmPm(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $period';
    } catch (_) {
      return time;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) {
    final today     = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_formatDate(d) == _formatDate(today)) return 'Today';
    if (_formatDate(d) == _formatDate(yesterday)) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = ''; });
    final result = await ApiService.getDashboard(date: _formatDate(_selectedDate));
    if (result['success'] == true) {
      setState(() {
        _total          = result['total']            ?? 0;
        _parkedCount    = result['parked_count']     ?? 0;
        _notParkedCount = result['not_parked_count'] ?? 0;
        _parked         = result['parked']           ?? [];
        _notParked      = result['not_parked']       ?? [];
      });
    } else {
      setState(() => _error = result['message'] ?? 'Failed to load');
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            secondary: AppColors.orange,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadDashboard();
    }
  }

  // ── CSV Export ─────────────────────────────────────────
  Future<void> _exportCSV() async {
    try {
      final dateStr = _formatDate(_selectedDate);
      final buffer  = StringBuffer();
      buffer.writeln('Mavens Park - Parking Report');
      buffer.writeln('Date: $dateStr');
      buffer.writeln('');
      buffer.writeln('--- PARKED ---');
      buffer.writeln('Emp Code,Name,Vehicle No,Time');
      for (var emp in _parked) {
        buffer.writeln(
            '${emp['emp_code'] ?? ''},${emp['name'] ?? ''},${emp['vehicle_no'] ?? ''},${emp['time'] ?? ''}');
      }
      buffer.writeln('');
      buffer.writeln('--- NOT PARKED ---');
      buffer.writeln('Emp Code,Name');
      for (var emp in _notParked) {
        buffer.writeln('${emp['emp_code'] ?? ''},${emp['name'] ?? ''}');
      }
      buffer.writeln('');
      buffer.writeln('Total: $_total | Parked: $_parkedCount | Absent: $_notParkedCount');

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'parking_$dateStr.csv', mimeType: 'text/csv')],
        subject: 'Parking Report - $dateStr',
      );
    } catch (_) {
      showError('Failed to export. Try again.');
    }
  }

  // ── Assign Number ──────────────────────────────────────
  void _showAssignDialog(String empCode, String empName, String currentNumber) {
    final ctrl = TextEditingController(text: currentNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.tag, color: AppColors.navy),
          SizedBox(width: 8),
          Text('Assign Number',
              style: TextStyle(color: AppColors.textDark, fontSize: 18)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogLabel(empName),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Employee Number',
              prefixIcon: const Icon(Icons.tag, color: AppColors.navy),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.navy, width: 2)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final number = ctrl.text.trim();
              if (number.isEmpty) return;
              // Check if number already assigned to someone else
              final allEmps = [..._parked, ..._notParked];
              final conflict = allEmps.firstWhere(
                (e) => e['number']?.toString() == number &&
                        e['emp_code']?.toString() != empCode,
                orElse: () => null,
              );
              if (conflict != null) {
                showError('Number $number already assigned to ${conflict['name']}');
                return;
              }
              Navigator.pop(context);
              final result = await ApiService.assignNumber(empCode, number);
              if (result['success'] == true) {
                showSuccess('Number $number assigned to $empName');
                _loadDashboard();
              } else {
                showError(result['message'] ?? 'Failed');
              }
            },
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Reset Password ─────────────────────────────────────
  Future<void> _showResetPasswordDialog(String empName) async {
    showInfo('Resetting password...');
    try {
      final result = await ApiService.resetPassword(empName, 'Mavens@123');
      if (result['success'] == true) {
        showSuccess('Password reset for $empName');
      } else {
        showError(result['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: PopScope(
        canPop: false,
        child: SafeArea(
        child: Column(
          children: [
            // ── Navy header ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              decoration: const BoxDecoration(color: AppColors.navy),
              child: Column(
                children: [
                  // Top bar
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.dashboard_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Dashboard',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Mavens-i Softech Solution Pvt Ltd',
                              style: TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: _loadDashboard,
                        icon: const Icon(Icons.refresh, color: Colors.white70, size: 20)),
                    IconButton(onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 20)),
                  ]),

                  // ── Date filter bar ──────────────────────
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      // Prev day
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white70, size: 22),
                        onPressed: () {
                          setState(() => _selectedDate =
                              _selectedDate.subtract(const Duration(days: 1)));
                          _loadDashboard();
                        },
                      ),
                      // Date picker
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppColors.orange, size: 16),
                              const SizedBox(width: 6),
                              Text(_displayDate(_selectedDate),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                      // Next day (only up to today)
                      IconButton(
                        icon: Icon(Icons.chevron_right,
                            color: _formatDate(_selectedDate) ==
                                    _formatDate(DateTime.now())
                                ? Colors.white24
                                : Colors.white70,
                            size: 22),
                        onPressed: _formatDate(_selectedDate) ==
                                _formatDate(DateTime.now())
                            ? null
                            : () {
                                setState(() => _selectedDate =
                                    _selectedDate.add(const Duration(days: 1)));
                                _loadDashboard();
                              },
                      ),
                      // Export CSV
                      GestureDetector(
                        onTap: _parked.isEmpty && _notParked.isEmpty
                            ? null
                            : _exportCSV,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(children: [
                            Icon(Icons.download_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('CSV', style: TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ]),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.orange,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'Parked ($_parkedCount)'),
                      Tab(text: 'Not Parked ($_notParkedCount)'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search bar ─────────────────────────────────
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, emp code or number...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            // ── Summary cards ──────────────────────────────
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                _statCard('Total', _total, Icons.people_alt_outlined,
                    Colors.white, Colors.white12),
                const SizedBox(width: 10),
                _statCard('Parked', _parkedCount, Icons.check_circle_outline,
                    Colors.greenAccent, Colors.green.withOpacity(0.15)),
                const SizedBox(width: 10),
                _statCard('Absent', _notParkedCount, Icons.cancel_outlined,
                    AppColors.orange, AppColors.orange.withOpacity(0.15)),
              ]),
            ),

            // ── Tab content ────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                  : _error.isNotEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.orange, size: 48),
                          const SizedBox(height: 12),
                          Text(_error, style: const TextStyle(color: AppColors.textGrey)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadDashboard,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy),
                              child: const Text('Retry',
                                  style: TextStyle(color: Colors.white))),
                        ]))
                      : TabBarView(
                          controller: _tabController,
                          children: [_parkedList(), _notParkedList()],
                        ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _statCard(String label, int count, IconData icon,
      Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10,
                color: color.withOpacity(0.8))),
          ]),
        ]),
      ),
    );
  }

  Widget _parkedList() {
    final list = _filteredParked;
    if (_parked.isEmpty) return _emptyState(
        'No one parked on ${_displayDate(_selectedDate)}',
        Icons.directions_car_outlined);
    if (list.isEmpty) return _emptyState('No results for "$_searchQuery"', Icons.search_off);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final emp    = list[i];
        final number = emp['number']?.toString() ?? '';
        return _empCard(
          empCode:  emp['emp_code']?.toString() ?? '',
          number:   number,
          name:     emp['name'] ?? '',
          sub:      'Vehicle: ${emp['vehicle_no'] ?? ''}',
          badge:    _toAmPm(emp['time'] ?? ''),
          badgeColor: Colors.green,
          isParked: true,
          onAssign: () => _showAssignDialog(
              emp['emp_code'] ?? '', emp['name'] ?? '', number),
          onReset:  () => _showResetPasswordDialog(emp['name'] ?? ''),
        );
      },
    );
  }

  Widget _notParkedList() {
    final list = _filteredNotParked;
    if (_notParked.isEmpty) return _emptyState(
        'All employees parked on ${_displayDate(_selectedDate)}! 🎉',
        Icons.check_circle_outline);
    if (list.isEmpty) return _emptyState('No results for "$_searchQuery"', Icons.search_off);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final emp    = list[i];
        final number = emp['number']?.toString() ?? '';
        return _empCard(
          empCode:  emp['emp_code']?.toString() ?? '',
          number:   number,
          name:     emp['name'] ?? '',
          sub:      'Not parked',
          badge:    'Absent',
          badgeColor: AppColors.orange,
          isParked: false,
          onAssign: () => _showAssignDialog(
              emp['emp_code'] ?? '', emp['name'] ?? '', number),
          onReset:  () => _showResetPasswordDialog(emp['name'] ?? ''),
        );
      },
    );
  }

  Widget _empCard({
    required String empCode,
    required String number,
    required String name,
    required String sub,
    required String badge,
    required Color badgeColor,
    required bool isParked,
    required VoidCallback onAssign,
    required VoidCallback onReset,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isParked
              ? Colors.green.withOpacity(0.12)
              : AppColors.orange.withOpacity(0.12),
          child: number.isNotEmpty
              ? Text(number, style: TextStyle(fontWeight: FontWeight.bold,
                  color: isParked ? Colors.green : AppColors.orange, fontSize: 13))
              : Icon(isParked ? Icons.check : Icons.person_outline,
                  color: isParked ? Colors.green : AppColors.orange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 15, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badgeColor.withOpacity(0.35)),
          ),
          child: Text(badge, style: TextStyle(fontSize: 11, color: badgeColor,
              fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navy.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(empCode, style: const TextStyle(fontSize: 11,
              color: AppColors.navy, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        _iconBtn(Icons.lock_reset, AppColors.orange, onReset),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );

  Widget _emptyState(String msg, IconData icon) =>
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
      ]));

  Widget _dialogLabel(String name) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.bgSoft,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.person_outline, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold,
              color: AppColors.textDark)),
        ]),
      );

}
