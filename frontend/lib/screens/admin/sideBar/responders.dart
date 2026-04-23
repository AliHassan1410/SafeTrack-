import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';

class ResponderManagementPage extends StatefulWidget {
  const ResponderManagementPage({super.key});

  @override
  State<ResponderManagementPage> createState() =>
      _ResponderManagementPageState();
}

class _ResponderManagementPageState extends State<ResponderManagementPage> {
  bool isSidebarOpen = false;
  int currentPage = 1;
  final int rowsPerPage = 3;

  final List<Map<String, String>> responders = [
    {
      "name": "Inspector Farhan Ali",
      "id": "res1",
      "dept": "Rescue 1122 - Lahore",
      "phone": "+92 311 5556666",
      "email": "farhan.ali@rescue1122.pk",
      "status": "on duty",
    },
    {
      "name": "Constable Imran Khan",
      "id": "res2",
      "dept": "Punjab Police - Lahore",
      "phone": "+92 322 7778899",
      "email": "imran.khan@punjabpolice.gov.pk",
      "status": "available",
    },
    {
      "name": "Dr. Amina Shah",
      "id": "res3",
      "dept": "Edhi Ambulance Service",
      "phone": "+92 333 1234567",
      "email": "amina.shah@edhi.org.pk",
      "status": "available",
    },
    {
      "name": "Fire Chief Nawaz Sharif",
      "id": "res4",
      "dept": "Lahore Fire Brigade",
      "phone": "+92 344 9876543",
      "email": "fire.chief@lahore.gov.pk",
      "status": "busy",
    },
    {
      "name": "SI Kamran Akmal",
      "id": "res5",
      "dept": "Punjab Police - Traffic Wing",
      "phone": "+92 355 4443322",
      "email": "kamran.akmal@punjabpolice.gov.pk",
      "status": "available",
    },
  ];

  @override
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
              child: Container(color: Colors.black.withOpacity(0.4)),
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
    final paginatedData =
        responders
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
          const SizedBox(height: 20),
          Expanded(child: _table(paginatedData)),
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
          onPressed: () {
            setState(() => isSidebarOpen = !isSidebarOpen);
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search responders...",
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
      children: [
        const Text(
          "Responder Management",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text("Add Responder"),
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
          ...data.map((e) => _row(e)).toList(),
        ],
      ),
    );
  }

  Widget _row(Map<String, String> r) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                r["name"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                r["dept"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                r["phone"]!,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            Expanded(child: _statusChip(r["status"]!)),
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editDialog(r),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDialog(r),
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

  Widget _statusChip(String status) {
    Color color =
        status == "available"
            ? Colors.green
            : status == "busy"
            ? Colors.red
            : Colors.orange;

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  // ================= PAGINATION =================
  Widget _pagination() {
    int totalPages = (responders.length / rowsPerPage).ceil();

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

  // ================= EDIT DIALOG =================
  void _editDialog(Map<String, String> r) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Responder"),
            content: Text("Editing ${r["name"]}"),
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

  // ================= DELETE DIALOG =================
  void _deleteDialog(Map<String, String> r) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Responder"),
            content: Text("Are you sure you want to delete ${r["name"]}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() => responders.remove(r));
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
            "Responder",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Department",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Contact",
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
