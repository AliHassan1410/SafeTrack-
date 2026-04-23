import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboard> {
  bool isSidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          _mainContent(),

          // Dark overlay when sidebar open
          if (isSidebarOpen)
            GestureDetector(
              onTap: () => setState(() => isSidebarOpen = false),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),

          // Sidebar
          SideBarNavigation(
            isOpen: isSidebarOpen,
            onClose: () => setState(() => isSidebarOpen = false),
            parentContext: context,
          ),
        ],
      ),
    );
  }

  // ================= MAIN CONTENT =================
  Widget _mainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            const SizedBox(height: 24),
            _statsRow(),
            const SizedBox(height: 24),
            _responderStatus(),
            const SizedBox(height: 24),
            _bottomSection(),
            const SizedBox(height: 24),
            _weeklyIncidentGraph(),
          ],
        ),
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => setState(() => isSidebarOpen = !isSidebarOpen),
        ),
        const SizedBox(width: 12),
        const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= STATS =================
  Widget _statsRow() {
    return Row(
      children: const [
        _StatCard("Total Incidents", "6"),
        _StatCard("Pending", "2"),
        _StatCard("Active", "3"),
        _StatCard("Resolved Today", "1"),
      ],
    );
  }

  // ================= RESPONDER STATUS =================
  Widget _responderStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 24, 24, 132).withOpacity(0.8),
            AppColors.cardBg.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _StatusBox("Responder Available", "2", Colors.greenAccent),
          _DividerLine(),
          _StatusBox("Responder Busy", "1", Colors.orangeAccent),
          _DividerLine(),
          _StatusBox("ResponderOffline", "1", Colors.grey),
        ],
      ),
    );
  }

  // ================= BOTTOM SECTION =================
  Widget _bottomSection() {
    return Row(
      children: [
        Expanded(child: _pendingAssignments()),
        const SizedBox(width: 20),
        Expanded(child: _liveOverview()),
      ],
    );
  }

  // ================= PENDING ASSIGNMENTS =================
  Widget _pendingAssignments() {
    return _panel(
      title: "Pending Assignments",
      child: Column(
        children: const [
          _AssignmentTile(
            title: "Road Accident",
            location: "Ring Road",
            priority: "HIGH",
          ),
          _AssignmentTile(
            title: "Fire Emergency",
            location: "Mall Road",
            priority: "CRITICAL",
          ),
          _AssignmentTile(
            title: "Medical Emergency",
            location: "Model Town",
            priority: "MEDIUM",
          ),
        ],
      ),
    );
  }

  // ================= LIVE OVERVIEW =================
  Widget _liveOverview() {
    return _panel(
      title: "Live Overview",
      child: Column(
        children: const [
          _LiveLocationRow(
            name: "Responder A",
            status: "On Route",
            color: Colors.orange,
          ),
          _LiveLocationRow(
            name: "Responder B",
            status: "At Scene",
            color: Colors.green,
          ),
          _LiveLocationRow(
            name: "Responder C",
            status: "Offline",
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            "Live tracking simulation (Frontend only)",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= WEEKLY GRAPH =================
  Widget _weeklyIncidentGraph() {
    final data = [3, 5, 2, 6, 4, 1, 3];
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Incidents",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (i) {
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: data[i] * 20,
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[i],
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= PANEL =================
  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ================= SMALL WIDGETS =================

class _StatCard extends StatelessWidget {
  final String title, value;
  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cardBg.withOpacity(0.8),
              AppColors.cardBg.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String title, value;
  final Color color;
  const _StatusBox(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textSecondary.withOpacity(0.2),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final String title, location, priority;
  const _AssignmentTile({
    required this.title,
    required this.location,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    Color c =
        priority == "CRITICAL"
            ? Colors.red
            : priority == "HIGH"
            ? Colors.orange
            : Colors.blue;

    return Card(
      color: AppColors.cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Text(
          location,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Chip(
          label: Text(priority, style: const TextStyle(color: Colors.white)),
          backgroundColor: c,
        ),
      ),
    );
  }
}

class _LiveLocationRow extends StatelessWidget {
  final String name, status;
  final Color color;
  const _LiveLocationRow({
    required this.name,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.location_on, color: color),
      title: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
