import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (from DIU CPC logo)
  static const Color lightBlue = Color(0xFF66B6FF);
  static const Color mediumBlue = Color(0xFF3A86FF);
  static const Color deepBlue = Color(0xFF244B8A);
  
  // White
  static const Color white = Color(0xFFFFFFFF);
  
  // Secondary Colors
  static const Color skyBlueAccent = Color(0xFF5AD2FF);
  static const Color coolCyan = Color(0xFF00D0D8);
  static const Color softGray = Color(0xFFE0E6ED);
  
  // Additional utility colors
  static const Color darkGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Standard Background Colors
  static const Color primaryBackground = Color(0xFFF5F5F5); // Light grey
  static const Color surfaceBackground = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white
  static const Color accentBackground = Color(0xFFE3F2FD); // Light blue tint
  
  // Gradient definitions (simplified for standard look)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentBackground, primaryBackground],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBlue, mediumBlue],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, lightGray],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBackground, softGray],
    stops: [0.0, 1.0],
  );
  
  // Glassmorphism colors
  static Color glassBackground = white.withOpacity(0.2);
  static Color glassBorder = white.withOpacity(0.3);
  
  // Shadow colors
  static Color cardShadow = deepBlue.withOpacity(0.1);
  static Color buttonShadow = deepBlue.withOpacity(0.3);
}
