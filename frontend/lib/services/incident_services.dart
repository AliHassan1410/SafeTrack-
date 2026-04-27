import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IncidentService {
  // 🌐 Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    } else {
      return "http://192.168.0.159:5000/api";
    }
  }

  // 🔐 Get JWT token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /* ---------------------------------------
     🚨 CREATE INCIDENT (REPORTER)
  ----------------------------------------*/
  static Future<void> createIncident({
    required String title,
    required String type,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
  }) async {
    try {
      final token = await _getToken();

      // ⭐ MOST IMPORTANT FIX ADDED HERE
      if (token == null) {
        throw Exception("User not logged in. Token missing.");
      }

      String mappedType = "medical";
      if (type.toLowerCase() == "crime") {
        mappedType = "crime";
      }

      final response = await http.post(
        Uri.parse("$baseUrl/incidents"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "type": mappedType,
          "description": description,
          "location": {"lat": lat, "lng": lng},
          if (imageUrl != null) "imageUrl": imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        print("✅ Incident created");
      } else {
        print("❌ Error: ${response.body}");
        throw Exception("Failed to create incident: ${response.body}");
      }
    } catch (e) {
      print("❌ Create Incident Error: $e");
      rethrow;
    }
  }

  /* ---------------------------------------
     📥 GET REPORTER INCIDENTS
  ----------------------------------------*/
  static Future<List<dynamic>> getIncidents() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/incidents"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ Get Incidents Error: $e");
      return [];
    }
  }

  /* ---------------------------------------
     🚑 GET NEARBY INCIDENTS (RESPONDER)
     🔥 2 KM + TYPE FILTER
  ----------------------------------------*/
  static Future<List<dynamic>> getNearbyIncidents({
    required double lat,
    required double lng,
    required String type,
  }) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/incidents/nearby?lat=$lat&lng=$lng&type=$type"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("❌ Nearby Error: ${response.body}");
      return [];
    } catch (e) {
      print("❌ Nearby Incident Error: $e");
      return [];
    }
  }

  /* ---------------------------------------
     🚑 ACCEPT INCIDENT (RESPONDER)
  ----------------------------------------*/
  static Future<void> acceptIncident(String incidentId) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/incidents/$incidentId/accept"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        print("✅ Incident accepted");
      } else {
        print("❌ Accept failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Accept Error: $e");
    }
  }

  /* ---------------------------------------
     🩺 GET ASSIGNED INCIDENTS (RESPONDER)
  ----------------------------------------*/
  static Future<List<dynamic>> getAssignedIncidents() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/incidents/assigned"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("❌ Assigned Error: ${response.body}");
      return [];
    } catch (e) {
      print("❌ Assigned Incident Error: $e");
      return [];
    }
  }

  /* ---------------------------------------
     📍 UPDATE RESPONDER LOCATION (LIVE)
  ----------------------------------------*/
  static Future<void> updateResponderLocation({
    required String incidentId,
    required double lat,
    required double lng,
  }) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/incidents/$incidentId/location"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "lat": lat,
          "lng": lng,
        }),
      );

      if (response.statusCode != 200) {
        print("❌ Location update failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Location Error: $e");
    }
  }
}