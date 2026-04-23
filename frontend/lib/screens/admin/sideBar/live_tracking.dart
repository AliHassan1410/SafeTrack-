import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:safetrack/screens/admin/sideBar/sideBarNavigation.dart';



class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  bool isSidebarOpen = false;

  double x = 80;
  double y = 120;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startFakeTracking();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startFakeTracking() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        x += 6;
        y += 4;

        if (x > 300) x = 80;
        if (y > 400) y = 120;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

  // ================= SIDEBAR =================
  
  

  // ================= MAIN =================
  Widget _mainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _topBar(),
          const SizedBox(height: 20),
          Expanded(child: _mapSection()),
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
          "Live Tracking",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const Spacer(),
        const CircleAvatar(child: Icon(Icons.person)),
      ],
    );
  }

  // ================= FAKE MAP =================
  Widget _mapSection() {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          _fakeMapGrid(),
          _incidentMarker(),
          _responderMarker(),
          _infoPanel(),
        ],
      ),
    );
  }

  Widget _fakeMapGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBg.withOpacity(0.5),
      ),
      child: CustomPaint(
        painter: GridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _incidentMarker() {
    return const Positioned(
      left: 260,
      top: 220,
      child: Column(
        children: [
          Icon(Icons.location_on, size: 40, color: Colors.red),
          Text("Incident", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _responderMarker() {
    return Positioned(
      left: x,
      top: y,
      child: Column(
        children: const [
          Icon(Icons.directions_car, size: 36, color: Colors.blue),
          Text("Responder", style: TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _infoPanel() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
        child: Card(
          color: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Inspector Farhan Ali",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text("Rescue 1122 • Lahore", style: TextStyle(color: AppColors.textSecondary)),
                  Text("Incident: Road Accident", style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              Column(
                children: const [
                  Chip(
                    label: Text("LIVE"),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text("ETA: 7 min", style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= GRID PAINTER =================
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
