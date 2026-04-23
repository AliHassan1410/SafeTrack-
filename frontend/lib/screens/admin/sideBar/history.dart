import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';

class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});

  final List<Map<String, String>> historyData = const [
    {
      "incident": "Road Accident on Ring Road",
      "urgency": "HIGH",
      "solvedBy": "Inspector Farhan Ali",
      "solverEmail": "farhan.ali@rescue1122.pk",
      "solveTime": "42 mins",
      "reporterName": "Ahmed Khan",
      "reporterPhone": "+92 311 5556666",
      "meetingTime": "10:35 AM",
    },
    {
      "incident": "bike accident",
      "urgency": "HIGH",
      "solvedBy": "Mr. Nawaz Sharif",
      "solverEmail": "Nawaz.chief@lahore.gov.pk",
      "solveTime": "1 hr 20 mins",
      "reporterName": "Fatima Bibi",
      "reporterPhone": "+92 322 7778899",
      "meetingTime": "02:10 PM",
    },
    {
      "incident": "Mobile Snatching Incident",
      "urgency": "MEDIUM",
      "solvedBy": "Constable Imran Khan",
      "solverEmail": "imran.khan@punjabpolice.gov.pk",
      "solveTime": "55 mins",
      "reporterName": "Hassan Raza",
      "reporterPhone": "+92 333 1234567",
      "meetingTime": "06:45 PM",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: const Text(
          "Incident History",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resolved Incidents",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Detailed record of completed incidents",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: historyData.length,
                itemBuilder: (context, index) {
                  return _historyCard(historyData[index]);
                },
              ),
            ),
          ],
        ),
      ),
      // Add the sidebar navigation as a widget (not as a sidebar overlay)
      drawer: SideBarNavigation(
        isOpen: true,
        onClose: () {},
        parentContext: context,
      ),
    );
  }

  // ================= HISTORY CARD =================
  Widget _historyCard(Map<String, String> data) {
    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INCIDENT + URGENCY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data["incident"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                _urgencyChip(data["urgency"]!),
              ],
            ),
            const SizedBox(height: 12),

            // SOLVER INFO
            _infoRow(
              "Solved By",
              "${data["solvedBy"]!}\n${data["solverEmail"]!}",
            ),

            // TIME TO SOLVE
            _infoRow("Total Time to Solve", data["solveTime"]!),

            const Divider(height: 28),

            // REPORTER DETAILS
            const Text(
              "Reporter Details",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            _infoRow("Name", data["reporterName"]!),
            _infoRow("Phone", data["reporterPhone"]!),
            _infoRow("Meeting Time", data["meetingTime"]!),
          ],
        ),
      ),
    );
  }

  // ================= REUSABLE WIDGETS =================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyChip(String urgency) {
    final Color color = urgency == "HIGH" ? Colors.red : Colors.orange;

    return Chip(
      label: Text(urgency),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}
