import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? borderGradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadii.lg, // 22.0
    this.blurSigma = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.white.withOpacity(0.72);

    final defaultBorder = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);

    final effectiveBg = backgroundColor ?? defaultBg;
    final effectiveBorderColor = borderColor ?? defaultBorder;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderGradient == null
            ? Border.all(
                color: effectiveBorderColor,
                width: 1.0,
              )
            : null,
      ),
      child: child,
    );

    // If borderGradient is provided, wrap in an outer container with gradient border
    if (borderGradient != null) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: borderGradient,
        ),
        padding: const EdgeInsets.all(1.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(borderRadius - 1),
          ),
          child: child,
        ),
      );
    }

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );

    if (onTap != null) {
      glass = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primaryIndigo.withOpacity(0.12),
          highlightColor: AppColors.primaryIndigo.withOpacity(0.06),
          child: glass,
        ),
      );
    }

    if (margin != null) {
      glass = Padding(padding: margin!, child: glass);
    }

    return glass;
  }
}
