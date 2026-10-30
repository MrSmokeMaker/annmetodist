import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Backgrounds (Obsidian & Deep Slate)
  static const Color darkCanvas = Color(0xFF090B10);
  static const Color darkBackground = Color(0xFF0B0D13);
  static const Color darkSurface = Color(0xFF131622);
  static const Color darkElevated = Color(0xFF181C2B);
  static const Color darkSurfaceElevated = darkElevated;
  static const Color darkCard = Color(0x14FFFFFF); // ~8% opacity white

  // Light Theme Backgrounds (Warm Porcelain & Clean Glass)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceElevated = lightElevated;
  static const Color lightCard = Color(0xB3FFFFFF); // ~70% opacity white

  // Borders & Specular Lines
  static const Color darkBorder = Color(0x1AFFFFFF); // ~10%
  static const Color darkBorderSubtle = Color(0x0FFFFFFF); // ~6%
  static const Color specularHighlight = Color(0x33FFFFFF); // 20%
  static const Color lightBorder = Color(0x0F0F172A); // ~6%

  // Accent Colors (Linear & Apple inspired vibrancy)
  static const Color primaryIndigo = Color(0xFF5E5CE6);
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text Colors Dark (High contrast, WCAG AAA compliant)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Text Colors Light
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
}

class AppGradients {
  // Primary: Индиго -> Фиолетовый (Linear / Electric aesthetic)
  static const LinearGradient indigoViolet = LinearGradient(
    colors: [AppColors.primaryIndigo, AppColors.primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary: Фиолетовый -> Пурпурный
  static const LinearGradient violetMagenta = LinearGradient(
    colors: [AppColors.primaryViolet, Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cyan -> Teal
  static const LinearGradient cyanTeal = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cyan -> Blue
  static const LinearGradient cyanBlue = LinearGradient(
    colors: [AppColors.cyan, AppColors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Amber -> Orange (Warm luxury / Premium)
  static const LinearGradient amberOrange = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Emerald -> Teal (Success & Finished)
  static const LinearGradient emeraldTeal = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass Specular Borders (Apple-style specular highlight)
  static const LinearGradient glassBorderDark = LinearGradient(
    colors: [
      Color(0x3DFFFFFF), // 24% top-left highlight
      Color(0x0AFFFFFF), // 4% bottom-right shadow
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderLight = LinearGradient(
    colors: [
      Color(0x4D6366F1), // subtle indigo accent
      Color(0x12000000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Ambient Glows
  static const RadialGradient ambientIndigo = RadialGradient(
    center: Alignment(-0.8, -0.6),
    radius: 1.2,
    colors: [
      Color(0x2E5E5CE6), // 18% indigo
      Colors.transparent,
    ],
    stops: [0.0, 1.0],
  );

  static const RadialGradient ambientCyan = RadialGradient(
    center: Alignment(0.8, 0.7),
    radius: 1.3,
    colors: [
      Color(0x2406B6D4), // 14% cyan
      Colors.transparent,
    ],
    stops: [0.0, 1.0],
  );

  // Subtle Surface Card Gradient
  static const LinearGradient darkCardSurface = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // 10%
      Color(0x08FFFFFF), // 3%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  // Soft, diffuse modern box shadows
  static const List<BoxShadow> cardSm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardMd = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> cardLg = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: AppColors.primaryIndigo.withValues(alpha: 0.25),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowCyan = [
    BoxShadow(
      color: AppColors.cyan.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowSecondary = glowCyan;

  static List<BoxShadow> glowAmber = [
    BoxShadow(
      color: AppColors.accentAmber.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowAccent = [
    BoxShadow(
      color: AppColors.primaryViolet.withValues(alpha: 0.25),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
}

/// Возрастная палитра (Дошкольники / 1–2 класс)
class AgePalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final LinearGradient gradient;

  const AgePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
  });

  // Дошкольники: мягкие, тёплые градиенты (индиго-фиолетовый, бирюза)
  static const AgePalette preschool = AgePalette(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF06B6D4),
    accent: Color(0xFFA855F7),
    gradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // 1–2 класс: строже, академические благородные оттенки
  static const AgePalette school = AgePalette(
    primary: Color(0xFF3730A3), // Тёмно-синий индиго
    secondary: Color(0xFF0284C7), // Академический лазурный
    accent: Color(0xFF475569), // Сдержанный грифельный
    gradient: LinearGradient(
      colors: [Color(0xFF312E81), Color(0xFF1E40AF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

class AppRadii {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
  static const double full = pill;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryIndigo,
        secondary: AppColors.cyan,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      fontFamily: null, // Системный шрифт платформы (SF Pro на Apple, Roboto/Segoe на других)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.6,
          height: 1.18,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMutedDark,
          letterSpacing: 0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorderSubtle,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryIndigo,
        secondary: AppColors.cyan,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.6,
          height: 1.18,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryLight,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryLight,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMutedLight,
          letterSpacing: 0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14000000),
        thickness: 1,
      ),
    );
  }

  static ThemeData getTheme({required bool isDark, bool isPreschool = true}) {
    final palette = isPreschool ? AgePalette.preschool : AgePalette.school;
    final baseTheme = isDark ? darkTheme : lightTheme;

    return baseTheme.copyWith(
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: palette.primary,
        secondary: palette.secondary,
        tertiary: palette.accent,
        surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        error: AppColors.error,
      ),
    );
  }
}

/// Плавный переход между экранами (fade + slide 220 мс)
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.03, 0.0),
              end: Offset.zero,
            ).animate(curved);

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curved);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
