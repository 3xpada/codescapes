import 'package:flutter/material.dart';

class AppColors {
  // Dark base
  static const bgTop = Color(0xFF050810);
  static const bgBottom = Color(0xFF0A1120);
  static const card = Color(0xFF0D1424);
  static const border = Color(0xFF1A2540);
  static const inputBg = Color(0xFF080D1A);
  static const text = Color(0xFFE2E8F0);
  static const muted = Color(0xFF7C8BA8);

  // Accent (swap these to change theme) - Cyber Cyan
  static const accent = Color(0xFF22D3EE);
  static const secondary = Color(0xFF6366F1);
  static const success = Color(0xFF34D399);
  static const onAccent = Color(0xFF031417);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );
}
