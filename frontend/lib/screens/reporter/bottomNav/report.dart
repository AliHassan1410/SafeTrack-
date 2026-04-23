import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safetrack/services/incident_services.dart';

class ReportIncidentScreen extends StatefulWidget {
  final int initialTabIndex;
  const ReportIncidentScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  late int _selectedTab;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> _categories = ['Medical Emergency', 'Crime'];
  String _selectedCategory = 'Medical Emergency';

  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _getLocation();
  }

  // ---------------- LOCATION ----------------
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationController.text = "Location Disabled";
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position pos = await Geolocator.getCurrentPosition();
      _locationController.text =
          "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
    } catch (e) {
      _locationController.text = "Location Error";
    }
  }

  // ---------------- IMAGE ----------------
  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() => _image = img);
    }
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔥 Get real location
      Position position = await Geolocator.getCurrentPosition();

      // 🔥 Call backend using service
      await IncidentService.createIncident(
        title: _titleController.text,
        type: _selectedCategory,
        description: _descriptionController.text,
        lat: position.latitude,
        lng: position.longitude,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Incident Submitted")));

      // 🔄 Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _image = null);

      // Return to Home so real-time incidents refresh
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => _loading = false);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Report Incident",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _input(_titleController, "Title", Icons.title),
                      const Divider(height: 30),

                      _input(
                        _descriptionController,
                        "Description",
                        Icons.description,
                        maxLines: 4,
                      ),
                      const Divider(height: 30),

                      _locationBox(),
                      const Divider(height: 30),

                      _dropdown(),
                      const Divider(height: 30),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _imageBox(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          _submitBtn(),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Text(
        "Report Incident",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }



  // ---------------- INPUT ----------------
  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: c,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- LOCATION ----------------
  Widget _locationBox() {
    return Row(
      children: [
        const Icon(Icons.location_on, color: AppColors.primary),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _locationController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Location",
              hintStyle: TextStyle(color: Colors.black38, fontWeight: FontWeight.w400),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.my_location, color: AppColors.primary), onPressed: _getLocation),
      ],
    );
  }

  // ---------------- DROPDOWN ----------------
  Widget _dropdown() {
    return Row(
      children: [
        const Icon(Icons.category, color: AppColors.primary),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              items: _categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- IMAGE ----------------
  Widget _imageBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          image:
              _image != null
                  ? DecorationImage(
                    image: FileImage(File(_image!.path)),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            _image == null
                ? const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: AppColors.primary,
                  ),
                )
                : null,
      ),
    );
  }

  // ---------------- BUTTON ----------------
  Widget _submitBtn() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _loading ? null : _submit,
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child:
                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "SUBMIT REPORT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
