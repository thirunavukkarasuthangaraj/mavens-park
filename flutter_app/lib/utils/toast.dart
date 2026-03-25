import 'package:flutter/material.dart';
import '../../main.dart';

void showSuccess(String message) => _show(message, Colors.green.shade700, Icons.check_circle_outline);
void showError(String message)   => _show(message, const Color(0xFFD32F2F), Icons.error_outline);
void showInfo(String message)    => _show(message, const Color(0xFF1A2744), Icons.info_outline);

void _show(String message, Color color, IconData icon) {
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 14))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
}
