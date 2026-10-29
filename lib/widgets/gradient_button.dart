import 'package:flutter/material.dart';
import '../theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final double? width;
  final String? shortcutLabel;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient = AppGradients.indigoViolet,
    this.icon,
    this.isLoading = false,
    this.height = 54.0,
    this.borderRadius = AppRadii.lg, // 22.0
    this.width,
    this.shortcutLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled && !isLoading ? 0.45 : 1.0,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: (gradient is LinearGradient &&
                            (gradient as LinearGradient).colors.isNotEmpty)
                        ? (gradient as LinearGradient).colors.first.withOpacity(0.35)
                        : AppColors.primaryIndigo.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (shortcutLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                shortcutLabel!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
