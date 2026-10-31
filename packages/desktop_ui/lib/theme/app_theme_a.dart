import 'package:flutter/material.dart';
import 'package:ui/theme/app_colors.dart';
import 'package:ui/theme/app_spacing.dart';
import 'package:ui/theme/app_radii.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData classicMacOsTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF090B10), // Mica dark
  primaryColor: AppColors.primaryIndigo,
  textTheme: GoogleFonts.sFProDisplayTextTheme().apply(
    bodyColor: AppColors.textPrimaryLight,
    displayColor: AppColors.textPrimaryLight,
  ),
  cardTheme: CardTheme(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    color: Colors.transparent,
  ),
);
