import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────
// Model: GoogleUser (lightweight struct for in-memory state)
// ─────────────────────────────────────────────────────────────
class GoogleAuthUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? responderType;
  final String? profilePic;
  final String authProvider;

  GoogleAuthUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.responderType,
    this.profilePic,
    required this.authProvider,
  });

  factory GoogleAuthUser.fromJson(Map<String, dynamic> json) {
    return GoogleAuthUser(
      uid: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'reporter',
      responderType: json['responderType'],
      profilePic: json['profilePic'],
      authProvider: json['authProvider'] ?? 'google',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': uid,
        'name': name,
        'email': email,
        'role': role,
        'responderType': responderType,
        'profilePic': profilePic,
        'authProvider': authProvider,
      };
}

// ─────────────────────────────────────────────────────────────
// GoogleAuthService
// ─────────────────────────────────────────────────────────────
class GoogleAuthService {
  // ── Singleton ──
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // ── State ──
  static GoogleAuthUser? _currentUser;
  static String? _jwtToken;

  GoogleAuthUser? get currentUser => _currentUser;
  String? get jwtToken => _jwtToken;
  bool get isSignedIn => _jwtToken != null && _currentUser != null;

  // ── Secure Storage (Keychain on iOS, Keystore on Android) ──
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'google_jwt_token';
  static const _userKey = 'google_user_data';

  // ── Google Sign-In client ──
  // 👉 Replace the clientId below with your own from Google Cloud Console.
  //    For Android: the SHA-1 fingerprint must be registered in the project.
  //    For iOS: add the reversed client ID to Info.plist CFBundleURLSchemes.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // clientId is only required for iOS / Web.
    // Android uses the SHA-1 registered in Firebase / Cloud Console.
    // clientId: 'YOUR_IOS_OR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );

  // ── Backend base URL ──
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://192.168.0.159:5000';
    } catch (_) {}
    return 'http://192.168.0.159:5000';
  }

  // ─────────────────────────────────────────────────────────
  // INIT — Call this in main() before runApp()
  // Restores JWT & user from secure storage for auto-login
  // ─────────────────────────────────────────────────────────
  Future<void> init() async {
    _jwtToken = await _storage.read(key: _tokenKey);
    final userJson = await _storage.read(key: _userKey);

    if (userJson != null) {
      try {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = GoogleAuthUser.fromJson(data);
      } catch (_) {
        // Corrupt data — clear it
        await _clearStorage();
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIGN IN WITH GOOGLE
  // 1. Triggers native Google account picker
  // 2. Gets the Google ID token
  // 3. Sends ID token to your backend /api/auth/google
  // 4. Backend verifies with Google, returns JWT
  // 5. Stores JWT securely
  // ─────────────────────────────────────────────────────────
  Future<GoogleAuthUser> signInWithGoogle({String role = 'reporter'}) async {
    // Step 1 — Native Google picker
    final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

    if (googleAccount == null) {
      throw Exception('Google sign-in was cancelled by the user');
    }

    // Step 2 — Get auth tokens from Google
    final GoogleSignInAuthentication googleAuth =
        await googleAccount.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception(
          'Failed to get Google ID token. Check your Google Cloud Console configuration.');
    }

    // Step 3 — Send ID token to backend
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Step 4 — Save JWT and user
      await _saveSession(
        token: data['token'] as String,
        userData: data['user'] as Map<String, dynamic>,
      );

      return _currentUser!;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Google sign-in failed');
    }
  }

  // ─────────────────────────────────────────────────────────
  // VERIFY JWT — Check if stored token is still valid
  // Call this on app startup after init()
  // ─────────────────────────────────────────────────────────
  Future<bool> verifyStoredToken() async {
    if (_jwtToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/profile/google'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        // Refresh in-memory user with latest data from server
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = GoogleAuthUser.fromJson(data);
        await _storage.write(key: _userKey, value: jsonEncode(data));
        return true;
      } else {
        // Token expired or invalid
        await _clearStorage();
        return false;
      }
    } catch (_) {
      // Network error — trust the stored token optimistically
      return _currentUser != null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // 1. Sign out from Google (clears cached Google account)
    await _googleSignIn.signOut();

    // 2. Optionally call backend logout
    if (_jwtToken != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
        );
      } catch (_) {
        // Silent fail — local logout still succeeds
      }
    }

    // 3. Clear local state
    _currentUser = null;
    _jwtToken = null;
    await _clearStorage();
  }

  // ─────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────
  Future<void> _saveSession({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    _jwtToken = token;
    _currentUser = GoogleAuthUser.fromJson(userData);

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Returns the Authorization header value for use in HTTP requests.
  /// Example: http.get(url, headers: {'Authorization': authService.authHeader})
  String get authHeader => 'Bearer $_jwtToken';
}
