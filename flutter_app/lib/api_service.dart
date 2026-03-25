import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/hash.dart';

const String scriptUrl = "https://script.google.com/macros/s/AKfycbzPTsPRjGeN9c1ebFnI6s6hTKTRmFUTTjjYOCg6EAF7pIjKU6XOvWsWyIPRWMX_ugmB/exec";
const _timeout = Duration(seconds: 15);

class ApiService {
  // ── safe POST helper — never throws, always returns a map ──
  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(scriptUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(_timeout);
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"success": false, "message": "Unexpected response"};
    } catch (_) {
      return {"success": false, "message": "Connection error. Check your internet."};
    }
  }

  // ── LOGIN (by employee code or admin name) ─────────────────
  static Future<Map<String, dynamic>> login(String code, String password) =>
      _post({"action": "login", "code": code, "password": hashPassword(password)});

  // ── PARK VEHICLE ───────────────────────────────────────────
  static Future<Map<String, dynamic>> parkVehicle(
          String empCode, String userName, String vehicleNo) =>
      _post({"action": "parkVehicle", "emp_code": empCode,
             "user_name": userName, "vehicle_no": vehicleNo});

  // ── TODAY LOGS ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTodayLogs() =>
      _post({"action": "getTodayLogs"});

  // ── DASHBOARD ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard({String? date}) =>
      _post({"action": "getDashboard", if (date != null) "date": date});

  // ── ASSIGN NUMBER ──────────────────────────────────────────
  static Future<Map<String, dynamic>> assignNumber(String name, String number) =>
      _post({"action": "assignNumber", "name": name, "number": number});

  // ── CHANGE PASSWORD (employee — plain old password) ────────
  static Future<Map<String, dynamic>> changePassword(
          String name, String oldPassword, String newPassword) =>
      _post({
        "action":       "changePassword",
        "name":         name,
        "old_password": hashPassword(oldPassword),
        "new_password": hashPassword(newPassword),
      });

  // ── CHANGE PASSWORD (force — old password already hashed) ──
  static Future<Map<String, dynamic>> changePasswordHashed(
          String name, String oldHashedPassword, String newPassword) =>
      _post({
        "action":       "changePassword",
        "name":         name,
        "old_password": oldHashedPassword,
        "new_password": hashPassword(newPassword),
      });

  // ── RESET PASSWORD (admin — sets must_change = TRUE) ───────
  static Future<Map<String, dynamic>> resetPassword(String name, String newPassword) =>
      _post({
        "action":       "resetPassword",
        "name":         name,
        "new_password": hashPassword(newPassword),
      });
}
