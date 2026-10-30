import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui/theme/app_theme.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base solid background
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
        ),
        // Animated Lottie logo (top‑left)
        Positioned(
          top: 12,
          left: 12,
          width: 48,
          height: 48,
          child: Lottie.asset(
            'assets/animations/logo.json',
            repeat: true,
            animate: true,
          ),
        ),
        // Atmospheric Ambient Orbs (preserve old effect)
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
        // Child content
        Positioned.fill(child: child),
      ],
    );
  }
}
