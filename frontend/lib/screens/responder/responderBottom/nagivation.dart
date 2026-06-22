import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/responder/responderBottom/responderBottomBarNavigation.dart';
import 'package:safetrack/services/incident_services.dart';
import 'package:safetrack/services/auth_service.dart';

class Trackreporter extends StatefulWidget {
  const Trackreporter({super.key});

  @override
  State<Trackreporter> createState() => _TrackreporterState();
}

class _TrackreporterState extends State<Trackreporter> {
  bool _isGpsActive = true;
  bool _isLiveTracking = true;
  final MapController _mapController = MapController();
  LatLng? _responderLocation; // Current user (Responder)
  LatLng? _reporterLocation; // Destination (Reporter)
  late IO.Socket _socket;
  String? _activeIncidentId;
  Timer? _locationTimer;
  bool _isLoading = true;
  String _currentAddress = "Loading address...";
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;
  bool _isCompleting = false;

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

  @override
  void initState() {
    super.initState();
    _fetchActiveIncident();
  }

  Future<void> _fetchActiveIncident() async {
    try {
      final assigned = await IncidentService.getAssignedIncidents();
      final active = assigned.where((i) => i['status'] == 'accepted').toList();
      if (active.isNotEmpty) {
        final incident = active.first;
        _activeIncidentId = incident['_id'];
        if (incident['location'] != null && incident['location']['coordinates'] != null) {
          final coords = incident['location']['coordinates']; // [lng, lat]
          if (coords.length >= 2) {
             _reporterLocation = LatLng(coords[1], coords[0]);
          }
        }
      } else {
        _activeIncidentId = null;
        _reporterLocation = null;
        _routePoints = [];
        _routeDistance = null;
        _routeDuration = null;
      }
    } catch (e) {
      print("Error fetching active incident for map: $e");
    } finally {
      if (mounted) {
        setState(() {});
      }
      _initLocationAndSocket();
    }
  }

  Future<void> _initLocationAndSocket() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() { _isGpsActive = false; _isLoading = false; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        if (mounted) setState(() { _isGpsActive = false; _isLoading = false; });
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _responderLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      _getAddressFromLatLng(pos.latitude, pos.longitude);
      _fitMapBounds();
    }

    // Initialize Socket
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      print('Responder Connected to Socket');
      if (_activeIncidentId != null) {
        _socket.emit('join_incident', _activeIncidentId);
        _broadcastLocation(pos.latitude, pos.longitude);
      }
    });

    _socket.on('reporter_location_update', (data) {
      print("Reporter Location Updated: $data");
      if (mounted) {
        setState(() {
          _reporterLocation = LatLng(data['lat'], data['lng']);
        });
        _fetchRoute();
        _fitMapBounds();
      }
    });

    // Start location tracking loop
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isLiveTracking && _activeIncidentId != null) {
        Position newPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _responderLocation = LatLng(newPos.latitude, newPos.longitude);
          });
          _fetchRoute();
        }
        _broadcastLocation(newPos.latitude, newPos.longitude);
      }
    });
  }

  void _broadcastLocation(double lat, double lng) {
    if (_activeIncidentId == null) return;
    String responderId = AuthService().currentUser?.uid ?? "unknown";
    _socket.emit('responder_location_update', {
      'incidentId': _activeIncidentId,
      'lat': lat,
      'lng': lng,
      'responderId': responderId
    });
  }

  void _fitMapBounds() {
    if (_reporterLocation != null && _responderLocation != null) {
      final bounds = LatLngBounds.fromPoints([_reporterLocation!, _responderLocation!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    } else if (_responderLocation != null) {
      _mapController.move(_responderLocation!, 15);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Live Tracking",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            onPressed: () {
              _showSettingsDialog();
            },
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _gpsStatus(),
              const SizedBox(height: 16),
              _mapView(),
              _infoPanel(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ResponderBottomBarNavigation(currentIndex: 2),
    );
  }

  Widget _gpsStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isGpsActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.gps_fixed,
              color: _isGpsActive ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGpsActive ? "Live GPS Active" : "GPS Disabled",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isGpsActive
                      ? "Location: $_currentAddress"
                      : "Enable GPS to share location",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isLiveTracking,
            onChanged: (value) {
              setState(() {
                _isLiveTracking = value;
              });
            },
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _mapView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _responderLocation ?? const LatLng(0, 0),
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
                      if (_responderLocation != null)
                        Marker(
                          point: _responderLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.local_hospital, color: Colors.blue, size: 40),
                        ),
                      if (_reporterLocation != null)
                        Marker(
                          point: _reporterLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Top Info Pill
          if (_activeIncidentId != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.share_location, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Broadcasting Location",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Map Controls
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () { _fitMapBounds(); },
                    icon: const Icon(Icons.zoom_out_map, color: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: () {
                      _centerOnLocation();
                    },
                    icon: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _infoPanel() {
    String distanceStr = "Calculating...";
    String etaStr = "Calculating...";
    
    if (_routeDistance != null) {
       distanceStr = "${(_routeDistance! / 1000).toStringAsFixed(1)} km";
    }
    if (_routeDuration != null) {
       int minutes = (_routeDuration! / 60).ceil();
       etaStr = "$minutes min";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Incident Navigation",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  label: "Distance",
                  value: distanceStr,
                  icon: Icons.route_outlined,
                ),
              ),
              Expanded(
                child: _infoTile(
                  label: "ETA",
                  value: etaStr,
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeIncidentId != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCompleting ? null : _markIncidentComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isCompleting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Mark as Completed",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _markIncidentComplete() async {
    if (_activeIncidentId == null) return;
    setState(() {
      _isCompleting = true;
    });

    try {
      await IncidentService.completeIncident(_activeIncidentId!);
      
      // Re-fetch to clear the active incident state
      await _fetchActiveIncident();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Incident marked as completed!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print("Error completing incident: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to complete incident."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }



  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tracking Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("Live Tracking"),
              subtitle: const Text("Enable real-time location updates"),
              value: _isLiveTracking,
              onChanged: (value) {
                setState(() {
                  _isLiveTracking = value;
                });
              },
              activeColor: AppColors.primary,
            ),
            SwitchListTile(
              title: const Text("GPS Accuracy"),
              subtitle: const Text("High accuracy mode"),
              value: _isGpsActive,
              onChanged: (value) {
                setState(() {
                  _isGpsActive = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _centerOnLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Centered on your location"),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

}
