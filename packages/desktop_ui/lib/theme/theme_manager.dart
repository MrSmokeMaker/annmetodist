import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme_a.dart';
import 'app_theme_b.dart';
import 'app_theme_c.dart';

enum DesktopThemeVariant { classic, neumorphic, gradient }

final desktopThemeProvider = StateProvider<DesktopThemeVariant>((ref) => DesktopThemeVariant.classic);

ThemeData getThemeData(DesktopThemeVariant variant) {
  switch (variant) {
    case DesktopThemeVariant.classic:
      return classicMacOsTheme;
    case DesktopThemeVariant.neumorphic:
      return neumorphicTheme;
    case DesktopThemeVariant.gradient:
      return gradientFusionTheme;
  }
}
