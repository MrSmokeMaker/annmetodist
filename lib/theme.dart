import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Backgrounds
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF161922);
  static const Color darkCard = Color(0x14FFFFFF); // ~8% opacity white

  // Light Theme Backgrounds
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xB3FFFFFF); // ~70% opacity white

  // Accent Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text Colors Dark (Elevated contrast for mobile Safari & sunlight, WCAG AA)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFA0A6B2);
  static const Color textMutedDark = Color(0xFF9BA1AA); // minimum #9BA1AA per design review

  // Text Colors Light
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
}

class AppGradients {
  // Primary: Индиго -> Фиолетовый
  static const LinearGradient indigoViolet = LinearGradient(
    colors: [AppColors.primaryIndigo, AppColors.primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary: Бирюза -> Синий
  static const LinearGradient violetMagenta = LinearGradient(
    colors: [AppColors.primaryViolet, Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanBlue = LinearGradient(
    colors: [AppColors.cyan, AppColors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Amber -> Orange
  static const LinearGradient amberOrange = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass Borders
  static const LinearGradient glassBorderDark = LinearGradient(
    colors: [
      Color(0x33FFFFFF), // 20%
      Color(0x0DFFFFFF), // 5%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderLight = LinearGradient(
    colors: [
      Color(0x4D6366F1), // subtle indigo accent
      Color(0x1A000000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Ambient Glows
  static const RadialGradient ambientIndigo = RadialGradient(
    center: Alignment(-0.8, -0.6),
    radius: 1.2,
    colors: [
      Color(0x336366F1), // 20% indigo
      Colors.transparent,
    ],
    stops: [0.0, 1.0],
  );

  static const RadialGradient ambientCyan = RadialGradient(
    center: Alignment(0.8, 0.7),
    radius: 1.3,
    colors: [
      Color(0x2606B6D4), // 15% cyan
      Colors.transparent,
    ],
    stops: [0.0, 1.0],
  );
}

/// Шаг 5: Возрастная палитра (Дошкольники / 1–2 класс)
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
  static const double xl = 26.0;
  static const double pill = 999.0;

  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
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
      fontFamily: null, // Системный шрифт платформы (SF Pro на iOS, Roboto на Android)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
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
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMutedDark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
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
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
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
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMutedLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1F000000),
        thickness: 1,
      ),
    );
  }

  /// Шаг 5: Получение темы с учетом возрастной палитры (Дошкольники / 1–2 класс)
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

/// Плавный переход между экранами (fade + slide 250 мс)
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.04, 0.0),
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
