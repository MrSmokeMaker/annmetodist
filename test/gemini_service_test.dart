import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/config/gemini_config.dart';
import 'package:metodist/services/ai_service.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  group('Google Gemini Integration & Config Tests', () {
    late StorageService storageService;
    late YandexGptService yandexGptService;
    late AiService aiService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
      yandexGptService = YandexGptService(storageService: storageService);
      aiService = AiService(
        storageService: storageService,
        yandexGptService: yandexGptService,
      );
    });

    test('1. GeminiConfig contains valid default API key and Edge-proxy URL', () {
      expect(GeminiConfig.apiKey, isNotEmpty);
      expect(GeminiConfig.defaultProxyUrl, contains('gemini-proxy'));
      expect(GeminiConfig.defaultModel, equals('gemini-3.5-flash'));
      expect(GeminiConfig.isConfigured, isTrue);
    });

    test('2. StorageService persists and retrieves Gemini settings', () async {
      expect(storageService.getGeminiApiKey(), equals(GeminiConfig.apiKey));
      expect(storageService.getGeminiModel(), equals(GeminiConfig.defaultModel));
      expect(storageService.getGeminiProxyUrl(), equals(GeminiConfig.defaultProxyUrl));

      await storageService.saveGeminiModel('gemini-3.8-flash');
      expect(storageService.getGeminiModel(), equals('gemini-3.8-flash'));

      await storageService.saveGeminiModel(GeminiConfig.defaultModel);
    });

    test('3. AiService exposes available Gemini models and detects configured keys', () {
      expect(AiService.availableGeminiModels.containsKey('gemini-3.5-flash'), isTrue);
      expect(AiService.availableGeminiModels.containsKey('gemini-3.7-flash'), isTrue);
      expect(AiService.availableGeminiModels.containsKey('gemini-3.8-flash'), isTrue);
      expect(aiService.hasAnyKeyConfigured(), isTrue);
    });

    test('4. Live Edge-proxy bypasses region check and connects to Gemini', () async {
      await aiService.setProvider('gemini');
      expect(aiService.activeProvider, equals('gemini'));

      final result = await aiService.testConnection();
      expect(result['success'], isTrue, reason: 'Gemini connection via Edge-proxy must succeed without region error: ${result['message']}');
      expect((result['message'] as String).toLowerCase(), contains('gemini'));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('5. Live Gemini generation produces valid educational output via Edge-proxy', () async {
      await aiService.setProvider('gemini');
      await aiService.setGeminiModel('gemini-3.5-flash');

      final result = await aiService.generate(
        systemPrompt: 'Ты — методист начальной школы.',
        userPrompt: 'Назови одним предложением тему урока математики для 1 класса.',
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.length, greaterThan(10));
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
