import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/conspect_provider.dart';
import 'services/storage_service.dart';
import 'services/yandex_gpt_service.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final storageService = StorageService();
  final gptService = YandexGptService(storageService: storageService);

  runApp(MyApp(
    storageService: storageService,
    gptService: gptService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService? storageService;
  final YandexGptService? gptService;

  const MyApp({
    super.key,
    this.storageService,
    this.gptService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConspectProvider(
            storageService: storageService,
            gptService: gptService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Методист',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
