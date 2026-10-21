

import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'data/method_repository.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/ambient_background.dart';
import 'widgets/glass_card.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('ru', null);
  } catch (e) {
    debugPrint('DateFormatting warning: $e');
  }

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

  // JS Bridge for PDF generation callback (window.onPdfGenerated) - only for web
  if (kIsWeb) {
    try {
      // Use js_util to set a global property on the window object.
      // ignore: avoid_dynamic_calls
      js_util.setProperty(js_util.globalThis, 'onPdfGenerated', (dynamic fileName) {
        if (fileName != null) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            Provider.of<AppProvider>(ctx, listen: false).addRecentPdf(fileName.toString());
          }
        }
      });
    } catch (e) {
      debugPrint('JS bridge onPdfGenerated setup error: $e');
    }
  }
}

class MetodistApp extends StatelessWidget {
  const MetodistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Методист',
      debugShowCheckedModeBanner: false,
      themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.getTheme(isDark: false, isPreschool: appProvider.selectedAgeGroup == 'preschool'),
      darkTheme: AppTheme.getTheme(isDark: true, isPreschool: appProvider.selectedAgeGroup == 'preschool'),
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
          : appProvider.errorMessage != null
              ? Scaffold(
                  body: AmbientBackground(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Ошибка загрузки',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                appProvider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryIndigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Повторить попытку'),
                                onPressed: () => appProvider.initialize(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const HomeScreen(),
    );
  }
}
