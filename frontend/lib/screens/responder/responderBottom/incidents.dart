import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/responder/responderBottom/responderBottomBarNavigation.dart';

class ResponderIncidentsPage extends StatefulWidget {
  const ResponderIncidentsPage({super.key});

  @override
  State<ResponderIncidentsPage> createState() => _ResponderIncidentsPageState();
}

class _ResponderIncidentsPageState extends State<ResponderIncidentsPage> {
  final List<Incident> _incidents = [
    Incident(
      id: "INC-001",
      title: "Road Accident on Ring Road",
      location: "Ring Road, Near Thokar Niaz Baig, Lahore",
      priority: "HIGH",
      priorityColor: Colors.red,
      distance: "3.2 km",
      reportedTime: "30 min ago",
      description: "Two vehicles collision. Multiple injuries reported.",
      status: "Pending",
    ),
    Incident(
      id: "INC-002",
      title: "Mobile Snatching Incident",
      location: "Anarkali Bazaar, Near Food Street",
      priority: "MEDIUM",
      priorityColor: Colors.orange,
      distance: "2.3 km",
      reportedTime: "1 hour ago",
      description: "Snatching reported near Liberty Market.",
      status: "Assigned",
    ),
    Incident(
      id: "INC-003",
      title: "Medical Emergency - Heart Attack",
      location: "House 45, Block D, Model Town",
      priority: "HIGH",
      priorityColor: Colors.red,
      distance: "1.8 km",
      reportedTime: "15 min ago",
      description: "Elderly patient with chest pain. Immediate response needed.",
      status: "Pending",
    ),
    Incident(
      id: "INC-004",
      title: "Fire Emergency - Building",
      location: "Commercial Plaza, Gulberg",
      priority: "HIGH",
      priorityColor: Colors.red,
      distance: "4.5 km",
      reportedTime: "45 min ago",
      description: "Multi-story building fire. Fire brigade en route.",
      status: "In Progress",
    ),
    Incident(
      id: "INC-005",
      title: "Domestic Violence Report",
      location: "Sector G, DHA Phase 5",
      priority: "MEDIUM",
      priorityColor: Colors.orange,
      distance: "5.1 km",
      reportedTime: "2 hours ago",
      description: "Neighbors reported loud arguments and possible violence.",
      status: "Pending",
    ),
  ];

  String _selectedFilter = "All"; // All, Pending, Assigned, In Progress
  String _selectedPriority = "All"; // All, High, Medium, Low

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
              // Refresh incidents
              _showRefreshDialog();
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
            child: filteredIncidents.isEmpty
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
                  incident.id,
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
                      _handleAcceptIncident(incident);
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

  void _showRefreshDialog() {
    // Simulate refresh
    setState(() {
      // In real app, you would fetch new data here
    });
    
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
  }

  void _handleAcceptIncident(Incident incident) {
    if (incident.status == "Pending") {
      setState(() {
        incident.status = "Assigned";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incident ${incident.id} accepted"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleViewDetails(Incident incident) {
    // Navigate to incident details page
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
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  incident.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Add more detailed information here
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
  final String title;
  final String location;
  final String priority;
  final Color priorityColor;
  final String distance;
  final String reportedTime;
  final String description;
  String status;

  Incident({
    required this.id,
    required this.title,
    required this.location,
    required this.priority,
    required this.priorityColor,
    required this.distance,
    required this.reportedTime,
    required this.description,
    required this.status,
  });
}
