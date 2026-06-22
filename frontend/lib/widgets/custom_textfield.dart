import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';


class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: isPassword
              ? const Icon(Icons.visibility_off, color: AppColors.textSecondary)
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
