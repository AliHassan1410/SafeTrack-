import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationService {
  static final _authService = AuthService();

  static Future<List<dynamic>> getNotifications() async {
    if (_authService.token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${_authService.baseUrl}/api/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.token}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markAsRead() async {
    if (_authService.token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${_authService.baseUrl}/api/notifications/mark-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.token}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }
}
