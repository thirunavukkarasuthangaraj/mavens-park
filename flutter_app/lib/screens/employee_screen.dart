import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _checkingParked  = true;
  bool _parkedToday     = false;
  String _parkedVehicle = '';
  String _parkedTime    = '';
  List<dynamic> _history     = [];
  bool _loadingHistory       = false;
  bool _historyLoaded        = false;
  DateTime? _historyFrom;
  DateTime? _historyTo;

  @override
  void initState() {
    super.initState();
    _checkAlreadyParked();
  }

  Future<void> _checkAlreadyParked() async {
    try {
      final result = await ApiService.getDashboard();
      if (!mounted) return;
      if (result['success'] == true) {
        final parked = result['parked'] as List<dynamic>? ?? [];
        for (var emp in parked) {
          if (emp['emp_code']?.toString() == widget.empCode) {
            setState(() {
              _parkedToday   = true;
              _parkedVehicle = emp['vehicle_no']?.toString() ?? '';
              _parkedTime    = emp['time']?.toString() ?? '';
            });
            break;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _checkingParked = false);
  }

  String _nowTime() {
    final now = DateTime.now();
    final h   = now.hour.toString().padLeft(2, '0');
    final m   = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _loadHistory() async {
    setState(() { _loadingHistory = true; });
    final result = await ApiService.getHistory(
      widget.empCode,
      fromDate: _historyFrom != null ? _fmtDate(_historyFrom!) : null,
      toDate:   _historyTo   != null ? _fmtDate(_historyTo!)   : null,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _history = result['history'] ?? []; _historyLoaded = true; });
    }
    setState(() => _loadingHistory = false);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _historyFrom != null && _historyTo != null
          ? DateTimeRange(start: _historyFrom!, end: _historyTo!)
          : null,
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
    if (range != null) {
      setState(() { _historyFrom = range.start; _historyTo = range.end; });
      _loadHistory();
    }
  }

  Future<void> _park() async {
    final vehicleNo = _vehicleCtrl.text.trim().toUpperCase();
    if (vehicleNo.isEmpty) { showError('Please enter your vehicle number'); return; }
    setState(() => _loading = true);
    final result = await ApiService.parkVehicle(
        widget.empCode, widget.userName, vehicleNo);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      showSuccess('Vehicle parked successfully');
      setState(() {
        _parkedToday   = true;
        _parkedVehicle = vehicleNo;
        _parkedTime    = _nowTime();
      });
      _vehicleCtrl.clear();
    } else {
      showError(result['message'] ?? 'Failed to park vehicle');
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
    return PopScope(
      canPop: false,
      child: Scaffold(
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
              child: _checkingParked
                  ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                  : SingleChildScrollView(
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Successfully Parked!',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.directions_car,
                                        size: 13, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(_parkedVehicle,
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.access_time,
                                        size: 13, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text('Parked at $_parkedTime',
                                        style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12)),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Parking History ───────────────────────────
                    _historySection(),
                    const SizedBox(height: 16),

                    // ── Main park card (hidden when already parked) ──
                    if (!_parkedToday) Container(
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
                            child: const Icon(Icons.two_wheeler,
                                size: 42, color: Colors.white),
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
                              hintText: 'TN00 B0000',
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
    ));
  }

  String _toAmPm(String time) {
    try {
      final parts = time.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
      final p = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $p';
    } catch (_) { return time; }
  }

  String _friendlyDate(String date) {
    try {
      final d = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) return 'Today';
      if (day == yesterday) return 'Yesterday';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return date; }
  }

  Widget _historySection() {
    final hasFilter = _historyFrom != null && _historyTo != null;
    final filterLabel = hasFilter
        ? '${_historyFrom!.day}/${_historyFrom!.month} – ${_historyTo!.day}/${_historyTo!.month}'
        : 'All time';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: AppColors.navy.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history, color: AppColors.navy, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Parking History',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppColors.textDark)),
              ),
              // Date range chip
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasFilter
                        ? AppColors.orange.withOpacity(0.1)
                        : AppColors.navy.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: hasFilter
                            ? AppColors.orange.withOpacity(0.4)
                            : AppColors.navy.withOpacity(0.15)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.date_range,
                        size: 13,
                        color: hasFilter ? AppColors.orange : AppColors.navy),
                    const SizedBox(width: 4),
                    Text(filterLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: hasFilter ? AppColors.orange : AppColors.navy,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              if (_loadingHistory)
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy))
              else
                IconButton(
                  icon: Icon(
                    _historyLoaded ? Icons.refresh : Icons.expand_more,
                    color: AppColors.navy, size: 20),
                  onPressed: _loadHistory,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ]),
          ),

          // History list
          if (_historyLoaded) ...[
            const Divider(height: 1),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No parking records found',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _history.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final rec = _history[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_car_outlined,
                            color: AppColors.navy, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_friendlyDate(rec['date'] ?? ''),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(rec['vehicle_no'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(_toAmPm(rec['time'] ?? ''),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

