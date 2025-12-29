import 'package:flutter/material.dart';

class AppColors {
  // Main Colors (Black & White Theme)
  static const Color primary = Color(0xFF000000); // Black
  static const Color secondary = Color(0xFFFFFFFF); // White
  static const Color tertiary = Color(0xFF808080); // Grey
  
  // Secondary Colors
  static const Color secondaryLight = Color(0xFFE0E0E0); // Lighter Grey
  static const Color secondaryDark = Color(0xFF616161); // Darker Grey
  
  // Background Colors
  static const Color background = Color(0xFF000000); // Black
  static const Color surface = Color(0xFF121212); // Dark Grey (Material Surface)
  static const Color surfaceVariant = Color(0xFF2C2C2C); // Slightly lighter grey
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFAAAAAA); // Light Grey
  static const Color textTertiary = Color(0xFF666666); // Darker Grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  
  // Functional Colors
  static const Color error = Color(0xFFCF6679); // Material Dark Error
  static const Color success = Color(0xFF03DAC6); // Material Dark Secondary
  static const Color warning = Color(0xFFFFB74D); // Orange for warning
  static const Color info = Color(0xFF64B5F6); // Blue for info
  
  // Category Colors - Monochrome
  static const List<Color> categoryColors = [
    Color(0xFFFFFFFF), 
    Color(0xFFEEEEEE),
    Color(0xFFDDDDDD),
    Color(0xFFCCCCCC),
    Color(0xFFBBBBBB),
    Color(0xFFAAAAAA),
    Color(0xFF999999),
    Color(0xFF888888),
  ];
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, surfaceVariant], // Black to Dark Grey
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1AFFFFFF); // White shadow for dark mode visibility
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Border Colors
  static const Color border = Color(0xFF424242);
  static const Color borderLight = Color(0xFF616161);
  static const Color borderDark = Color(0xFF212121);
}
