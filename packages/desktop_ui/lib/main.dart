import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_editor/editor_screen.dart';
import 'package:desktop_ui/theme/theme_manager.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DesktopApp()));
}

class DesktopApp extends ConsumerWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(desktopThemeProvider);
    final theme = getThemeData(variant);
    return MaterialApp(
      title: 'Metodist Desktop',
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const MainScreen(),
        '/pdf-editor': (_) => const EditorScreen(),
      },
    );
  }
}
