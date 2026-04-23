import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';


class SideBarNavigation extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final BuildContext parentContext;

  const SideBarNavigation({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: isOpen ? 0 : -260,
      top: 0,
      bottom: 0,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        color: AppColors.cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: const [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.shield, color: Colors.white),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SafeTrack",
                      style: TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Admin Portal",
                      style:
                          TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            

            _menuItem(Icons.dashboard, "Dashboard", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-dashboard');
            }, active: true),

             _menuItem(Icons.person, "Admin Profile", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-profile');
            }),

            _menuItem(Icons.warning, "All Incidents", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-incidents');
            }),

            _menuItem(Icons.people, "Responders", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-responders');
            }),

            _menuItem(Icons.map, "Live Map", () {
              onClose();
              Navigator.pushReplacementNamed(parentContext, '/admin-live-tracking');
            }),
            _menuItem(Icons.history, "History", () {
              onClose();
              Navigator.pushReplacementNamed(parentContext, '/admin-history');
            }),

            const Spacer(),

            _menuItem(Icons.notifications, "Notifications", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-notifications');
            }),

            _menuItem(Icons.settings, "Settings", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-settings');
            }),

            _menuItem(Icons.logout, "Logout", () {
              onClose();
              Navigator.pushReplacementNamed(
                  parentContext, '/admin-login');
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? AppColors.white : AppColors.textPrimary),
        title: Text(title, style: TextStyle(color: active ? AppColors.white : AppColors.textPrimary)),
        onTap: onTap,
      ),
    );
  }
}
