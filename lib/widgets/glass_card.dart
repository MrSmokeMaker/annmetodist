import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? borderGradient;
  final List<BoxShadow>? boxShadow;
  final bool isInteractive;

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
    this.boxShadow,
    this.isInteractive = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null && widget.isInteractive) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null && widget.isInteractive) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.isInteractive) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium glass surface colors
    final defaultBg = isDark
        ? (_isHovered
            ? const Color(0x18FFFFFF) // ~9.5% on hover
            : const Color(0x12FFFFFF)) // ~7% normal
        : (_isHovered
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.88));

    // Specular border gradient for Apple/Linear high-end frosted look
    final defaultBorderGradient = isDark
        ? (_isHovered
            ? const LinearGradient(
                colors: [Color(0x4DFFFFFF), Color(0x14FFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppGradients.glassBorderDark)
        : AppGradients.glassBorderLight;

    final effectiveBg = widget.backgroundColor ?? defaultBg;
    final effectiveGradient = widget.borderGradient ?? (widget.borderColor == null ? defaultBorderGradient : null);

    Widget cardBody = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: widget.child,
    );

    // Render specular border
    Widget borderedCard;
    if (effectiveGradient != null) {
      borderedCard = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: effectiveGradient,
          boxShadow: widget.boxShadow ?? (_isHovered ? AppShadows.cardMd : AppShadows.cardSm),
        ),
        padding: const EdgeInsets.all(1.0), // 1px micro specular border
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: cardBody,
          ),
        ),
      );
    } else {
      borderedCard = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.0,
          ),
          boxShadow: widget.boxShadow ?? (_isHovered ? AppShadows.cardMd : AppShadows.cardSm),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: cardBody,
          ),
        ),
      );
    }

    // Interactive gestures
    if (widget.onTap != null) {
      borderedCard = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: borderedCard,
          ),
        ),
      );
    }

    if (widget.margin != null) {
      borderedCard = Padding(padding: widget.margin!, child: borderedCard);
    }

    return borderedCard;
  }
}
