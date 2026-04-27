import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  String _selectedTeam = "All"; // All, Police, Ambulance
  
  GoogleMapController? _mapController;
  LatLng? _responderLocation; // Current user (Responder)
  LatLng? _reporterLocation; // Destination (Reporter)
  late IO.Socket _socket;
  String? _activeIncidentId;
  Timer? _locationTimer;
  bool _isLoading = true;

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
      }
    } catch (e) {
      print("Error fetching active incident for map: $e");
    } finally {
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

    // Start location tracking loop
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isLiveTracking && _activeIncidentId != null) {
        Position newPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _responderLocation = LatLng(newPos.latitude, newPos.longitude);
          });
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
    if (_mapController == null) return;

    if (_reporterLocation != null && _responderLocation != null) {
      LatLngBounds bounds;
      if (_responderLocation!.latitude > _reporterLocation!.latitude &&
          _responderLocation!.longitude > _reporterLocation!.longitude) {
        bounds = LatLngBounds(southwest: _reporterLocation!, northeast: _responderLocation!);
      } else if (_responderLocation!.longitude > _reporterLocation!.longitude) {
        bounds = LatLngBounds(
            southwest: LatLng(_responderLocation!.latitude, _reporterLocation!.longitude),
            northeast: LatLng(_reporterLocation!.latitude, _responderLocation!.longitude));
      } else if (_responderLocation!.latitude > _reporterLocation!.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(_reporterLocation!.latitude, _responderLocation!.longitude),
            northeast: LatLng(_responderLocation!.latitude, _reporterLocation!.longitude));
      } else {
        bounds = LatLngBounds(southwest: _responderLocation!, northeast: _reporterLocation!);
      }
      
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_responderLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_responderLocation!, 15));
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  final List<Unit> _units = [
    Unit(
      id: "UNIT-001",
      name: "Officer Rehan Ahmed",
      type: "Police",
      badgeNumber: "PB-45218",
      status: "On Route",
      estimatedTime: "3 min",
      distance: "0.8 km",
      color: Colors.green,
      latitude: 31.5204,
      longitude: 74.3587,
    ),
    Unit(
      id: "UNIT-002",
      name: "General Hospital Ambulance",
      type: "Ambulance",
      badgeNumber: "AMB-78910",
      status: "En Route",
      estimatedTime: "7 min",
      distance: "1.9 km",
      color: Colors.red,
      latitude: 31.5249,
      longitude: 74.3632,
    ),
    Unit(
      id: "UNIT-003",
      name: "Rescue 1122 Unit",
      type: "Rescue",
      badgeNumber: "RES-12345",
      status: "Standby",
      estimatedTime: "10 min",
      distance: "3.2 km",
      color: Colors.orange,
      latitude: 31.5189,
      longitude: 74.3556,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<Unit> filteredUnits = _units.where((unit) {
      return _selectedTeam == "All" || unit.type == _selectedTeam;
    }).toList();

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
              _infoPanel(filteredUnits),
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
                      ? "Real-time location sharing enabled"
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
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _responderLocation ?? const LatLng(0, 0),
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitMapBounds();
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: {
                  if (_responderLocation != null)
                    Marker(
                      markerId: const MarkerId('responder'),
                      position: _responderLocation!,
                      infoWindow: const InfoWindow(title: 'You'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    ),
                  if (_reporterLocation != null)
                    Marker(
                      markerId: const MarkerId('reporter'),
                      position: _reporterLocation!,
                      infoWindow: const InfoWindow(title: 'Emergency Location'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                },
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

  Widget _infoPanel(List<Unit> units) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Emergency Units",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _teamFilterButton("All"),
                    const SizedBox(width: 8),
                    _teamFilterButton("Police"),
                    const SizedBox(width: 8),
                    _teamFilterButton("Ambulance"),
                    const SizedBox(width: 8),
                    _teamFilterButton("Rescue"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Estimated Arrival and Distance
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  label: "Nearest Unit",
                  value: units.isNotEmpty ? units.first.estimatedTime : "N/A",
                  icon: Icons.timer_outlined,
                ),
              ),
              Expanded(
                child: _infoTile(
                  label: "Total Distance",
                  value: units.isNotEmpty ? "2.4 km" : "0 km",
                  icon: Icons.route_outlined,
                ),
              ),
              Expanded(
                child: _infoTile(
                  label: "Active Units",
                  value: "${units.length}",
                  icon: Icons.group_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Units List with fixed height
          SizedBox(
            height: 180, // Fixed height for units list
            child: units.isEmpty
                ? _buildEmptyUnits()
                : ListView.builder(
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _unitTile(units[index]),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _teamFilterButton(String team) {
    bool isSelected = _selectedTeam == team;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTeam = team;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          team,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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

  Widget _unitTile(Unit unit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: unit.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            unit.type == "Police" ? Icons.local_police_outlined :
            unit.type == "Ambulance" ? Icons.local_hospital_outlined :
            Icons.security_outlined,
            color: unit.color,
            size: 20,
          ),
        ),
        title: Text(
          unit.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              "${unit.type} · ${unit.badgeNumber}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(unit.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    unit.status,
                    style: TextStyle(
                      color: _getStatusColor(unit.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              unit.estimatedTime,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              unit.distance,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () {
          _showUnitDetails(unit);
        },
      ),
    );
  }

  Widget _buildEmptyUnits() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            color: Colors.grey[300],
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            "No Units Available",
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Try changing your filter",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
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

  void _showUnitDetails(Unit unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: unit.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    unit.type == "Police" ? Icons.local_police_outlined :
                    unit.type == "Ambulance" ? Icons.local_hospital_outlined :
                    Icons.security_outlined,
                    color: unit.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${unit.type} · ${unit.badgeNumber}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Add more details here
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "On Scene":
        return Colors.green;
      case "On Route":
      case "En Route":
        return Colors.orange;
      case "Standby":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class Unit {
  final String id;
  final String name;
  final String type;
  final String badgeNumber;
  final String status;
  final String estimatedTime;
  final String distance;
  final Color color;
  final double latitude;
  final double longitude;

  Unit({
    required this.id,
    required this.name,
    required this.type,
    required this.badgeNumber,
    required this.status,
    required this.estimatedTime,
    required this.distance,
    required this.color,
    required this.latitude,
    required this.longitude,
  });
}
