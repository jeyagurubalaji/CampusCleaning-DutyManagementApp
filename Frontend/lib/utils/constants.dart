import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF26A69A);
  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFB8C00);
  static const danger = Color(0xFFE53935);
  static const pending = Color(0xFF757575);
  static const background = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}

class StatusColors {
  static Color of(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pending;
      case 'completed':
        return AppColors.warning;
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.pending;
    }
  }

  static String label(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
