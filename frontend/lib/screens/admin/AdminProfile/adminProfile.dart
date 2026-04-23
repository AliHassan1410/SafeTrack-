import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool isSidebarOpen = false;

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

  // ================= MAIN =================
  Widget _mainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 20),
          Expanded(child: _profileBody()),
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
            setState(() {
              isSidebarOpen = !isSidebarOpen;
            });
          },
        ),
        const SizedBox(width: 10),
        const Text(
          "Admin Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const CircleAvatar(child: Icon(Icons.person)),
      ],
    );
  }

  // ================= PROFILE BODY =================
  Widget _profileBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _profileHeader(),
          const SizedBox(height: 20),
          _profileInfo(),
          const SizedBox(height: 20),
          _securitySection(),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Muhammad Usman",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Administrator",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  "usman.admin@safetrack.pk",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfo() {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow("Full Name", "Muhammad Usman"),
            _infoRow("Email", "usman.admin@safetrack.pk"),
            _infoRow("Phone", "+92 300 1234567"),
            _infoRow("Role", "System Administrator"),
            _infoRow("Last Login", "Today, 10:45 AM"),
          ],
        ),
      ),
    );
  }

  Widget _securitySection() {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Security",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text(
                "Change Password",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text(
                "Two-Factor Authentication",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
