import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/services/incident_services.dart';

import '../bottomNav/bottom_nav_bar.dart';

class ResponderHistory extends StatefulWidget {
  const ResponderHistory({super.key});

  @override
  State<ResponderHistory> createState() => _ResponderHistoryState();
}

class _ResponderHistoryState extends State<ResponderHistory> {
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  /// GET DATA FROM NODE.JS BACKEND
  Future<void> fetchReports() async {
    try {
      final incidents = await IncidentService.getIncidents();
      if (mounted) {
        setState(() {
          reports = incidents;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              "No incident history found",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final incident = reports[index];
                          return _buildIncidentCard(incident);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Text(
                "Incident History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Track all your past reports and standard alerts.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// FILTER (STATIC)
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          const Text(
            "All Reports",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  "Filter",
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// INCIDENT CARD
  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final status = incident['status'] ?? 'Pending';
    final priority = incident['priority'] ?? 'Medium';

    String dateStr = "Just now";

    if (incident['createdAt'] != null) {
      try {
        dateStr = DateFormat('MMM d, y · h:mm a')
            .format(DateTime.parse(incident['createdAt']).toLocal());
      } catch (_) {}
    }

    Color priorityColor = priority == "High" ? AppColors.secondary : AppColors.accent;
    Color statusColor = status == "Pending" ? Colors.orange : AppColors.primary;

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
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "REF-${incident['_id'] != null ? incident['_id'].substring(incident['_id'].length - 4).toUpperCase() : 'N/A'}",
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
              incident['title'] ?? incident['type'] ?? 'No Title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    incident['description'] ?? 'Unknown Location',
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}