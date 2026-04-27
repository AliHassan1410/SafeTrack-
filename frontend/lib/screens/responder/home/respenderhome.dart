import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/responder/responderBottom/responderBottomBarNavigation.dart';
import '../../chat/chat_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safetrack/services/auth_service.dart';
import 'package:safetrack/services/incident_services.dart';
import 'package:safetrack/screens/responder/responderBottom/nagivation.dart';


class ResponderHome extends StatefulWidget {
  const ResponderHome({super.key});

  @override
  State<ResponderHome> createState() => _ResponderHomeState();
}

class _ResponderHomeState extends State<ResponderHome> {
  bool _isAvailable = true;
  int _assignedCount = 0;
  int _pendingCount = 0;
  int _completedCount = 0;
  int _notificationCount = 5;

  bool _isLoading = false;
  List<dynamic> _incidents = [];
  Map<String, dynamic>? _activeIncident;
  Position? _currentPosition;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = "Location Services Disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationError = "Location Permission Denied");
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final type = AuthService().currentUser?.responderType ?? "medical";
      
      final incidents = await IncidentService.getNearbyIncidents(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        type: type,
      );

      final assignedIncidents = await IncidentService.getAssignedIncidents();

      if (mounted) {
        setState(() {
          _incidents = incidents;
          _pendingCount = incidents.length;
          _assignedCount = assignedIncidents.where((i) => i['status'] == 'accepted').length;
          _completedCount = assignedIncidents.where((i) => i['status'] == 'completed').length;
          
          final acceptedIncidents = assignedIncidents.where((i) => i['status'] == 'accepted').toList();
          _activeIncident = acceptedIncidents.isNotEmpty ? acceptedIncidents.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = "Error fetching data: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _availabilityCard(),
                    const SizedBox(height: 16),
                    _statsRow(),
                    const SizedBox(height: 20),
                    if (_activeIncident != null) ...[
                      _activeAssignment(),
                      const SizedBox(height: 20),
                    ],
                    _nearbyIncidents(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ResponderBottomBarNavigation(currentIndex: 0),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isAvailable ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isAvailable ? "ON DUTY" : "OFF DUTY",
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AuthService().currentUser?.name ?? "Responder Profile",
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Unit: ${AuthService().currentUser?.responderType?.toUpperCase() ?? 'UNKNOWN'}",
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Icons Row
          Row(
            children: [
              // Message Icon (New)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(
                            receiverId: 'reporter_id_123', // Dynamic in real app
                            receiverName: 'Recent Reporter',
                            userRole: 'responder',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.message_outlined,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Professional Notification Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showProfessionalNotification(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Notification Badge (Professional Design)
                  if (_notificationCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _notificationCount > 9 ? "9+" : "$_notificationCount",
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Professional Notification Popup
  void _showProfessionalNotification(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _notificationCount = 0;
                            });
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.check_circle_outline,
                              color: AppColors.textSecondary),
                          tooltip: "Mark all as read",
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Notification List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(0),
                  children: [
                    // Today Section
                    _notificationSection("Today"),
                    
                    _professionalNotificationItem(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.orange,
                      title: "New Emergency Alert",
                      subtitle: "Major accident reported near Liberty Market Chowk. Multiple casualties.",
                      time: "10:24 AM",
                      isUrgent: true,
                      isUnread: true,
                    ),
                    
                    _professionalNotificationItem(
                      icon: Icons.assignment_rounded,
                      iconColor: AppColors.primary,
                      title: "Assignment Update",
                      subtitle: "Your current assignment priority has been elevated to HIGH",
                      time: "09:45 AM",
                      isUnread: true,
                    ),
                    
                    _professionalNotificationItem(
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.green,
                      title: "Location Update Required",
                      subtitle: "Please confirm your current location for dispatch",
                      time: "08:30 AM",
                      isUnread: true,
                    ),
                    
                    // Yesterday Section
                    _notificationSection("Yesterday"),
                    
                    _professionalNotificationItem(
                      icon: Icons.verified_rounded,
                      iconColor: Colors.teal,
                      title: "Report Verified",
                      subtitle: "Incident report #INC-2045 has been verified and closed",
                      time: "06:15 PM",
                      isUnread: false,
                    ),
                    
                    _professionalNotificationItem(
                      icon: Icons.group_rounded,
                      iconColor: Colors.purple,
                      title: "Team Assignment",
                      subtitle: "You have been assigned to Rescue Team Alpha",
                      time: "03:45 PM",
                      isUnread: false,
                    ),
                    
                    _professionalNotificationItem(
                      icon: Icons.update_rounded,
                      iconColor: Colors.blueGrey,
                      title: "System Update",
                      subtitle: "Emergency response protocols have been updated",
                      time: "11:20 AM",
                      isUnread: false,
                    ),
                    
                    // This Week Section
                    _notificationSection("This Week"),
                    
                    _professionalNotificationItem(
                      icon: Icons.school,
                      iconColor: Colors.indigo,
                      title: "Training Session",
                      subtitle: "Complete the new emergency response training module",
                      time: "Monday, 2:00 PM",
                      isUnread: false,
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationSection(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _professionalNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    bool isUrgent = false,
    bool isUnread = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.1), width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (isUrgent)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "URGENT",
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_outlined,
                    color: AppColors.textSecondary.withOpacity(0.4), size: 14),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (isUnread) {
            setState(() {
              _notificationCount = _notificationCount > 0 ? _notificationCount - 1 : 0;
            });
          }
        },
      ),
    );
  }

  Widget _availabilityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.circle_notifications_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Availability Status",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable ? "Available for emergencies" : "Currently off duty",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _StatBox(
          title: "Assigned",
          value: "$_assignedCount",
          color: AppColors.primary,
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(width: 12),
        _StatBox(
          title: "Pending",
          value: "$_pendingCount",
          color: const Color(0xFFFF9800),
          icon: Icons.pending_outlined,
        ),
        const SizedBox(width: 12),
        _StatBox(
          title: "Completed",
          value: "$_completedCount",
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }

  Widget _activeAssignment() {
    if (_activeIncident == null) return const SizedBox.shrink();
    
    final idStr = _activeIncident!['_id']?.toString() ?? "0000";
    final incCode = "INC-${idStr.length >= 4 ? idStr.substring(idStr.length - 4).toUpperCase() : idStr}";
    final title = _activeIncident!['title'] ?? 'Incident';
    final description = _activeIncident!['description'] ?? 'No description available.';
    
    String locationText = "Location unrecorded";
    if (_activeIncident!['location'] != null && _activeIncident!['location']['coordinates'] != null) {
        final coords = _activeIncident!['location']['coordinates'];
        // coordinates are [lng, lat]
        if (coords.length >= 2) {
           locationText = "Lat: ${coords[1].toStringAsFixed(4)}, Lng: ${coords[0].toStringAsFixed(4)}";
        }
    }

    String timeText = "Unknown Time";
    if (_activeIncident!['createdAt'] != null) {
       try {
         final dt = DateTime.parse(_activeIncident!['createdAt']).toLocal();
         final ampm = dt.hour >= 12 ? 'PM' : 'AM';
         int hourStr = dt.hour % 12;
         if (hourStr == 0) hourStr = 12;
         timeText = "$hourStr:${dt.minute.toString().padLeft(2, '0')} $ampm, ${dt.day}/${dt.month}/${dt.year}";
       } catch (e) { }
    }

    String reporterName = "Unknown Reporter";
    String reporterPhone = "No Phone";
    if (_activeIncident!['reporter'] != null && _activeIncident!['reporter'] is Map) {
       reporterName = _activeIncident!['reporter']['name'] ?? "Unknown Reporter";
       reporterPhone = _activeIncident!['reporter']['phone'] ?? "No Phone";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Active Assignment",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "VIEW ALL",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "HIGH PRIORITY",
                      style: TextStyle(
                        color: AppColors.secondary.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    incCode,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    reporterName,
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    reporterPhone,
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationText,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    timeText,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Trackreporter()),
                          );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.navigation, size: 20),
                      label: const Text(
                        "Navigate",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                         _showIncidentDetails(
                            incCode, title, description, locationText, timeText, reporterName, reporterPhone
                         );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                      ),
                      icon: Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                      label: const Text(
                        "Details",
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIncidentDetails(String code, String title, String description, String location, String time, String repName, String repPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text(code, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            const Text("Reporter Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(repName, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(repPhone, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Incident Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(location, style: const TextStyle(fontSize: 16))),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Reported Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _nearbyIncidents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Nearby Incidents",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else
              TextButton(
                onPressed: _fetchData,
                child: const Text(
                  "REFRESH",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_locationError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_locationError, style: const TextStyle(color: Colors.red)),
          )
        else if (!_isLoading && _incidents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text("No nearby incidents found.")),
          )
        else
          ..._incidents.map((incident) {
            final id = incident['_id']?.toString() ?? "";
            final title = incident['title'] ?? 'Emergency';
            
            String locStr = 'Unknown Location';
            if (incident['location'] != null && incident['location']['coordinates'] != null) {
               final coords = incident['location']['coordinates'];
               locStr = '${coords[1].toStringAsFixed(4)}, ${coords[0].toStringAsFixed(4)}';
            }

            String distanceStr = "Near";
            if (_currentPosition != null && incident['location'] != null && incident['location']['coordinates'] != null) {
              final incidentLng = incident['location']['coordinates'][0];
              final incidentLat = incident['location']['coordinates'][1];
              final distMeters = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude, 
                incidentLat, incidentLng
              );
              distanceStr = "${(distMeters / 1000).toStringAsFixed(1)} km";
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _incidentTile(
                id: id,
                priority: "HIGH",
                priorityColor: AppColors.secondary,
                title: title,
                location: locStr,
                distance: distanceStr,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _incidentTile({
    required String id,
    required String priority,
    required Color priorityColor,
    required String title,
    required String location,
    required String distance,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              location,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (id.isNotEmpty) {
                        try {
                           setState(() => _isLoading = true);
                           await IncidentService.acceptIncident(id);
                           await _fetchData();
                        } catch(e) {
                           // Handle error
                           setState(() => _isLoading = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Accept",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (id.isNotEmpty) {
                         setState(() {
                            // Dummy decline by simply removing from list locally
                            _incidents.removeWhere((i) => i['_id'] == id);
                         });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                    ),
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
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

// ================= STAT BOX =================
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
