import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'data/method_repository.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/ambient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  final storageService = StorageService();
  final methodRepository = MethodRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            storageService: storageService,
            methodRepository: methodRepository,
          )..initialize(),
        ),
      ],
      child: const MetodistApp(),
    ),
  );
}

class MetodistApp extends StatelessWidget {
  const MetodistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Методист',
      debugShowCheckedModeBanner: false,
      themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.getTheme(isDark: false, isPreschool: appProvider.isPreschoolPalette),
      darkTheme: AppTheme.getTheme(isDark: true, isPreschool: appProvider.isPreschoolPalette),
      home: appProvider.isLoading
          ? const Scaffold(
              body: AmbientBackground(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                  ),
                ),
              ),
            )
          : const HomeScreen(),
    );
  }
}
