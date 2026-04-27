import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:safetrack/utils/app_colors.dart';
import '../bottomNav/bottom_nav_bar.dart';

class TrackResponder extends StatefulWidget {
  final Map<String, dynamic>? activeIncident;
  const TrackResponder({super.key, this.activeIncident});

  @override
  State<TrackResponder> createState() => _TrackResponderState();
}

class _TrackResponderState extends State<TrackResponder> {
  GoogleMapController? _mapController;
  LatLng? _reporterLocation;
  LatLng? _responderLocation;
  late IO.Socket _socket;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initSocket();
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
      _fitMapBounds();
    }
  }

  void _initSocket() {
    // Determine the incident ID
    String incidentId = widget.activeIncident?['_id'] ?? "test_incident_id";

    // Initialize Socket.IO connection to Backend
    // Use 10.0.2.2 for Android Emulator, or your local network IP for real devices.
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      print('Connected to Socket');
      // Join the tracking room for this specific incident
      _socket.emit('join_incident', incidentId);
    });
    
    _socket.on('location_update', (data) {
      print("Responder Location Updated: $data");
      if (mounted) {
        setState(() {
          _responderLocation = LatLng(data['lat'], data['lng']);
        });
        _fitMapBounds();
      }
    });
  }

  void _fitMapBounds() {
    if (_mapController == null) return;

    if (_reporterLocation != null && _responderLocation != null) {
      LatLngBounds bounds;
      if (_reporterLocation!.latitude > _responderLocation!.latitude &&
          _reporterLocation!.longitude > _responderLocation!.longitude) {
        bounds = LatLngBounds(southwest: _responderLocation!, northeast: _reporterLocation!);
      } else if (_reporterLocation!.longitude > _responderLocation!.longitude) {
        bounds = LatLngBounds(
            southwest: LatLng(_reporterLocation!.latitude, _responderLocation!.longitude),
            northeast: LatLng(_responderLocation!.latitude, _reporterLocation!.longitude));
      } else if (_reporterLocation!.latitude > _responderLocation!.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(_responderLocation!.latitude, _reporterLocation!.longitude),
            northeast: LatLng(_reporterLocation!.latitude, _responderLocation!.longitude));
      } else {
        bounds = LatLngBounds(southwest: _reporterLocation!, northeast: _responderLocation!);
      }
      
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_reporterLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_reporterLocation!, 15));
    }
  }

  @override
  void dispose() {
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
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _reporterLocation ?? const LatLng(0, 0),
                          zoom: 14.0,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitMapBounds();
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: {
                          if (_reporterLocation != null)
                            Marker(
                              markerId: const MarkerId('reporter'),
                              position: _reporterLocation!,
                              infoWindow: const InfoWindow(title: 'Your Location'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                          if (_responderLocation != null)
                            Marker(
                              markerId: const MarkerId('responder'),
                              position: _responderLocation!,
                              infoWindow: const InfoWindow(title: 'Responder'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                            ),
                        },
                      ),
                      
                      // Floating ETA & Distance card
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: _buildETAAndDistance(),
                      ),
                      
                      // Floating Top Refresh Button
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
            "GPS Active · Live map connection established. "
            "Responder's movements will automatically update here.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETAAndDistance() {
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
                    Text(_responderLocation != null ? "Tracking..." : "Waiting...", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    Text(_responderLocation != null ? "Updating..." : "--", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
