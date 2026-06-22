import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../bottomNav/bottom_nav_bar.dart';

class ReporterProfile extends StatefulWidget {
  const ReporterProfile({super.key});

  @override
  State<ReporterProfile> createState() => _ReporterProfileState();
}

class _ReporterProfileState extends State<ReporterProfile> {
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;
  bool _locationSharing = true;

  String _name = "Loading...";
  String _role = "Emergency Reporter";
  String _email = "Loading...";
  String _phone = "Loading...";
  String _location = "Lahore, Pakistan";
  String? _profileImageUrl;

  final _auth = AuthService();
  bool _isLoading = true;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _auth.init();
      final user = _auth.currentUser;

      if (user != null) {
        // Fallback to local data first
        setState(() {
          _name = user.name;
          _email = user.email;
          _role = user.role;
          _phone = "Loading...";
          _location = "Location not available natively";
        });

        // Fetch real-time profile data from DB
        try {
          final profileData = await _auth.getUserProfile();
          if (mounted) {
            setState(() {
              _name = profileData['name'] ?? user.name;
              _email = profileData['email'] ?? user.email;
              _phone = profileData['phone'] ?? "No Phone";
              _role = profileData['role'] ?? user.role;
            });
          }
        } catch (e) {
          debugPrint("Fetch from DB failed: $e, using local cache");
        }
      } else {
        setState(() {
          _name = "Guest";
          _email = "No Email";
          _phone = "No Phone";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
      );

      if (image != null) {
        setState(() => _isImageUploading = true);
        final user = _auth.currentUser;
        if (user != null) {
          // Mock upload delay
          await Future.delayed(const Duration(seconds: 1));
          final String url = "https://via.placeholder.com/150";

          setState(() {
            _profileImageUrl = url;
            _isImageUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile picture updated successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isImageUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _updateProfile(
    String newName,
    String newPhone,
    String newLocation,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await Future.delayed(const Duration(seconds: 1)); // Mock DB delay
        setState(() {
          _name = newName;
          _phone = newPhone;
          _location = newLocation;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 20),
              _statsRow(),
              const SizedBox(height: 20),
              _personalInfoCard(),
              const SizedBox(height: 20),
              _settingsCard(),
              const SizedBox(height: 20),
              _signOutButton(),
              const SizedBox(height: 20),
              _footerText(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Account",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.white,
                  size: 28,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Enhanced Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                      child:
                          _profileImageUrl == null
                              ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: AppColors.primary,
                              )
                              : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // User Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: AppColors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _role.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _location,
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STATS ROW =================
  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatBox(
              title: "Reports",
              value: "0",
              color: AppColors.primary,
              icon: Icons.description_outlined,
            ),
            const SizedBox(width: 12),
            _StatBox(
              title: "Verified",
              value: "0",
              color: Colors.green,
              icon: Icons.verified_outlined,
            ),
            const SizedBox(width: 12),
            _StatBox(
              title: "Accuracy",
              value: "0%",
              color: Colors.orange,
              icon: Icons.assessment_outlined,
            ),
          ],
        ),
      ),
    );
  }

  // ================= PERSONAL INFO =================
  Widget _personalInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              "SECURITY & INFO",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoItemTile(
                  label: "Phone",
                  value: _phone,
                  icon: Icons.phone_android_rounded,
                  color: Colors.blue,
                ),
                _infoItemTile(
                  label: "Email",
                  value: _email,
                  icon: Icons.alternate_email_rounded,
                  color: Colors.indigo,
                ),
                _infoItemTile(
                  label: "Address",
                  value: _location,
                  icon: Icons.home_work_rounded,
                  color: Colors.orange,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItemTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.lock_rounded, size: 14, color: Colors.blueGrey),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Divider(
              color: AppColors.textSecondary.withOpacity(0.1),
              height: 1,
            ),
          ),
      ],
    );
  }

  // ================= SETTINGS =================
  Widget _settingsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              "PREFERENCES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _settingsItem(
                  icon: Icons.shield_rounded,
                  title: "2FA Authentication",
                  subtitle: "Secure your account with 2-steps",
                  isSwitch: true,
                  value: _twoFactorEnabled,
                  onChanged: (v) => setState(() => _twoFactorEnabled = v),
                  color: Colors.teal,
                ),
                _settingsItem(
                  icon: Icons.notifications_active_rounded,
                  title: "Push Notifications",
                  subtitle: "Instant emergency alerts",
                  isSwitch: true,
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  color: Colors.amber[800]!,
                ),
                _settingsItem(
                  icon: Icons.my_location_rounded,
                  title: "Location Services",
                  subtitle: "Real-time dispatch tracking",
                  isSwitch: true,
                  value: _locationSharing,
                  onChanged: (v) => setState(() => _locationSharing = v),
                  color: Colors.pink,
                ),
                _settingsItem(
                  icon: Icons.password_rounded,
                  title: "Change Password",
                  subtitle: "Update your login security",
                  isSwitch: false,
                  onTap: _showChangePasswordDialog,
                  color: Colors.blueGrey,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSwitch,
    required Color color,
    bool? value,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing:
              isSwitch
                  ? Switch(
                    value: value!,
                    onChanged: onChanged,
                    activeColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withOpacity(0.2),
                  )
                  : const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
          onTap: onTap,
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Divider(
              color: AppColors.textSecondary.withOpacity(0.08),
              height: 1,
            ),
          ),
      ],
    );
  }

  // ================= SIGN OUT =================
  Widget _signOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.red.withOpacity(0.05),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: ListTile(
          onTap: _showSignOutDialog,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: const Text(
            "Sign Out",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          subtitle: const Text(
            "Terminate current session safely",
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
        ),
      ),
    );
  }

  Widget _footerText() {
    return Column(
      children: [
        Text(
          "SafeTrack v1.0.0",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "Pakistan Emergency Reporting System",
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  // ================= DIALOG METHODS =================
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final locationController = TextEditingController(text: _location);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  controller: nameController,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  controller: phoneController,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Address / Location",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  controller: locationController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _updateProfile(
                    nameController.text,
                    phoneController.text,
                    locationController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    // Leave as is for now, this logic handles UI not Auth update yet.
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Sign Out"),
            content: const Text(
              "Are you sure you want to sign out of your account?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/reporter-login',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Sign Out"),
              ),
            ],
          ),
    );
  }
}

// ================= STAT BOX =================
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
