import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/services/auth_service.dart';
import 'package:safetrack/services/incident_services.dart';
import 'package:safetrack/services/cloudinary_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../bottomNav/bottom_nav_bar.dart';
import '../bottomNav/report.dart';
import '../bottomNav/track.dart';
import '../../chat/chat_screen.dart';

class ReporterHome extends StatefulWidget {
  const ReporterHome({super.key});

  @override
  State<ReporterHome> createState() => _ReporterHomeState();
}

class _ReporterHomeState extends State<ReporterHome>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _blinkController;
  late Animation<Color?> _blinkAnimation;
  
  String _userName = "Loading...";
  String _currentLocation = "Turning on GPS...";
  String? _profileImageUrl;
  
  List<dynamic> _recentIncidents = [];
  Map<String, dynamic>? _activeIncident;
  bool _isLoadingIncidents = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _getCurrentLocation();
    _fetchIncidents();
    
    // Setup blinking animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);
    
    _blinkAnimation = ColorTween(
      begin: AppColors.secondary,
      end: AppColors.secondary.withOpacity(0.8),
    ).animate(_blinkController);
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();
    await authService.init(); 
    if (mounted) {
      setState(() {
        final name = authService.currentUser?.name;
        if (name != null) {
          // Get only the first name (everything before the first space)
          _userName = name.split(' ').first;
        } else {
          _userName = "Guest User";
        }
      });
    }
  }

  Future<void> _fetchIncidents() async {
    try {
      final incidents = await IncidentService.getIncidents();
      if (mounted) {
        setState(() {
          _recentIncidents = incidents;
          try {
             _activeIncident = _recentIncidents.firstWhere(
                (i) => i['status'] == 'accepted' || i['status'] == 'pending'
             );
          } catch(e) {
             _activeIncident = null;
          }
          _isLoadingIncidents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingIncidents = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _currentLocation = "Location Disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _currentLocation = "Permission Denied");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _currentLocation = "Permission Permanently Denied");
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      // Since we don't have geocoding, show coords or generic text
      if (mounted) {
        setState(() {
          _currentLocation = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocation = "Error getting location");
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 20),

              // Emergency Button with Blinking Effect
              _buildEmergencyButton(),
              const SizedBox(height: 20),

              // Active Incident
              if (_activeIncident != null) ...[
                _activeIncidentCard(),
                const SizedBox(height: 20),
              ],

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Recent Reports
              _buildRecentReports(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  // Header with User Info
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.background,
                  backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                  child: _profileImageUrl == null ? const Icon(Icons.person, color: AppColors.primary, size: 30) : null,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assalamu Alaikum,",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _notificationBadge(),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Current Location",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentLocation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationBadge() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(
              receiverId: 'responder_id_123', // This should be dynamic in a real app
              receiverName: 'Official Responder',
              userRole: 'reporter',
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Emergency Button with Blinking Effect
  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => const ReportIncidentScreen(initialTabIndex: 0)),
             ).then((_) {
               _fetchIncidents();
             });
        },
        child: AnimatedBuilder(
          animation: _blinkController,
          builder: (context, child) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _blinkAnimation.value ?? AppColors.secondary,
                    const Color(0xFFB91C1C),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_blinkAnimation.value ?? AppColors.secondary).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 20),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EMERGENCY HELP",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "Press to report immediately",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Active Incident Card
  Widget _activeIncidentCard() {
    if (_activeIncident == null) return const SizedBox.shrink();
    
    final idStr = _activeIncident!['_id']?.toString() ?? "0000";
    final incCode = "INC-${idStr.length >= 4 ? idStr.substring(idStr.length - 4).toUpperCase() : idStr}";
    final title = _activeIncident!['title'] ?? 'Incident';
    final status = _activeIncident!['status'] ?? 'pending';
    
    String locationText = "Location unrecorded";
    if (_activeIncident!['location'] != null && _activeIncident!['location']['coordinates'] != null) {
        final coords = _activeIncident!['location']['coordinates'];
        // coordinates are [lng, lat]
        if (coords.length >= 2) {
           locationText = "Lat: ${coords[1].toStringAsFixed(4)}, Lng: ${coords[0].toStringAsFixed(4)}";
        }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: AppColors.accent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("ETA: Calculating...", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationText,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: status == 'accepted' ? 0.6 : 0.2,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(status == 'accepted' ? AppColors.success : Colors.orange),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrackResponder()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "TRACK",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // Quick Actions Grid
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Quick Submission",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickItem(Icons.text_snippet_rounded, "Text", const Color(0xFF6366F1), 0),
              _buildQuickItem(Icons.add_a_photo_rounded, "Image", const Color(0xFFF59E0B), 1),
              _buildQuickItem(Icons.keyboard_voice_rounded, "Voice", const Color(0xFF10B981), 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickItem(IconData icon, String label, Color color, int tabIndex) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleQuickAction(label),
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- QUICK ACTIONS LOGIC ---

  Future<void> _submitQuickIncident(String title, String description, String type, {String? imageUrl}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await IncidentService.createIncident(
        title: title,
        type: type,
        description: description,
        lat: position.latitude,
        lng: position.longitude,
        imageUrl: imageUrl,
      );
      if (mounted) Navigator.pop(context); // close loader
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Quick Report Submitted")));
        _fetchIncidents();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loader
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
      }
    }
  }

  void _handleQuickAction(String actionType) {
    if (actionType == "Text") {
      _showQuickTextDialog();
    } else if (actionType == "Image") {
      _handleQuickImage();
    } else if (actionType == "Voice") {
      _showQuickVoiceDialog();
    }
  }

  void _showQuickTextDialog() {
    final TextEditingController textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Quick Text Report"),
          content: TextField(
            controller: textCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Describe the incident quickly...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.isEmpty) return;
                Navigator.pop(context);
                _submitQuickIncident("Quick Report", textCtrl.text, "medical");
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleQuickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text("Uploading Photo...", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );

    try {
      final bytes = await image.readAsBytes();
      String imageUrl = await CloudinaryService.uploadImage(
        bytes: bytes,
        fileName: image.name,
        folder: 'quick_reports',
      );
      if (mounted) Navigator.pop(context); // close uploader
      _submitQuickIncident("Photo Report", "Submitted a photo evidence.", "medical", imageUrl: imageUrl);
    } catch (e) {
      if (mounted) Navigator.pop(context); // close uploader
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
    }
  }

  void _showQuickVoiceDialog() {
    // We will use a StatefulWidget inside the dialog for mic animation & state
    showDialog(
      context: context,
      builder: (context) => const QuickVoiceDialog(),
    ).then((result) {
      if (result != null && result is String && result.isNotEmpty) {
        _submitQuickIncident("Voice Report", result, "medical");
      }
    });
  }

  // Recent Reports Section
  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                "Recent Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _fetchIncidents();
                },
                child: const Text(
                  "Refresh",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingIncidents
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _recentIncidents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Center(
                      child: Text(
                        "No recent reports",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: _recentIncidents.map((incident) {
                      String id = incident['_id'] ?? '0000';
                      String code = "INC-${id.length >= 4 ? id.substring(id.length - 4).toUpperCase() : id}";
                      
                      String locationText = "Location unrecorded";
                      if (incident['location'] != null && incident['location']['lat'] != null) {
                         locationText = "Lat: ${incident['location']['lat'].toStringAsFixed(4)}, Lng: ${incident['location']['lng'].toStringAsFixed(4)}";
                      }
                      
                      return _buildReportCard(
                        priority: "HIGH",
                        code: code,
                        title: incident['title'] ?? incident['type'] ?? 'Incident',
                        location: locationText,
                        status: incident['status'] ?? "Pending",
                        statusColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReportCard({
    required String priority,
    required String code,
    required String title,
    required String location,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priority == "HIGH" 
                      ? AppColors.secondary.withOpacity(0.1) 
                      : AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priority == "HIGH" ? AppColors.secondary : AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  code,
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickVoiceDialog extends StatefulWidget {
  const QuickVoiceDialog({super.key});

  @override
  State<QuickVoiceDialog> createState() => _QuickVoiceDialogState();
}

class _QuickVoiceDialogState extends State<QuickVoiceDialog> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = "Press the mic and start speaking";
  bool _hasSpeech = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _hasSpeech = await _speech.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Speech initialization failed: $e");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Voice Report", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _text,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _hasSpeech ? _listen : null,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: _isListening ? Colors.red : AppColors.primary,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? "Listening..." : "Tap to speak",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isListening) _speech.stop();
            Navigator.pop(context);
          },
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isListening) _speech.stop();
            if (_text.isEmpty || _text == "Press the mic and start speaking") return;
            Navigator.pop(context, _text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text("Submit", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
