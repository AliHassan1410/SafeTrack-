import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? responderType; // 🚑 Added responderType
  final String authProvider;
  final String? profilePic;
  final bool isEmailVerified;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.responderType,
    this.authProvider = 'local',
    this.profilePic,
    this.isEmailVerified = false,
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
      try {
        final data = jsonDecode(userJson);

        _currentUser = User(
          uid: data['_id'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? 'Not Provided',
          role: data['role'] ?? '',
          responderType: data['responderType'],
          authProvider: data['authProvider'] ?? 'local',
          profilePic: data['profilePic'],
          isEmailVerified: data['isEmailVerified'] ?? false,
        );
      } catch (_) {
        _currentUser = null;
        _token = null;
      }
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
      phone: userData['phone'] ?? 'Not Provided',
      role: userData['role'] ?? 'reporter',
      responderType: userData['responderType'],
      authProvider: userData['authProvider'] ?? 'local',
      profilePic: userData['profilePic'],
      isEmailVerified: userData['isEmailVerified'] ?? false,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(userData));
  }

  // ================= LOGIN =================
  Future<Map<String, dynamic>> signIn({
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

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveUserData(
        jsonResponse['user'],
        jsonResponse['user']['token'],
      );
      return jsonResponse;
    } else {
      if (jsonResponse['requiresVerification'] == true) {
        return jsonResponse;
      }
      throw Exception(jsonResponse['message'] ?? 'Failed to sign in');
    }
  }

  // ================= REGISTER =================
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? responderType,
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
        if (responderType != null) 'responderType': responderType,
      }),
    );

    if (response.statusCode == 201) {
      // Backend now returns OTP instruction instead of user object
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to sign up');
    }
  }

  // ================= VERIFY EMAIL =================
  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
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
      throw Exception(error['message'] ?? 'Failed to verify email');
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

  // ================= FORGOT PASSWORD =================
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send OTP');
    }
  }

  // ================= VERIFY RESET OTP =================
  Future<void> verifyResetOTP({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to verify OTP');
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to reset password');
    }
  }

  // ================= SIGN IN WITH GOOGLE =================
  Future<Map<String, dynamic>> signInWithGoogle({
    String role = 'reporter',
    bool isMock = false,
    String? mockEmail,
    String? mockName,
  }) async {
    String? idToken;

    if (!isMock) {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '850545060336-uga8bq0nnf61n928va2jc2nk9kgapra1.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();

      if (googleAccount == null) {
        throw Exception('Google sign-in was cancelled by the user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
            'Failed to get Google ID token. Check your Google Cloud Console configuration.');
      }
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'role': role,
        'isMock': isMock,
        if (mockEmail != null) 'mockEmail': mockEmail,
        if (mockName != null) 'mockName': mockName,
      }),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (jsonResponse['requiresVerification'] == true) {
        return jsonResponse;
      }

      await _saveUserData(
        jsonResponse['user'],
        jsonResponse['token'],
      );
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Google sign-in failed');
    }
  }

  // ================= VERIFY STORED TOKEN =================
  Future<bool> verifyStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final String? userJson = prefs.getString('user');

    if (_token == null || userJson == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User(
          uid: data['_id'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? 'Not Provided',
          role: data['role'] ?? '',
          responderType: data['responderType'],
          authProvider: data['authProvider'] ?? 'local',
          profilePic: data['profilePic'],
          isEmailVerified: data['isEmailVerified'] ?? false,
        );
        await prefs.setString('user', jsonEncode(data));
        
        // If user is unverified local user, return false
        if (!_currentUser!.isEmailVerified && _currentUser!.authProvider == 'local') {
          await signOut();
          return false;
        }
        
        return true;
      } else {
        await signOut();
        return false;
      }
    } catch (_) {
      if (_currentUser != null) {
        return _currentUser!.isEmailVerified || _currentUser!.authProvider == 'google';
      }
      return false;
    }
  }
}