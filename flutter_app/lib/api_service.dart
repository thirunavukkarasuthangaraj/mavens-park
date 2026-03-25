import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/hash.dart';

// Replace with your deployed Apps Script Web App URL
const String scriptUrl = "YOUR_APPS_SCRIPT_WEB_APP_URL_HERE";

class ApiService {
  static Future<Map<String, dynamic>> login(String name, String password) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action":   "login",
        "name":     name,
        "password": hashPassword(password),
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> parkVehicle(String userName, String vehicleNo) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action":     "parkVehicle",
        "user_name":  userName,
        "vehicle_no": vehicleNo,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getTodayLogs() async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": "getTodayLogs"}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": "getDashboard"}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> assignNumber(String name, String number) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": "assignNumber", "name": name, "number": number}),
    );
    return jsonDecode(res.body);
  }

  /// Employee changes own password — verifies old password (plain text, hashed here)
  static Future<Map<String, dynamic>> changePassword(
      String name, String oldPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action":       "changePassword",
        "name":         name,
        "old_password": hashPassword(oldPassword),
        "new_password": hashPassword(newPassword),
      }),
    );
    return jsonDecode(res.body);
  }

  /// Force change after admin reset — old password is already hashed (from login response)
  static Future<Map<String, dynamic>> changePasswordHashed(
      String name, String oldHashedPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action":       "changePassword",
        "name":         name,
        "old_password": oldHashedPassword,   // already hashed
        "new_password": hashPassword(newPassword),
      }),
    );
    return jsonDecode(res.body);
  }

  /// Admin resets employee password — sets must_change = TRUE in sheet
  static Future<Map<String, dynamic>> resetPassword(String name, String newPassword) async {
    final res = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action":       "resetPassword",
        "name":         name,
        "new_password": hashPassword(newPassword),
      }),
    );
    return jsonDecode(res.body);
  }
}
