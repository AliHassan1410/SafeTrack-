import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:safetrack/utils/app_colors.dart';
import '../bottomNav/bottom_nav_bar.dart';
import 'package:safetrack/services/incident_services.dart';

class TrackResponder extends StatefulWidget {
  final Map<String, dynamic>? activeIncident;
  const TrackResponder({super.key, this.activeIncident});

  @override
  State<TrackResponder> createState() => _TrackResponderState();
}

class _TrackResponderState extends State<TrackResponder> {
  final MapController _mapController = MapController();
  LatLng? _reporterLocation;
  LatLng? _responderLocation;
  late IO.Socket _socket;
  
  bool _isLoading = true;
  Timer? _locationTimer;
  String _currentAddress = "Loading address...";
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchActiveIncident();
  }

  Future<void> _fetchActiveIncident() async {
    if (widget.activeIncident != null) {
      _initSocket(widget.activeIncident!['_id']);
      return;
    }
    
    try {
      // Import needed for IncidentService if not imported yet
      // Wait, let's just make sure to add the import if missing.
      final incidents = await IncidentService.getIncidents();
      // Look for an incident that hasn't been resolved or closed
      final active = incidents.where((i) => i['status'] != 'resolved' && i['status'] != 'closed').toList();
      if (active.isNotEmpty) {
        _initSocket(active.first['_id']);
        return;
      }
    } catch (e) {
      print("Error fetching reporter active incident: $e");
    }
    
    // Fallback if no active incident is found
    _initSocket("test_incident_id");
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'SafeTrack_App'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentAddress = data['display_name'] ?? "Unknown Location";
          });
        }
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  Future<void> _fetchRoute() async {
    if (_reporterLocation == null || _responderLocation == null) return;
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${_responderLocation!.longitude},${_responderLocation!.latitude};'
        '${_reporterLocation!.longitude},${_reporterLocation!.latitude}?geometries=geojson');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'];
          List<LatLng> points = [];
          for (var coord in geometry) {
            points.add(LatLng(coord[1], coord[0]));
          }
          if (mounted) {
            setState(() {
              _routePoints = points;
              if (route['distance'] != null) {
                _routeDistance = (route['distance'] as num).toDouble();
              }
              if (route['duration'] != null) {
                _routeDuration = (route['duration'] as num).toDouble();
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _reporterLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      _getAddressFromLatLng(pos.latitude, pos.longitude);
      _fitMapBounds();
    }
  }

  void _initSocket(String incidentId) {
    print("Initializing socket for incident: $incidentId");

    // Initialize Socket.IO connection to Backend
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      print('Connected to Socket');
      _socket.emit('join_incident', incidentId);
    });
    
    _socket.on('location_update', (data) {
      print("Responder Location Updated: $data");
      if (mounted) {
        setState(() {
          _responderLocation = LatLng(data['lat'], data['lng']);
        });
        _fetchRoute();
        _fitMapBounds();
      }
    });

    // Broadcast reporter's live location
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (incidentId != "test_incident_id") {
        Position newPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _reporterLocation = LatLng(newPos.latitude, newPos.longitude);
          });
          _fetchRoute();
        }
        _socket.emit('reporter_location_update', {
          'incidentId': incidentId,
          'lat': newPos.latitude,
          'lng': newPos.longitude,
        });
      }
    });
  }

  void _fitMapBounds() {
    if (_reporterLocation != null && _responderLocation != null) {
      final bounds = LatLngBounds.fromPoints([_reporterLocation!, _responderLocation!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    } else if (_reporterLocation != null) {
      _mapController.move(_reporterLocation!, 15);
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _reporterLocation ?? const LatLng(0, 0),
                          initialZoom: 14.0,
                          onMapReady: () {
                            _fitMapBounds();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.safetrack',
                          ),
                          PolylineLayer(
                            polylines: [
                              if (_routePoints.isNotEmpty)
                                Polyline(
                                  points: _routePoints,
                                  color: Colors.blue,
                                  strokeWidth: 4.0,
                                ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              if (_reporterLocation != null)
                                Marker(
                                  point: _reporterLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                              if (_responderLocation != null)
                                Marker(
                                  point: _responderLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.local_hospital, color: Colors.blue, size: 40),
                                ),
                            ],
                          ),
                        ],
                      ),
                      
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: _buildETAAndDistance(),
                      ),
                      
                      Positioned(
                        top: 20,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () {
                             _initLocation();
                          },
                          child: const Icon(Icons.my_location, color: AppColors.primary),
                        ),
                      )
                    ],
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x401E3A8A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Live Tracking",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "SECURE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Location: $_currentAddress\nLive map connection established.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETAAndDistance() {
    String distanceStr = "--";
    String etaStr = "Waiting...";
    
    if (_routeDistance != null) {
       distanceStr = "${(_routeDistance! / 1000).toStringAsFixed(1)} km";
    }
    if (_routeDuration != null) {
       int minutes = (_routeDuration! / 60).ceil();
       etaStr = "$minutes min";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_filled, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("ETA", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text(etaStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Distance", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text(distanceStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
