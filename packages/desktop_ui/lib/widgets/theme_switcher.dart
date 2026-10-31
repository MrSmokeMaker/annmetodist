import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_manager.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(desktopThemeProvider);
    return PopupMenuButton<DesktopThemeVariant>(
      icon: const Icon(Icons.palette),
      initialValue: variant,
      onSelected: (v) => ref.read(desktopThemeProvider.notifier).state = v,
      itemBuilder: (c) => const [
        PopupMenuItem(value: DesktopThemeVariant.classic, child: Text('Classic macOS (A)')),
        PopupMenuItem(value: DesktopThemeVariant.neumorphic, child: Text('Neumorphic Luxury (B)')),
        PopupMenuItem(value: DesktopThemeVariant.gradient, child: Text('Gradient Fusion (C)')),
      ],
    );
  }
}
