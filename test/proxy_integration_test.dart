import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

class _AllowRealNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealNetworkHttpOverrides();

  group('StorageService & YandexGptService Live Proxy Integration', () {
    late StorageService storageService;
    late YandexGptService gptService;

    setUp(() {
      storageService = StorageService();
      gptService = YandexGptService(storageService: storageService);
    });

    test('Proxy URL is saved and retrieved via StorageService', () async {
      const testUrl = 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c';
      await storageService.saveProxyUrl(testUrl);
      final retrievedUrl = await storageService.getProxyUrl();
      expect(retrievedUrl, testUrl);
    });

    test('YandexGptService.testConnection returns success: true via deployed proxy', () async {
      await storageService.saveProxyUrl('https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c');
      final result = await gptService.testConnection();
      print('testConnection result: $result');
      expect(result['success'], isTrue);
      expect(result['message'], contains('успешно'));
    });

    test('YandexGptService.generateConspect generates text via deployed proxy', () async {
      await storageService.saveProxyUrl('https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c');
      final conspect = await gptService.generateConspect(
        systemPrompt: 'Ты опытный методист.',
        userPrompt: 'Составь краткий план занятия на тему "Счёт до 5 для дошкольников". Не более 50 слов.',
      );
      print('generateConspect output:\n$conspect');
      expect(conspect, isNotEmpty);
    });
  });
}
