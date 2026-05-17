import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — mint teal
  static const Color primary = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF00574B);
  static const Color primaryLight = Color(0xFF4DB6AC);

  // Per-screen accent colors
  static const Color scanAccent = Color(0xFF0277BD);        // Blue — scan/AI
  static const Color careAccent = Color(0xFF2E7D32);        // Green — care/hospitals
  static const Color chatAccent = Color(0xFF00838F);        // Cyan — chat
  static const Color appointmentAccent = Color(0xFF5E35B1); // Purple — appointments
  static const Color emergencyAccent = Color(0xFFE53935);   // Red — emergency ONLY

  // Emergency section specific colors
  static const Color govtAmbulance = Color(0xFFE53935);
  static const Color majorHospital = Color(0xFFE65100);
  static const Color privateAmbulance = Color(0xFF0277BD);
  static const Color otherEmergency = Color(0xFF5E35B1);
  static const Color firstAid = Color(0xFF2E7D32);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0D1A18);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF1F8F7);
  static const Color surfaceDark = Color(0xFF152420);

  static const Color surfaceVariantLight = Color(0xFFE0F2F1);
  static const Color surfaceVariantDark = Color(0xFF1C302C);

  // Text
  static const Color textPrimaryLight = Color(0xFF0D1A18);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF4E6B67);
  static const Color textSecondaryDark = Color(0xFF8FADA9);

  static const Color textBodyLight = Color(0xFF2D4744);
  static const Color textBodyDark = Color(0xFFB2CAC7);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF43A047);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFE53935);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFB2DFDB);
  static const Color dividerDark = Color(0xFF1C302C);
}