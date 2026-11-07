import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/data/method_repository.dart';
import 'package:metodist/models/method_prompt.dart';
import 'package:metodist/providers/app_provider.dart';
import 'package:metodist/services/ai_service.dart';
import 'package:metodist/services/assistant_ai_service.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  group('Gemini in AI Assistant and Lesson Generation Live Verification', () {
    late StorageService storageService;
    late YandexGptService yandexGptService;
    late AiService aiService;
    late MethodRepository methodRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
      yandexGptService = YandexGptService(storageService: storageService);
      aiService = AiService(
        storageService: storageService,
        yandexGptService: yandexGptService,
      );
      methodRepository = MethodRepository();
    });

    test('1. Gemini is active provider and connection via Edge-proxy is healthy', () async {
      expect(storageService.getAiProvider(), equals('gemini'));
      expect(aiService.activeProvider, equals('gemini'));

      final conn = await aiService.testConnection();
      expect(conn['success'], isTrue, reason: 'Gemini Edge-proxy connection failed: ${conn['message']}');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('2. AI Assistant (Совёнок) generates live answers using Gemini', () async {
      final assistantService = AssistantAiService(
        storageService: storageService,
        aiService: aiService,
      );

      final reply = await assistantService.askAssistant(
        question: 'Предложи 2 коротких двигательных упражнения для физкультминутки на уроке счёта.',
        currentTopic: 'Сложение до 10',
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('3. Lesson generation end-to-end runs successfully via Gemini', () async {
      final appProvider = AppProvider(
        storageService: storageService,
        methodRepository: methodRepository,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(appProvider.activeAiProvider, equals('gemini'));

      const testMethod = MethodPrompt(
        id: 'pchelko',
        name: 'Методика А.С. Пчёлко',
        subject: 'Математика',
        description: 'Классическая методика арифметики',
        promptBlock: 'Используй наглядность и практический счёт предметов.',
      );

      final conspect = await appProvider.generateConspect(
        method: testMethod,
        ageGroup: '1_class',
        topicTitle: 'Сложение чисел в пределах 5',
        duration: '40',
        useEnhancedPrompts: true,
      );

      expect(conspect.title, contains('Сложение чисел в пределах 5'));
      expect(conspect.content.isNotEmpty, isTrue);
      expect(conspect.content.length, greaterThan(200));
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
