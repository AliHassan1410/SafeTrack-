import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/responder/responderBottom/responderBottomBarNavigation.dart';
import 'package:safetrack/services/incident_services.dart';
import 'package:safetrack/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponderIncidentsPage extends StatefulWidget {
  const ResponderIncidentsPage({super.key});

  @override
  State<ResponderIncidentsPage> createState() => _ResponderIncidentsPageState();
}

class _ResponderIncidentsPageState extends State<ResponderIncidentsPage> {
  List<Incident> _incidents = [];
  bool _isLoading = false;
  Position? _currentPosition;
  late IO.Socket _socket;

  String _selectedFilter = "All"; // All, Pending, Assigned, In Progress
  String _selectedPriority = "All"; // All, High, Medium, Low

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initSocket();
  }

  void _initSocket() {
    final String url = IncidentService.baseUrl.replaceAll('/api', '');
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      print('Incidents Page Connected to Socket');
    });

    _socket.on('new_incident', (data) {
      print('New Incident Received via Socket');
      _fetchData();
    });

    _socket.on('incident_updated', (data) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        }
      }

      final type = AuthService().currentUser?.responderType ?? "medical";
      
      List<dynamic> nearby = [];
      if (_currentPosition != null) {
        nearby = await IncidentService.getNearbyIncidents(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          type: type,
        );
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to fetch your location. Please enable GPS to see nearby incidents.'), backgroundColor: Colors.red),
           );
        }
      }
      
      final assigned = await IncidentService.getAssignedIncidents();
      
      List<Incident> parsedIncidents = [];
      
      // Parse nearby (status: Pending)
      for (var inc in nearby) {
         if (inc['status'] != 'pending') continue; // only show pending
         parsedIncidents.add(_parseIncident(inc, "Pending"));
      }
      
      // Parse assigned (status: Assigned or In Progress)
      for (var inc in assigned) {
         String st = inc['status'] == 'accepted' ? 'Assigned' : 
                     inc['status'] == 'completed' ? 'Completed' : 'In Progress';
         parsedIncidents.add(_parseIncident(inc, st));
      }
      
      if (mounted) {
        setState(() {
          _incidents = parsedIncidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching incidents: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Incident _parseIncident(Map<String, dynamic> data, String status) {
    final idStr = data['_id']?.toString() ?? "0000";
    final incCode = "INC-${idStr.length >= 4 ? idStr.substring(idStr.length - 4).toUpperCase() : idStr}";
    final title = data['title'] ?? 'Emergency';
    final description = data['description'] ?? 'No description available.';
    
    String locStr = 'Unknown Location';
    if (data['location'] != null && data['location']['coordinates'] != null) {
       final coords = data['location']['coordinates'];
       locStr = '${coords[1].toStringAsFixed(4)}, ${coords[0].toStringAsFixed(4)}';
    }

    String distStr = "Near";
    if (_currentPosition != null && data['location'] != null && data['location']['coordinates'] != null) {
       final coords = data['location']['coordinates'];
       double dist = Geolocator.distanceBetween(
           _currentPosition!.latitude, _currentPosition!.longitude, 
           coords[1], coords[0]
       );
       distStr = "${(dist / 1000).toStringAsFixed(1)} km";
    }

    String timeText = "Unknown Time";
    if (data['createdAt'] != null) {
       try {
         final dt = DateTime.parse(data['createdAt']).toLocal();
         final ampm = dt.hour >= 12 ? 'PM' : 'AM';
         int hourStr = dt.hour % 12;
         if (hourStr == 0) hourStr = 12;
         timeText = "$hourStr:${dt.minute.toString().padLeft(2, '0')} $ampm";
       } catch (e) {}
    }

    String repName = "Unknown Reporter";
    String repPhone = "No Phone";
    if (data['reporter'] != null && data['reporter'] is Map) {
       repName = data['reporter']['name'] ?? "Unknown Reporter";
       repPhone = data['reporter']['phone'] ?? "No Phone";
    }

    return Incident(
      id: idStr,
      displayId: incCode,
      title: title,
      location: locStr,
      priority: "HIGH", 
      priorityColor: AppColors.secondary,
      distance: distStr,
      reportedTime: timeText,
      description: description,
      status: status,
      reporterName: repName,
      reporterPhone: repPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter incidents based on selections
    List<Incident> filteredIncidents = _incidents.where((incident) {
      bool matchesStatus = _selectedFilter == "All" || incident.status == _selectedFilter;
      bool matchesPriority = _selectedPriority == "All" || 
          (_selectedPriority == "High" && incident.priority == "HIGH") ||
          (_selectedPriority == "Medium" && incident.priority == "MEDIUM") ||
          (_selectedPriority == "Low" && incident.priority == "LOW");
      return matchesStatus && matchesPriority;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Incidents & Emergencies",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            onPressed: () {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Incidents refreshed"),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // Incidents Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredIncidents.length} Incidents Found",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showFilterDialog(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.filter_list_outlined, size: 18),
                      SizedBox(width: 4),
                      Text(
                        "Filter",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Incidents List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : filteredIncidents.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredIncidents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _incidentCard(filteredIncidents[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const ResponderBottomBarNavigation(currentIndex: 1),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Filters",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("All", _selectedFilter == "All"),
                _filterChip("Pending", _selectedFilter == "Pending"),
                _filterChip("Assigned", _selectedFilter == "Assigned"),
                _filterChip("In Progress", _selectedFilter == "In Progress"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Priority Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _priorityChip("All", _selectedPriority == "All", Colors.grey),
                _priorityChip("High", _selectedPriority == "High", Colors.red),
                _priorityChip("Medium", _selectedPriority == "Medium", Colors.orange),
                _priorityChip("Low", _selectedPriority == "Low", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : "All";
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String label, bool isSelected, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPriority = selected ? label : "All";
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: color.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _incidentCard(Incident incident) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Priority and ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: incident.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        incident.priority == "HIGH" ? Icons.warning_amber_rounded : 
                               incident.priority == "MEDIUM" ? Icons.warning_outlined : Icons.info_outline,
                        color: incident.priorityColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        incident.priority,
                        style: TextStyle(
                          color: incident.priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  incident.displayId,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              incident.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              incident.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Location and Distance
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    incident.location,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.near_me_outlined, color: Colors.grey[500], size: 16),
                const SizedBox(width: 4),
                Text(
                  incident.distance,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time and Status
            Row(
              children: [
                Icon(Icons.access_time_outlined, color: Colors.grey[500], size: 16),
                const SizedBox(width: 4),
                Text(
                  incident.reportedTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(incident.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incident.status,
                    style: TextStyle(
                      color: _getStatusColor(incident.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (incident.status == "Pending") {
                         _handleAcceptIncident(incident);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: incident.status == "Pending" 
                          ? AppColors.primary 
                          : Colors.grey[300],
                      foregroundColor: incident.status == "Pending" 
                          ? Colors.white 
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      incident.status == "Pending" ? "Accept" : "Accepted",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _handleViewDetails(incident);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    icon: Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    label: const Text(
                      "Details",
                      style: TextStyle(color: Colors.black87),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            color: Colors.grey[300],
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            "No Incidents Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try changing your filters",
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = "All";
                _selectedPriority = "All";
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Reset Filters"),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Advanced Filters"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add more filter options here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptIncident(Incident incident) async {
    if (incident.status == "Pending") {
      setState(() => _isLoading = true);
      try {
        await IncidentService.acceptIncident(incident.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Incident ${incident.displayId} accepted"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchData(); // Refreshes the list to move it to assigned
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to accept incident"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _handleViewDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildIncidentDetails(incident),
    );
  }

  Widget _buildIncidentDetails(Incident incident) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Text(incident.displayId, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    incident.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(incident.description, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            const Text("Reporter Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(incident.reporterName, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(incident.reporterPhone, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Incident Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(incident.location, style: const TextStyle(fontSize: 16))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.near_me, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text("${incident.distance} from you", style: const TextStyle(fontSize: 16))),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Reported Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(incident.reportedTime, style: const TextStyle(fontSize: 16)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Assigned":
        return AppColors.primary;
      case "In Progress":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class Incident {
  final String id;
  final String displayId;
  final String title;
  final String location;
  final String priority;
  final Color priorityColor;
  final String distance;
  final String reportedTime;
  final String description;
  String status;
  final String reporterName;
  final String reporterPhone;

  Incident({
    required this.id,
    required this.displayId,
    required this.title,
    required this.location,
    required this.priority,
    required this.priorityColor,
    required this.distance,
    required this.reportedTime,
    required this.description,
    required this.status,
    required this.reporterName,
    required this.reporterPhone,
  });
}
