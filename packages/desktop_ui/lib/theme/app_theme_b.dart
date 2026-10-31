import 'package:flutter/material.dart';
import 'package:ui/theme/app_colors.dart';
import 'package:ui/theme/app_spacing.dart';
import 'package:ui/theme/app_radii.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData neumorphicTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5), // soft‑shadow bg
  primaryColor: AppColors.cyan,
  textTheme: GoogleFonts.sFProDisplayTextTheme().apply(
    bodyColor: AppColors.textPrimaryDark,
    displayColor: AppColors.textPrimaryDark,
  ),
  cardTheme: CardTheme(
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    color: Colors.white,
    shadowColor: Colors.black.withOpacity(0.15),
  ),
);
