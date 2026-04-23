import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';


class ResponderBottomBarNavigation extends StatelessWidget {
  final int currentIndex;

  const ResponderBottomBarNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: "Incidents",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: "Navigation",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/responder-home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/responder-incidents');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/responder-navigation');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/responder-profile');
            break;
        }
      },
    );
  }
}
