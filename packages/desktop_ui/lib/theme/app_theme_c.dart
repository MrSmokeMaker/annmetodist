import 'package:flutter/material.dart';
import 'package:ui/theme/app_colors.dart';
import 'package:ui/theme/app_spacing.dart';
import 'package:ui/theme/app_radii.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData gradientFusionTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0F2C), // dark‑blue base
  primaryColor: AppColors.accentAmber,
  textTheme: GoogleFonts.sFProDisplayTextTheme().apply(
    bodyColor: AppColors.textPrimaryLight,
    displayColor: AppColors.textPrimaryLight,
  ),
);
