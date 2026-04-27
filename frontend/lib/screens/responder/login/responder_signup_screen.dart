import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';

import '../../../services/auth_service.dart';
import '../../auth/otp_verification_screen.dart';

class ResponderSignupPage extends StatefulWidget {
  const ResponderSignupPage({super.key});

  @override
  State<ResponderSignupPage> createState() => _ResponderSignupPageState();
}

class _ResponderSignupPageState extends State<ResponderSignupPage> {
  bool _isPoliceSelected = true;
  bool _obscurePassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deptIdController = TextEditingController();

  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _rankController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deptIdController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'responder',
        responderType: _isPoliceSelected ? 'crime' : 'medical',
      );
      // Here you would also save specific responder details to backend (badge number, rank, etc.)

      if (mounted) {
        if (result['requiresVerification'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: result['email'] ?? _emailController.text.trim(),
                role: 'responder',
              ),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/responder-login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Emergency Responder",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Title Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Register as First Responder",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete the form for department verification",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Login/Signup Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/responder-login',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Center(
                              child: Text(
                                "LOGIN",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              "REGISTER",
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Department ID Input
                _buildInputField(
                  icon: Icons.badge_outlined,
                  label: "Department ID (Required)",
                  hintText: "e.g., PDMA-2024-001, Rescue1122-EMP-023",
                  controller: _deptIdController,
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "Format: [Department]-[Year]-[UniqueNumber]",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Role Selection
                Text(
                  "Select Your Role",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton(
                        title: "Police Force",
                        icon: Icons.local_police_outlined,
                        selected: _isPoliceSelected,
                        onTap: () {
                          setState(() => _isPoliceSelected = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _roleButton(
                        title: "Ambulance Service",
                        icon: Icons.local_hospital_outlined,
                        selected: !_isPoliceSelected,
                        onTap: () {
                          setState(() => _isPoliceSelected = false);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      // Full Name
                      _buildInputField(
                        icon: Icons.person_outline,
                        label: "Full Name",
                        hintText: "Enter your full name",
                        controller: _nameController,
                      ),

                      const SizedBox(height: 20),

                      // Official Email
                      _buildInputField(
                        icon: Icons.email_outlined,
                        label: "Official Email",
                        hintText: "name@department.gov.pk",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Phone Number
                      _buildInputField(
                        icon: Icons.phone_outlined,
                        label: "Phone Number",
                        hintText: "03XX-XXXXXXX",
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 20),

                      // Role-specific fields
                      if (_isPoliceSelected) ...[
                        _buildInputField(
                          icon: Icons.badge_outlined,
                          label: "Police Badge Number",
                          hintText: "e.g., PB-12345",
                          controller: _idController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.military_tech_outlined,
                          label: "Rank / Position",
                          hintText: "e.g., Officer, Sergeant, Inspector",
                          controller: _rankController,
                        ),
                      ] else ...[
                        _buildInputField(
                          icon: Icons.medical_services_outlined,
                          label: "Paramedic ID",
                          hintText: "e.g., PM-67890",
                          controller: _idController,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Password",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Create secure password",
                                      hintStyle: TextStyle(
                                        color: AppColors.textSecondary.withOpacity(0.4),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Verification Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Verification Process",
                                  style: TextStyle(
                                  color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "1. Submit this registration form\n"
                              "2. Administrator will verify your department ID\n"
                              "3. You'll receive approval email within 24-48 hours\n"
                              "4. Upload verification letter if requested",
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.9),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: AppColors.white)
                              : const Text(
                                  "REQUEST VERIFICATION",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "Administrators will review your credentials",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Footer with login link
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Already have verified credentials?",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, '/responder-login');
                        },
                        child: const Text(
                          "Sign In to Your Account",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
