import 'package:flutter/material.dart';
import '../theme.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Solid background base
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
        ),

        // Top-left radial gradient (Indigo / Purple glow)
        Positioned(
          top: -100,
          left: -100,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryIndigo.withOpacity(isDark ? 0.22 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom-right radial gradient (Cyan / Blue glow)
        Positioned(
          bottom: -100,
          right: -80,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cyan.withOpacity(isDark ? 0.18 : 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
