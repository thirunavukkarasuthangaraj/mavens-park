import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'utils/hash.dart';

const String scriptUrl =
    "https://script.google.com/macros/s/AKfycbz7hMzHIrcDUfxcz4xuAFr_NcNYxtqD9EtoLharFvQQZzFwiopRIT63aukZx4ESpNUC/exec";

const _timeout = Duration(seconds: 30);

class ApiService {
  static http.Client? _client;

  static http.Client _getClient() {
    _client ??= http.Client();
    return _client!;
  }

  static Future<Map<String, dynamic>> _get(Map<String, dynamic> body) async {
    try {
      final encoded = Uri.encodeComponent(jsonEncode(body));
      final uri = Uri.parse('$scriptUrl?data=$encoded');

      http.Response res;
      if (kIsWeb) {
        // Web: use simple get (browser handles CORS/redirect)
        res = await http.get(uri).timeout(_timeout);
      } else {
        // Mobile: use persistent client for better redirect handling
        res = await _getClient().get(uri).timeout(_timeout);
      }

      if (res.statusCode != 200) {
        return {"success": false, "message": "Server error (${res.statusCode})"};
      }

      final body2 = res.body.trim();
      if (body2.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      try {
        final decoded = jsonDecode(body2);
        if (decoded is Map<String, dynamic>) return decoded;
        return {"success": false, "message": "Unexpected response format"};
      } catch (_) {
        // Response is not JSON — likely an HTML error page
        return {"success": false, "message": "Server returned invalid response. Please try again."};
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        return {"success": false, "message": "Request timed out. Check your internet and try again."};
      }
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        return {"success": false, "message": "No internet connection. Please check your network."};
      }
      if (msg.contains('HandshakeException') || msg.contains('certificate')) {
        return {"success": false, "message": "SSL error. Please update the app."};
      }
      if (kIsWeb) {
        return {"success": false, "message": "Connection error. Ensure script is deployed for 'Anyone'."};
      }
      return {"success": false, "message": "Connection error: $msg"};
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

  // ── GET HISTORY (employee) ──────────────────────────────
  static Future<Map<String, dynamic>> getHistory(
          String empCode, {String? fromDate, String? toDate}) =>
      _get({
        "action": "getHistory",
        "emp_code": empCode,
        if (fromDate != null) "from_date": fromDate,
        if (toDate != null) "to_date": toDate,
      });

  // ── GET REPORT (admin: date range) ──────────────────────
  static Future<Map<String, dynamic>> getReport(
          {String? fromDate, String? toDate}) =>
      _get({
        "action": "getReport",
        if (fromDate != null) "from_date": fromDate,
        if (toDate != null) "to_date": toDate,
      });

  // ── RESET PASSWORD (admin) ──────────────────────────────
  static Future<Map<String, dynamic>> resetPassword(
          String name, String newPassword) =>
      _get({"action": "resetPassword", "name": name,
            "new_password": hashPassword(newPassword)});
}
