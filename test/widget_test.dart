import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:metodist/providers/conspect_provider.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';
import 'package:metodist/ui/home_page.dart';
import 'package:metodist/ui/settings_page.dart';

/// Тестовое хранилище в памяти
class InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  InMemorySecureStorage([Map<String, String>? initial]) {
    if (initial != null) _data.addAll(initial);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.remove(key);

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.clear();
}

http.Response jsonUtf8Response(dynamic data, int statusCode) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Widget createHomeScreen({
  required ConspectProvider provider,
}) {
  return ChangeNotifierProvider<ConspectProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: HomePage(),
    ),
  );
}

Widget createSettingsScreen({
  required StorageService storageService,
  required YandexGptService gptService,
}) {
  return MaterialApp(
    home: SettingsPage(
      storageService: storageService,
      gptService: gptService,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempHiveDir;

  setUpAll(() {
    tempHiveDir = Directory.systemTemp.createTempSync('metodist_widget_test_hive_');
    Hive.init(tempHiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempHiveDir.existsSync()) {
      tempHiveDir.deleteSync(recursive: true);
    }
  });

  group('HomePage Widget Tests', () {
    late InMemorySecureStorage fakeStorage;
    late StorageService storageService;

    setUp(() async {
      fakeStorage = InMemorySecureStorage();
      storageService = StorageService(secureStorage: fakeStorage);
      await storageService.clear();
    });

    testWidgets('Рендерит базовые элементы HomePage', (tester) async {
      final provider = ConspectProvider(storageService: storageService);

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Методист — Генератор конспектов'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Сгенерировать конспект'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Отображает предупреждающий баннер, если ключи не заданы', (tester) async {
      final provider = ConspectProvider(storageService: storageService);

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('API-ключ или Folder ID не заполнены.'), findsOneWidget);
      expect(find.text('Настроить'), findsOneWidget);
    });

    testWidgets('Клик по методическому пресету заполняет TextField темы', (tester) async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');
      final provider = ConspectProvider(storageService: storageService);

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      final chipFinder = find.byType(ActionChip).first;
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isNotEmpty);
      expect(textField.controller?.text, contains('Русский язык'));
    });

    testWidgets('Кнопка генерации отключена при пустом поле ввода', (tester) async {
      final provider = ConspectProvider(storageService: storageService);

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(FilledButton, 'Сгенерировать конспект');
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('Отображает индикатор загрузки в процессе генерации', (tester) async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': 'Конспект'}
            }
          ]
        }, 200);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final provider = ConspectProvider(
        storageService: storageService,
        gptService: gptService,
      );

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Математика 2 класс');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Сгенерировать конспект'));
      await tester.pump();

      expect(find.text('Генерация...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Составляем конспект урока с помощью YandexGPT...'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Генерация...'), findsNothing);
    });

    testWidgets('Отображает Markdown-конспект и кнопки копирования/очистки при успехе', (tester) async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      const markdownContent = '### Тема: Звуковой анализ слова\n* Цель урока: обучить...';

      final mockClient = MockClient((request) async {
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': markdownContent}
            }
          ]
        }, 200);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final provider = ConspectProvider(
        storageService: storageService,
        gptService: gptService,
      );

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Чтение 1 класс');
      await tester.tap(find.widgetWithText(FilledButton, 'Сгенерировать конспект'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsNothing);
      expect(find.text('Введите тему урока или выберите шаблон выше и нажмите «Сгенерировать конспект».'), findsOneWidget);
    });

    testWidgets('Отображает блок ошибки с кнопкой перехода в настройки при сбое API', (tester) async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final provider = ConspectProvider(
        storageService: storageService,
        gptService: gptService,
      );

      await tester.pumpWidget(createHomeScreen(provider: provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Тема с ошибкой');
      await tester.tap(find.widgetWithText(FilledButton, 'Сгенерировать конспект'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('ai.languageModels.user'), findsOneWidget);
      expect(find.text('Открыть настройки'), findsOneWidget);
    });
  });

  group('SettingsPage Widget Tests', () {
    late InMemorySecureStorage fakeStorage;
    late StorageService storageService;

    setUp(() async {
      fakeStorage = InMemorySecureStorage({
        'yandex_api_key': 'saved_key_123',
        'yandex_folder_id': 'saved_folder_456',
      });
      storageService = StorageService(secureStorage: fakeStorage);
      await storageService.setApiKey('saved_key_123');
      await storageService.setFolderId('saved_folder_456');
    });

    testWidgets('Отображает инструкцию, поля ввода и загружает существующие данные', (tester) async {
      final gptService = YandexGptService(storageService: storageService);

      await tester.pumpWidget(createSettingsScreen(
        storageService: storageService,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Настройки YandexGPT'), findsOneWidget);
      expect(find.text('Инструкция по настройке'), findsOneWidget);
      expect(find.text('saved_key_123'), findsOneWidget);
      expect(find.text('saved_folder_456'), findsOneWidget);
      expect(find.text('Проверить связь'), findsOneWidget);
      expect(find.text('Сохранить'), findsOneWidget);
    });

    testWidgets('Переключатель скрытия API-ключа меняет obscureText', (tester) async {
      final gptService = YandexGptService(storageService: storageService);

      await tester.pumpWidget(createSettingsScreen(
        storageService: storageService,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      final obscureToggle = find.byIcon(Icons.visibility);
      expect(obscureToggle, findsOneWidget);

      await tester.tap(obscureToggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Валидирует пустые поля перед проверкой связи', (tester) async {
      final emptyStorage = StorageService(secureStorage: InMemorySecureStorage());
      await emptyStorage.clear();
      final gptService = YandexGptService(storageService: emptyStorage);

      await tester.pumpWidget(createSettingsScreen(
        storageService: emptyStorage,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      // Очищаем текстовые поля
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '');
      await tester.enterText(textFields.at(1), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проверить связь'));
      await tester.pumpAndSettle();

      expect(find.text('Пожалуйста, введите API-ключ перед проверкой.'), findsOneWidget);
    });

    testWidgets('Отображает зеленый баннер успешного соединения при ответе 200', (tester) async {
      final mockClient = MockClient((request) async {
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': 'ОК'}
            }
          ]
        }, 200);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      await tester.pumpWidget(createSettingsScreen(
        storageService: storageService,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проверить связь'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Соединение с YandexGPT успешно установлено!'), findsOneWidget);
    });

    testWidgets('Отображает красный баннер с детальным описанием ошибки 403', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      await tester.pumpWidget(createSettingsScreen(
        storageService: storageService,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проверить связь'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.textContaining('ai.languageModels.user'), findsOneWidget);
    });

    testWidgets('Кнопка «Сохранить» сохраняет ключи в хранилище и показывает SnackBar', (tester) async {
      final storage = StorageService(secureStorage: InMemorySecureStorage());
      await storage.clear();
      final gptService = YandexGptService(storageService: storage);

      await tester.pumpWidget(createSettingsScreen(
        storageService: storage,
        gptService: gptService,
      ));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'NEW_API_KEY_999');
      await tester.enterText(fields.at(1), 'NEW_FOLDER_ID_888');

      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Настройки успешно сохранены'), findsOneWidget);
      expect(await storage.getApiKey(), equals('NEW_API_KEY_999'));
      expect(await storage.getFolderId(), equals('NEW_FOLDER_ID_888'));
    });
  });
}
