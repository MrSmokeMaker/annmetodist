import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/pricing_plan.dart';
import 'package:metodist/models/tariff.dart';
import 'package:metodist/services/assistant_ai_service.dart';
import 'package:metodist/widgets/enhance_lesson_modal.dart';

void main() {
  group('Director Exclusivity & Tariff Verification', () {
    test('UserTariff grants MetodistAI & Deep Enhancement only to Director', () {
      const freeTariff = UserTariff(TariffLevel.free);
      expect(freeTariff.canUseMetodistAiBot, isFalse);
      expect(freeTariff.canUseDeepEnhancement, isFalse);
      expect(freeTariff.canCreateCustomActions, isFalse);

      const proTariff = UserTariff(TariffLevel.pro);
      expect(proTariff.canUseMetodistAiBot, isFalse);
      expect(proTariff.canUseDeepEnhancement, isFalse);
      expect(proTariff.canCreateCustomActions, isFalse);

      const directorTariff = UserTariff(TariffLevel.director);
      expect(directorTariff.canUseMetodistAiBot, isTrue);
      expect(directorTariff.canUseDeepEnhancement, isTrue);
      expect(directorTariff.canCreateCustomActions, isTrue);
    });

    test('PricingPlan Director prices and features match specifications', () {
      final director = PricingPlan.director;
      expect(director.monthlyPrice, 1499);
      expect(director.annualMonthlyPrice, 1199);
      expect(director.annualTotalPrice, 14388);

      final featureTexts = director.features.join(' ');
      expect(featureTexts, contains('MetodistAI'));
      expect(featureTexts, contains('Улучшить с MetodistPro AI'));
      expect(featureTexts, contains('/addaction'));
    });
  });

  group('AssistantAiService Custom Actions & Deep Enhancement Quality', () {
    late AssistantAiService service;

    setUp(() {
      service = AssistantAiService();
    });

    test('Can register and retrieve custom user actions with {topic} interpolation', () {
      final initialCount = service.getAllPrompts().length;
      service.addCustomPrompt(
        title: 'Рифмовка дня',
        prompt: 'Сочини для детей весёлую рифмовку на тему {topic}.',
      );

      final updatedPrompts = service.getAllPrompts();
      expect(updatedPrompts.length, initialCount + 1);
      final customPrompt = updatedPrompts.firstWhere((p) => p.title.contains('Рифмовка дня'));
      expect(customPrompt.isCustom, isTrue);
      expect(customPrompt.prompt, contains('{topic}'));
    });

    test('enhanceLessonWithMetodistProAi fallback produces full 6-block didactic enrichment', () async {
      final enhancedText = await service.enhanceLessonWithMetodistProAi(
        topic: 'Безударные гласные в корне слова',
        currentContent: 'Базовый конспект урока по русскому языку',
      );

      // Verify all 6 mandatory pedagogical modules are present
      expect(enhancedText, contains('Безударные гласные в корне слова'));
      expect(enhancedText, contains('Живая драматургия'));
      expect(enhancedText, contains('Тайминг:'));
      expect(enhancedText, contains('ТРИЗ'));
      expect(enhancedText, contains('Ловушка Незнайки'));
      expect(enhancedText, contains('Дифференцированное домашнее задание'));
      expect(enhancedText, contains('Готовый пост для родительского чата'));

      // Check quality hallmarks
      expect(enhancedText, contains('Учитель:'));
      expect(enhancedText, contains('Дети:'));
      expect(enhancedText, contains('Уровень 1. Базовый'));
      expect(enhancedText, contains('Уровень 2. Продвинутый'));
      expect(enhancedText, contains('Уровень 3. ТРИЗ-вызов'));
      expect(enhancedText, contains('WhatsApp / Telegram'));
    });
  });

  group('EnhanceLessonModal UI Tests', () {
    testWidgets('EnhanceLessonModal renders correctly with theme and action buttons', (tester) async {
      final dummyConspect = Conspect(
        id: 'test_c_1',
        title: 'Урок 1: Таблица умножения',
        methodId: 'pchelko',
        methodName: 'Пчёлко А.С.',
        subject: 'Математика',
        ageGroup: '2 класс',
        topic: 'Таблица умножения на 4',
        duration: '40 минут',
        content: 'Базовый конспект',
        createdAt: DateTime.now(),
      );

      String? applied;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhanceLessonModal(
              conspect: dummyConspect,
              currentContent: dummyConspect.content,
              onApplyEnhanced: (text) {
                applied = text;
              },
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text('Улучшить с MetodistPro AI'), findsOneWidget);
      expect(find.textContaining('Таблица умножения на 4'), findsOneWidget);

      // Pump through timer / async completion
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Check preview and action buttons
      expect(find.text('Скопировать'), findsOneWidget);
      expect(find.text('Применить к конспекту'), findsOneWidget);

      // Tap apply
      await tester.tap(find.text('Применить к конспекту'));
      await tester.pumpAndSettle();
      expect(applied, isNotNull);
      expect(applied, contains('Таблица умножения на 4'));
    });
  });
}
