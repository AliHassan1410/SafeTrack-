import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';

class IncidentManagementPage extends StatefulWidget {
  const IncidentManagementPage({super.key});

  @override
  State<IncidentManagementPage> createState() => _IncidentManagementPageState();
}

class _IncidentManagementPageState extends State<IncidentManagementPage> {
  bool isSidebarOpen = false;
  int currentPage = 1;
  final int rowsPerPage = 4;

  final List<Map<String, String>> incidents = [
    {
      "id": "INC-001",
      "title": "Road Accident on Ring Road",
      "type": "Accident",
      "location": "Lahore",
      "reporter": "Ahmed Khan",
      "urgency": "HIGH",
      "status": "in progress",
      "time": "1/10/2026",
    },
    {
      "id": "INC-002",
      "title": "Fire in Commercial Building",
      "type": "Fire",
      "location": "Lahore",
      "reporter": "Fatima Bibi",
      "urgency": "HIGH",
      "status": "assigned",
      "time": "1/10/2026",
    },
    {
      "id": "INC-003",
      "title": "Mobile Snatching Incident",
      "type": "Theft",
      "location": "Lahore",
      "reporter": "Hassan Raza",
      "urgency": "MEDIUM",
      "status": "pending",
      "time": "1/10/2026",
    },
    {
      "id": "INC-004",
      "title": "Medical Emergency - Heart Attack",
      "type": "Medical",
      "location": "Lahore",
      "reporter": "Ayesha Malik",
      "urgency": "HIGH",
      "status": "verified",
      "time": "1/10/2026",
    },
    {
      "id": "INC-005",
      "title": "Road Hazard - Open Manhole",
      "type": "Hazard",
      "location": "Lahore",
      "reporter": "Bilal Ahmed",
      "urgency": "MEDIUM",
      "status": "completed",
      "time": "1/9/2026",
    },
    {
      "id": "INC-006",
      "title": "Street Harassment Incident",
      "type": "Harassment",
      "location": "Lahore",
      "reporter": "Sara Qureshi",
      "urgency": "HIGH",
      "status": "pending",
      "time": "1/10/2026",
    },
  ];

  @override
  // ================= SIDEBAR =================
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          _mainContent(),

          // Overlay
          if (isSidebarOpen)
            GestureDetector(
              onTap: () => setState(() => isSidebarOpen = false),
              child: Container(
                color: Color.fromARGB(255, 147, 147, 147).withOpacity(0.4),
              ),
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
    final pageData =
        incidents
            .skip((currentPage - 1) * rowsPerPage)
            .take(rowsPerPage)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _topBar(),
          const SizedBox(height: 20),
          _header(),
          const SizedBox(height: 16),
          Expanded(child: _table(pageData)),
          _pagination(),
        ],
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => isSidebarOpen = !isSidebarOpen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search incidents, responders...",
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const CircleAvatar(child: Icon(Icons.person)),
      ],
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Incident Management",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ================= TABLE =================
  Widget _table(List<Map<String, String>> data) {
    return Card(
      color: AppColors.cardBg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _TableHeader(),
          const Divider(),
          ...data.map(_row).toList(),
        ],
      ),
    );
  }

  Widget _row(Map<String, String> i) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                i["id"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                i["title"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                i["location"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                i["reporter"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(child: _urgencyChip(i["urgency"]!)),
            Expanded(child: _statusChip(i["status"]!)),
            Expanded(
              child: Text(
                i["time"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editDialog(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDialog(i),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _urgencyChip(String u) {
    Color c = u == "HIGH" ? Colors.red : Colors.orange;
    return Chip(
      label: Text(u),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c),
    );
  }

  Widget _statusChip(String s) {
    Color c;
    switch (s) {
      case "completed":
        c = Colors.green;
        break;
      case "verified":
        c = Colors.blue;
        break;
      case "assigned":
        c = Colors.orange;
        break;
      case "in progress":
        c = Colors.purple;
        break;
      default:
        c = Colors.grey;
    }
    return Chip(
      label: Text(s),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c),
    );
  }

  // ================= PAGINATION =================
  Widget _pagination() {
    int totalPages = (incidents.length / rowsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Page $currentPage of $totalPages"),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              currentPage > 1 ? () => setState(() => currentPage--) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              currentPage < totalPages
                  ? () => setState(() => currentPage++)
                  : null,
        ),
      ],
    );
  }

  // ================= EDIT =================
  void _editDialog(Map<String, String> i) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Incident"),
            content: Text("Editing ${i["id"]}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  // ================= DELETE =================
  void _deleteDialog(Map<String, String> i) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Incident"),
            content: Text("Delete ${i["id"]}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() => incidents.remove(i));
                  Navigator.pop(context);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }
}

// ================= TABLE HEADER =================
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            "ID",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Incident",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Location",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Reporter",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Urgency",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Status",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Time",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Actions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
