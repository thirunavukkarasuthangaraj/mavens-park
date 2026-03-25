import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/hash.dart';

const String scriptUrl =
    "https://script.google.com/macros/s/AKfycbw3HO17yO9RdGfnmYSsENo-RDccpHEAhgXwt0iYUD8/exec";

const _timeout = Duration(seconds: 20);

class ApiService {
  // ── Safe GET — no CORS issues in Chrome ────────────────
  static Future<Map<String, dynamic>> _get(Map<String, dynamic> body) async {
    try {
      final encoded = Uri.encodeComponent(jsonEncode(body));
      final uri     = Uri.parse('$scriptUrl?data=$encoded');
      final res     = await http.get(uri).timeout(_timeout);
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"success": false, "message": "Unexpected response"};
    } catch (e) {
      return {"success": false, "message": "Connection error. Check your internet."};
    }
  }

  // ── LOGIN ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String code, String password) =>
      _get({"action": "login", "code": code, "password": hashPassword(password)});

  // ── PARK VEHICLE ────────────────────────────────────────
  static Future<Map<String, dynamic>> parkVehicle(
          String empCode, String userName, String vehicleNo) =>
      _get({"action": "parkVehicle", "emp_code": empCode,
            "user_name": userName, "vehicle_no": vehicleNo});

  // ── DASHBOARD ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard({String? date}) =>
      _get({"action": "getDashboard", if (date != null) "date": date});

  // ── ASSIGN NUMBER ───────────────────────────────────────
  static Future<Map<String, dynamic>> assignNumber(String empCode, String number) =>
      _get({"action": "assignNumber", "emp_code": empCode, "number": number});

  // ── CHANGE PASSWORD (employee — plain old password) ─────
  static Future<Map<String, dynamic>> changePassword(
          String name, String oldPassword, String newPassword) =>
      _get({"action": "changePassword", "name": name,
            "old_password": hashPassword(oldPassword),
            "new_password": hashPassword(newPassword)});

  // ── CHANGE PASSWORD (force — old already hashed) ────────
  static Future<Map<String, dynamic>> changePasswordHashed(
          String name, String oldHashedPassword, String newPassword) =>
      _get({"action": "changePassword", "name": name,
            "old_password": oldHashedPassword,
            "new_password": hashPassword(newPassword)});

  // ── RESET PASSWORD (admin) ──────────────────────────────
  static Future<Map<String, dynamic>> resetPassword(
          String name, String newPassword) =>
      _get({"action": "resetPassword", "name": name,
            "new_password": hashPassword(newPassword)});
}
