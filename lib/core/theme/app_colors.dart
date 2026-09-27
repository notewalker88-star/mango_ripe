import 'package:flutter/material.dart';

class AppColors {
  // Primary Mango Palette
  static const Color mangoGreen = Color(0xFF1B5E20);
  static const Color mangoGreenLight = Color(0xFF2E7D32);
  static const Color mangoGreenAccent = Color(0xFF43A047);
  static const Color mangoAmber = Color(0xFFF57F17);
  static const Color mangoAmberLight = Color(0xFFFBC02D);
  static const Color mangoOrange = Color(0xFFE65100);
  static const Color mangoOrangeLight = Color(0xFFFF6F00);
  static const Color mangoYellow = Color(0xFFFFC107);

  // Dark Theme Base
  static const Color bgDark = Color(0xFF0A0F0A);
  static const Color bgCard = Color(0xFF121A12);
  static const Color bgCardLight = Color(0xFF1A2A1A);
  static const Color surfaceDark = Color(0xFF162016);
  static const Color divider = Color(0xFF2A3A2A);

  // Text
  static const Color textPrimary = Color(0xFFF5F7F5);
  static const Color textSecondary = Color(0xFFB0C4B0);
  static const Color textMuted = Color(0xFF6B8F6B);

  // Ripeness Colors
  static const Color unripeColor = Color(0xFF2E7D32);
  static const Color partiallyRipeColor = Color(0xFFF9A825);
  static const Color ripeColor = Color(0xFFFF8F00);
  static const Color overripeColor = Color(0xFFB71C1C);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF0A2E0A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2A1A), Color(0xFF0F1A0F)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6F00), Color(0xFFF57F17)],
  );

  static const LinearGradient scanOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Color(0x00000000), Color(0xCC000000)],
    stops: [0.0, 0.4, 1.0],
  );
}
