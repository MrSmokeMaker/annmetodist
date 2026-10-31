import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/assistant_ai_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/models/thematic_world.dart';

/// Mock сервис, симулирующий оффлайн/фоллбек режим
class MockOfflineGptService extends YandexGptService {
  MockOfflineGptService() : super(storageService: StorageService());

  @override
  Future<String> generateConspect({
    required String systemPrompt,
    required String userPrompt,
    String model = YandexGptService.defaultModel,
    double temperature = 0.6,
    int maxTokens = 8000,
  }) async {
    // Вызывает переход в умный педагогический fallback Совёнка
    throw Exception('Offline mode simulation for deterministic fallback testing');
  }
}

void main() {
  group('AssistantAiService Offline Fallback Tests (Deterministic)', () {
    late AssistantAiService offlineService;

    setUp(() {
      offlineService = AssistantAiService(gptService: MockOfflineGptService());
    });

    test('quickPrompts contains expected educational categories and modes', () {
      final prompts = AssistantAiService.quickPrompts;
      expect(prompts.length, greaterThanOrEqualTo(8));

      final titles = prompts.map((p) => p.title).toList();
      expect(titles.any((t) => t.contains('Пост в чат родителей')), isTrue);
      expect(titles.any((t) => t.contains('3 уровня ДЗ')), isTrue);
      expect(titles.any((t) => t.contains('Сюжетный квест')), isTrue);
      expect(titles.any((t) => t.contains('Экспресс-тест')), isTrue);
      expect(titles.any((t) => t.contains('Вводное слово')), isTrue);
      expect(titles.any((t) => t.contains('Физкультминутка')), isTrue);
      expect(titles.any((t) => t.contains('ТРИЗ')), isTrue);
      expect(titles.any((t) => t.contains('Ловушка Незнайки')), isTrue);
      expect(titles.any((t) => t.contains('Упростить')), isTrue);
    });

    test('generates parent chat post with warm tone and recommendations', () async {
      final world = ThematicWorld.allWorlds.first;
      final reply = await offlineService.askAssistant(
        question: 'Составь пост для родительского чата по теме',
        currentTopic: 'Таблица умножения на 3',
        currentWorld: world,
        mode: AssistantMode.parentChat,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.contains('родительского чата'), isTrue);
      expect(reply.contains('Таблица умножения на 3'), isTrue);
      expect(reply.contains('родители'), isTrue);
    });

    test('generates 3-tier differentiated homework (ФГОС, практика, ТРИЗ)', () async {
      final world = ThematicWorld.allWorlds[1];
      final reply = await offlineService.askAssistant(
        question: 'Сформируй 3 уровня домашнего задания',
        currentTopic: 'Правописание безударных гласных',
        currentWorld: world,
        mode: AssistantMode.homework,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.contains('Базовый'), isTrue);
      expect(reply.contains('Продвинутый'), isTrue);
      expect(reply.contains('ТРИЗ-вызов'), isTrue);
    });

    test('generates story quest / gamification for classroom', () async {
      final world = ThematicWorld.allWorlds[3];
      final reply = await offlineService.askAssistant(
        question: 'Придумай сюжетный квест для урока',
        currentTopic: 'Периметр многоугольника',
        currentWorld: world,
        mode: AssistantMode.gamification,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.contains('квест') || reply.contains('игра'), isTrue);
      expect(reply.contains(world.mascotName), isTrue);
    });

    test('generates express flash test with check keys', () async {
      final reply = await offlineService.askAssistant(
        question: 'Составь экспресс тест с ключами проверки',
        currentTopic: 'Сложение с переходом через десяток',
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.contains('Экспресс-тест'), isTrue);
      expect(reply.contains('Критерии оценивания'), isTrue);
      expect(reply.contains('Правильный ответ'), isTrue);
    });

    test('generates teacher intro speech for first 2 minutes of lesson', () async {
      final reply = await offlineService.askAssistant(
        question: 'Напиши вдохновляющее вводное слово учителя на начало урока',
        currentTopic: 'Гласные звуки и буквы',
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.contains('вводное слово'), isTrue);
      expect(reply.contains('исследователи'), isTrue);
    });

    test('generates brain break / физкультминутка response with educational substance', () async {
      final world = ThematicWorld.allWorlds.first;
      final reply = await offlineService.askAssistant(
        question: 'Придумай физкультминутку для детей',
        currentTopic: 'Сложение чисел в пределах 10',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
      expect(reply.contains('разминка') || reply.contains('потянемся'), isTrue);
    });

    test('generates Nezhnayka trap / ловушка Незнайки response', () async {
      final world = ThematicWorld.allWorlds[1];
      final reply = await offlineService.askAssistant(
        question: 'Составь ловушку Незнайки по теме',
        currentTopic: 'Безударные гласные в корне слова',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.toLowerCase().contains('незнайк') || reply.toLowerCase().contains('ошибк'), isTrue);
    });

    test('generates TRIZ problem response', () async {
      final world = ThematicWorld.allWorlds[3];
      final reply = await offlineService.askAssistant(
        question: 'Предложи ТРИЗ задачу',
        currentTopic: 'Единицы измерения длины',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
      expect(reply.contains('ТРИЗ') || reply.contains('Противоречие'), isTrue);
    });

    test('generates simplification and adaptation response', () async {
      final reply = await offlineService.askAssistant(
        question: 'Как упростить задание для слабого ученика?',
        currentTopic: 'Таблица умножения',
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
      expect(reply.contains('наглядность') || reply.contains('адаптация'), isTrue);
    });
  });

  group('AssistantAiService Live Response Smoke Test', () {
    test('live or fallback call completes cleanly and returns markdown', () async {
      final service = AssistantAiService();
      final reply = await service.askAssistant(
        question: 'Как поддержать первоклассника в первый месяц учебы?',
        currentTopic: 'Адаптация к школе',
      );
      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(20));
    });
  });
}
