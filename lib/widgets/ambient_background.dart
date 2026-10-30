import 'package:flutter/material.dart';
import '../theme.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base solid obsidian background
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
        ),

        // Atmospheric Ambient Orb 1: Top-Left Electric Indigo / Violet
        Positioned(
          top: -120,
          left: -100,
          width: size.width > 800 ? 540 : 360,
          height: size.width > 800 ? 540 : 360,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryIndigo.withOpacity(isDark ? 0.20 : 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Atmospheric Ambient Orb 2: Top-Right Warm Specular Glow (Violet / Iris)
        Positioned(
          top: -60,
          right: -80,
          width: size.width > 800 ? 440 : 280,
          height: size.width > 800 ? 440 : 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryViolet.withOpacity(isDark ? 0.14 : 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Atmospheric Ambient Orb 3: Bottom-Right Arctic Cyan / Blue
        Positioned(
          bottom: -120,
          right: -60,
          width: size.width > 800 ? 480 : 320,
          height: size.width > 800 ? 480 : 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withOpacity(isDark ? 0.16 : 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Content on top
        Positioned.fill(child: child),
      ],
    );
  }
}
