// app_colors.dart – Design tokens for colors
import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Backgrounds (Obsidian & Deep Slate)
  static const Color darkCanvas = Color(0xFF090B10);
  static const Color darkBackground = Color(0xFF0B0D13);
  static const Color darkSurface = Color(0xFF131622);
  static const Color darkElevated = Color(0xFF181C2B);
  static const Color darkSurfaceElevated = darkElevated;
  static const Color darkCard = Color(0x14FFFFFF); // ~8% opacity white

  // Light Theme Backgrounds (Warm Porcelain & Clean Glass)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceElevated = lightElevated;
  static const Color lightCard = Color(0xB3FFFFFF); // ~70% opacity white

  // Borders & Specular Lines
  static const Color darkBorder = Color(0x1AFFFFFF); // ~10%
  static const Color darkBorderSubtle = Color(0x0FFFFFFF); // ~6%
  static const Color specularHighlight = Color(0x33FFFFFF); // 20%
  static const Color lightBorder = Color(0x0F0F172A); // ~6%

  // Accent Colors (Linear & Apple inspired vibrancy)
  static const Color primaryIndigo = Color(0xFF5E5CE6);
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text Colors Dark (WCAG AAA)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Text Colors Light
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
}
