import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/config/zveno_config.dart';
import 'package:metodist/services/ai_service.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_art_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  group('Zveno AI Integration, Models & Art Generation Tests', () {
    late StorageService storageService;
    late YandexGptService yandexGptService;
    late YandexArtService artService;
    late AiService aiService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
      yandexGptService = YandexGptService(storageService: storageService);
      artService = YandexArtService(storageService: storageService);
      aiService = AiService(
        storageService: storageService,
        yandexGptService: yandexGptService,
      );
    });

    test('1. ZvenoConfig contains user API key, endpoint and recommended cheap models', () {
      expect(ZvenoConfig.apiKey, isNotEmpty);
      expect(ZvenoConfig.baseUrl, equals('https://api.zveno.ai/v1'));
      expect(ZvenoConfig.defaultModel, equals('deepseek/deepseek-chat'));
      expect(ZvenoConfig.defaultImageModel, equals('google/gemini-3.1-flash-image'));
      expect(ZvenoConfig.isConfigured, isTrue);
      expect(ZvenoConfig.recommendedTextModels.containsKey('deepseek/deepseek-chat'), isTrue);
      expect(ZvenoConfig.recommendedImageModels.containsKey('google/gemini-3.1-flash-image'), isTrue);
    });

    test('2. StorageService persists and retrieves Zveno settings', () async {
      expect(storageService.getZvenoApiKey(), equals(ZvenoConfig.apiKey));
      expect(storageService.getZvenoModel(), equals(ZvenoConfig.defaultModel));
      expect(storageService.getZvenoImageModel(), equals(ZvenoConfig.defaultImageModel));
      expect(storageService.getZvenoBaseUrl(), equals(ZvenoConfig.baseUrl));

      await storageService.saveZvenoModel('qwen/qwen3.7-flash');
      expect(storageService.getZvenoModel(), equals('qwen/qwen3.7-flash'));

      await storageService.saveZvenoImageModel('google/gemini-3.1-flash-image');
      expect(storageService.getZvenoImageModel(), equals('google/gemini-3.1-flash-image'));

      // Restore defaults
      await storageService.saveZvenoModel(ZvenoConfig.defaultModel);
      await storageService.saveZvenoImageModel(ZvenoConfig.defaultImageModel);
    });

    test('3. AiService exposes available Zveno text/image models and detects key', () {
      expect(AiService.availableZvenoModels.containsKey('deepseek/deepseek-chat'), isTrue);
      expect(AiService.availableZvenoImageModels.containsKey('google/gemini-2.5-flash-image'), isTrue);
      expect(aiService.hasAnyKeyConfigured(), isTrue);
    });

    test('4. Live Zveno AI testConnection returns success', () async {
      await aiService.setProvider('zveno');
      expect(aiService.activeProvider, equals('zveno'));

      final result = await aiService.testConnection();
      expect(result['success'], isTrue, reason: 'Zveno connection failed: ${result['message']}');
      expect((result['message'] as String).toLowerCase(), contains('zveno'));
    }, timeout: const Timeout(Duration(seconds: 40)));

    test('5. Live Zveno text generation with DeepSeek V3 produces educational content', () async {
      await aiService.setProvider('zveno');
      await aiService.setZvenoModel('deepseek/deepseek-chat');

      final result = await aiService.generate(
        systemPrompt: 'Ты — строгий методист начальной школы.',
        userPrompt: 'Назови одним коротким предложением тему урока математики по сложению в 1 классе.',
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.length, greaterThan(10));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('6. Live Zveno art generation replaces YandexART producing base64 image', () async {
      await aiService.setProvider('zveno');
      await storageService.saveAiProvider('zveno');

      final base64Image = await artService.generateColoringActivity('Лесные звери на уроке счета');
      expect(base64Image, isNotNull);
      expect(base64Image!.length, greaterThan(100));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
