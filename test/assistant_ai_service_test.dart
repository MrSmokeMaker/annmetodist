import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/assistant_ai_service.dart';
import 'package:metodist/models/thematic_world.dart';

void main() {
  group('AssistantAiService Tests', () {
    late AssistantAiService service;

    setUp(() {
      service = AssistantAiService();
    });

    test('quickPrompts contains expected educational categories', () {
      final prompts = AssistantAiService.quickPrompts;
      expect(prompts.length, greaterThanOrEqualTo(5));

      final titles = prompts.map((p) => p.title).toList();
      expect(titles.any((t) => t.contains('Физкультминутка')), isTrue);
      expect(titles.any((t) => t.contains('ТРИЗ')), isTrue);
      expect(titles.any((t) => t.contains('Ловушка Незнайки')), isTrue);
      expect(titles.any((t) => t.contains('Упростить')), isTrue);
      expect(titles.any((t) => t.contains('ФГОС')), isTrue);
    });

    test('generates brain break / физкультминутка response with educational substance', () async {
      final world = ThematicWorld.allWorlds.first; // Космос
      final reply = await service.askAssistant(
        question: 'Придумай физкультминутку для детей',
        currentTopic: 'Сложение чисел в пределах 10',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
    });

    test('generates Nezhnayka trap / ловушка Незнайки response', () async {
      final world = ThematicWorld.allWorlds[1]; // Детектив
      final reply = await service.askAssistant(
        question: 'Составь ловушку Незнайки по теме',
        currentTopic: 'Безударные гласные в корне слова',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.toLowerCase().contains('незнайк') || reply.toLowerCase().contains('ошибк'), isTrue);
    });

    test('generates TRIZ problem response', () async {
      final world = ThematicWorld.allWorlds[3]; // Мастерская
      final reply = await service.askAssistant(
        question: 'Предложи ТРИЗ задачу',
        currentTopic: 'Единицы измерения длины',
        currentWorld: world,
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
    });

    test('generates simplification and adaptation response', () async {
      final reply = await service.askAssistant(
        question: 'Как упростить задание для слабого ученика?',
        currentTopic: 'Таблица умножения',
      );

      expect(reply.isNotEmpty, isTrue);
      expect(reply.length, greaterThan(30));
      expect(
        reply.toLowerCase().contains('умножен') ||
        reply.toLowerCase().contains('палочк') ||
        reply.toLowerCase().contains('шаг') ||
        reply.toLowerCase().contains('ученик'),
        isTrue,
      );
    });
  });
}
