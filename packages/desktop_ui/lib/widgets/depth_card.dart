import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_radii.dart';

class DepthCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  const DepthCard({super.key, required this.child, this.elevation = 4});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      color: Colors.transparent,
      child: child,
    )
        .animate()
        .scale(begin: 0.97, end: 1.0, curve: Curves.elasticOut, duration: 250.ms)
        .fadeIn(duration: 200.ms);
  }
}
