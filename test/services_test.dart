import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:metodist/providers/conspect_provider.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};
  bool throwOnWrite = false;
  bool throwOnRead = false;

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
    if (throwOnWrite) throw Exception('SecureStorage write error');
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
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
  }) async {
    if (throwOnRead) throw Exception('SecureStorage read error');
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }
}

http.Response jsonUtf8Response(dynamic data, int statusCode) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempHiveDir;

  setUpAll(() {
    tempHiveDir = Directory.systemTemp.createTempSync('metodist_test_hive_');
    Hive.init(tempHiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempHiveDir.existsSync()) {
      tempHiveDir.deleteSync(recursive: true);
    }
  });

  group('StorageService Tests', () {
    late FakeSecureStorage fakeSecureStorage;
    late StorageService storageService;

    setUp(() async {
      fakeSecureStorage = FakeSecureStorage();
      storageService = StorageService(secureStorage: fakeSecureStorage);
      await storageService.clear();
    });

    test('Сохранение и чтение API-ключа и Folder ID с автоматическим триммингом', () async {
      await storageService.setApiKey('  AQVN_TEST_KEY_123  ');
      await storageService.setFolderId('  b1g_test_folder_456  ');

      final key = await storageService.getApiKey();
      final folder = await storageService.getFolderId();

      expect(key, equals('AQVN_TEST_KEY_123'));
      expect(folder, equals('b1g_test_folder_456'));
    });

    test('clear() полностью удаляет сохраненные учетные данные', () async {
      await storageService.setApiKey('test_key');
      await storageService.setFolderId('test_folder');
      await storageService.clear();

      expect(await storageService.getApiKey(), isNull);
      expect(await storageService.getFolderId(), isNull);
    });

    test('Отказоустойчивое переключение на Hive при сбое чтения SecureStorage', () async {
      await storageService.setApiKey('fallback_key_val');
      fakeSecureStorage.throwOnRead = true;

      final key = await storageService.getApiKey();
      expect(key, equals('fallback_key_val'));
    });
  });

  group('YandexGptService - Connection & Auth Tests', () {
    late FakeSecureStorage fakeStorage;
    late StorageService storageService;

    setUp(() async {
      fakeStorage = FakeSecureStorage();
      storageService = StorageService(secureStorage: fakeStorage);
      await storageService.clear();
    });

    test('testConnection сообщает об ошибке, если API-ключ не указан', () async {
      final gptService = YandexGptService(storageService: storageService);
      final result = await gptService.testConnection(
        apiKey: '',
        folderId: 'b1g123',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('API-ключ не указан'));
    });

    test('testConnection сообщает об ошибке, если Folder ID не указан', () async {
      final gptService = YandexGptService(storageService: storageService);
      final result = await gptService.testConnection(
        apiKey: 'AQVN123',
        folderId: '   ',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('Folder ID не указан'));
    });

    test('testConnection возвращает success: true при HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('chat/completions'));
        expect(request.headers['Authorization'], equals('Api-Key test_key'));
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': 'Связь установлена'}
            }
          ]
        }, 200);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.testConnection(
        apiKey: 'test_key',
        folderId: 'test_folder',
      );

      expect(result['success'], isTrue);
      expect(result['message'], contains('успешно установлено'));
    });

    test('testConnection обрабатывает HTTP 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.testConnection(
        apiKey: 'bad_key',
        folderId: 'my_folder',
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], equals(401));
      expect(result['message'], contains('Неверный API-ключ'));
    });

    test('testConnection обрабатывает HTTP 403 с указанием роли ai.languageModels.user', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.testConnection(
        apiKey: 'key',
        folderId: 'folder_abc',
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], equals(403));
      expect(result['message'], contains('ai.languageModels.user'));
      expect(result['message'], contains('folder_abc'));
    });

    test('testConnection обрабатывает HTTP 429 Too Many Requests', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too many requests', 429);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.testConnection(
        apiKey: 'key',
        folderId: 'folder',
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], equals(429));
      expect(result['message'], contains('Превышен лимит запросов'));
    });

    test('testConnection корректно отлавливает сетевой сбой (ClientException)', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection reset by peer');
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.testConnection(
        apiKey: 'key',
        folderId: 'folder',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('Сетевая ошибка'));
    });
  });

  group('YandexGptService - generateConspect Tests', () {
    late FakeSecureStorage fakeStorage;
    late StorageService storageService;

    setUp(() async {
      fakeStorage = FakeSecureStorage();
      storageService = StorageService(secureStorage: fakeStorage);
      await storageService.clear();
    });

    test('Бросает YandexGptException, если API-ключ не задан в хранилище', () async {
      await storageService.setFolderId('my_folder');
      final gptService = YandexGptService(
        storageService: storageService,
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        () => gptService.generateConspect(
          systemPrompt: 'System',
          userPrompt: 'Тема урока',
        ),
        throwsA(isA<YandexGptException>().having(
          (e) => e.message,
          'message',
          contains('API-ключ YandexGPT не задан'),
        )),
      );
    });

    test('Бросает YandexGptException, если Folder ID не задан в хранилище', () async {
      await storageService.setApiKey('my_api_key');
      final gptService = YandexGptService(
        storageService: storageService,
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        () => gptService.generateConspect(
          systemPrompt: 'System',
          userPrompt: 'Тема урока',
        ),
        throwsA(isA<YandexGptException>().having(
          (e) => e.message,
          'message',
          contains('Идентификатор каталога (Folder ID) не задан'),
        )),
      );
    });

    test('Успешная генерация конспекта через OpenAI-совместимый эндпоинт', () async {
      await storageService.setApiKey('valid_api_key');
      await storageService.setFolderId('valid_folder_id');

      const expectedConspect = '# Конспект урока математики\n1. Цели: ...';

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('v1/chat/completions'));
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': expectedConspect}
            }
          ]
        }, 200);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.generateConspect(
        systemPrompt: 'Методист',
        userPrompt: 'Состав числа 10',
      );

      expect(result, equals(expectedConspect));
    });

    test('Немедленный отказ на HTTP 403 (без повторного обращения в резервный эндпоинт)', () async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('Forbidden', 403);
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      await expectLater(
        () => gptService.generateConspect(
          systemPrompt: 'System',
          userPrompt: 'Prompt',
        ),
        throwsA(isA<YandexGptException>()
            .having((e) => e.code, 'code', equals(403))
            .having((e) => e.message, 'message', contains('ai.languageModels.user'))),
      );

      expect(requestCount, equals(1));
    });

    test('Fallback на нативный эндпоинт при временной ошибке OpenAI-эндпоинта (HTTP 500)', () async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Internal server error', 500);
        } else {
          expect(request.url.toString(), contains('foundationModels/v1/completion'));
          return jsonUtf8Response({
            'result': {
              'alternatives': [
                {
                  'message': {'text': 'Конспект из резервного эндпоинта'}
                }
              ]
            }
          }, 200);
        }
      });

      final gptService = YandexGptService(
        storageService: storageService,
        client: mockClient,
      );

      final result = await gptService.generateConspect(
        systemPrompt: 'System',
        userPrompt: 'Prompt',
      );

      expect(result, equals('Конспект из резервного эндпоинта'));
      expect(requestCount, equals(2));
    });
  });

  group('ConspectProvider State Transitions', () {
    late FakeSecureStorage fakeStorage;
    late StorageService storageService;

    setUp(() async {
      fakeStorage = FakeSecureStorage();
      storageService = StorageService(secureStorage: fakeStorage);
      await storageService.clear();
    });

    test('Начальное состояние провайдера', () {
      final provider = ConspectProvider(storageService: storageService);

      expect(provider.result, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.hasResult, isFalse);
    });

    test('hasCredentials() возвращает false при пустом хранилище и true при заполненном', () async {
      final provider = ConspectProvider(storageService: storageService);
      expect(await provider.hasCredentials(), isFalse);

      await storageService.setApiKey('key');
      expect(await provider.hasCredentials(), isFalse);

      await storageService.setFolderId('folder');
      expect(await provider.hasCredentials(), isTrue);
    });

    test('generateConspect успешно переключает состояния: loading -> success', () async {
      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');

      final mockClient = MockClient((request) async {
        return jsonUtf8Response({
          'choices': [
            {
              'message': {'content': 'Готовый конспект урока'}
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

      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.generateConspect('Тема урока');

      expect(provider.isLoading, isFalse);
      expect(provider.result, equals('Готовый конспект урока'));
      expect(provider.errorMessage, isNull);
      expect(provider.hasResult, isTrue);
      expect(states, contains(true));
    });

    test('generateConspect при ошибке выставляет errorMessage и isLoading = false', () async {
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

      await provider.generateConspect('Тема урока');

      expect(provider.isLoading, isFalse);
      expect(provider.result, isEmpty);
      expect(provider.hasResult, isFalse);
      expect(provider.errorMessage, contains('ai.languageModels.user'));
    });

    test('clearResult() сбрасывает результат и ошибку', () async {
      final provider = ConspectProvider(storageService: storageService);
      provider.clearResult();

      expect(provider.result, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.hasResult, isFalse);
    });

    test('copyToClipboard() копирует результат в буфер обмена системы', () async {
      String? clipboardCopiedText;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardCopiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });

      await storageService.setApiKey('key');
      await storageService.setFolderId('folder');
      final mockClient = MockClient((_) async => jsonUtf8Response({
            'choices': [
              {
                'message': {'content': 'Текст для буфера'}
              }
            ]
          }, 200));

      final p = ConspectProvider(
        storageService: storageService,
        gptService: YandexGptService(storageService: storageService, client: mockClient),
      );
      await p.generateConspect('Prompt');
      await p.copyToClipboard();

      expect(clipboardCopiedText, equals('Текст для буфера'));
    });
  });
}
