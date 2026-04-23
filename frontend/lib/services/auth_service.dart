import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String role;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });
}

class AuthService {
  static User? _currentUser;
  static String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  // 🌐 BASE URL (FIXED)
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://192.168.0.159:5000';
      }
    } catch (_) {}

    return 'http://192.168.0.159:5000';
  }

  // ================= INIT =================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user');
    _token = prefs.getString('token');

    if (userJson != null) {
      final data = jsonDecode(userJson);

      _currentUser = User(
        uid: data['_id'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? '',
      );
    }
  }

  // ================= SAVE USER =================
  Future<void> _saveUserData(
    Map<String, dynamic> userData,
    String token,
  ) async {
    _token = token;

    _currentUser = User(
      uid: userData['_id'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      role: userData['role'] ?? 'reporter',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(userData));
  }

  // ================= LOGIN =================
  Future<void> signIn({
    required String email,
    required String password,
    required String role, // 🔥 IMPORTANT ADD
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role, // 🔥 SEND ROLE TO BACKEND
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      await _saveUserData(
        jsonResponse['user'],
        jsonResponse['user']['token'],
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to sign in');
    }
  }

  // ================= REGISTER =================
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      await _saveUserData(
        jsonResponse['user'],
        jsonResponse['user']['token'],
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to sign up');
    }
  }

  // ================= LOGOUT =================
  Future<void> signOut() async {
    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ================= PROFILE =================
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }
}