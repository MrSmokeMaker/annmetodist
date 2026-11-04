import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/app_story.dart';
import 'package:metodist/models/topic.dart';
import 'package:metodist/providers/app_provider.dart';
import 'package:metodist/data/method_repository.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/prompt_builder.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/assistant_ai_service.dart';

class TestMockMethodRepository extends MethodRepository {
  final List<Topic> _mockTopics;

  TestMockMethodRepository(this._mockTopics);

  @override
  List<Topic> getTopicsByFilter({required String methodId, required String ageGroup}) {
    return _mockTopics
        .where((t) => t.methodId == methodId && t.ageGroup == ageGroup)
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('International & Rural Education Tests', () {
    test('1. singapore_cpa method is defined in assets/data/methods.json', () {
      final file = File('assets/data/methods.json');
      expect(file.existsSync(), isTrue);

      final jsonString = file.readAsStringSync();
      final methods = json.decode(jsonString) as List<dynamic>;

      final singapore = methods.firstWhere(
        (m) => m['id'] == 'singapore_cpa',
        orElse: () => null,
      );

      expect(singapore, isNotNull);
      expect(singapore['name'], contains('Сингапурский'));
      expect(singapore['description'], contains('CPA'));
      expect(singapore['promptBlock'], contains('CPA'));
      expect(singapore['promptBlock'], contains('PISA'));
    });

    test('2. AppProvider maps singapore_cpa to math topics', () {
      final mockMathTopics = [
        Topic(
          id: 'pchelko_math_grade_1_1',
          methodId: 'pchelko_math',
          ageGroup: 'grade_1',
          title: 'Счёт предметов в пределах 10',
          description: 'Первичное знакомство с числом',
        ),
        Topic(
          id: 'pchelko_math_grade_2_1',
          methodId: 'pchelko_math',
          ageGroup: 'grade_2',
          title: 'Сложение с переходом через десяток',
          description: 'Десятичный состав',
        ),
      ];

      final repo = TestMockMethodRepository(mockMathTopics);
      final provider = AppProvider(
        storageService: StorageService(),
        methodRepository: repo,
      );

      final grade1Topics = provider.getTopicsFor('singapore_cpa', 'grade_1');
      expect(grade1Topics, isNotEmpty);
      expect(grade1Topics.first.id, 'pchelko_math_grade_1_1');

      final grade2Topics = provider.getTopicsFor('singapore_cpa', 'grade_2');
      expect(grade2Topics, isNotEmpty);
      expect(grade2Topics.first.id, 'pchelko_math_grade_2_1');
    });


    test('4. PromptBuilder includes Low-Tech Kitchen Lab and Chalkboard Canvas when ecoLowTechMode is true', () {
      final prompt = PromptBuilder.buildSystemPrompt(
        methodBlock: 'Сингапурский метод (CPA & PISA)',
        topic: 'Сложение чисел в пределах 10',
        ageGroup: '1 класс',
        duration: '40 минут',
        ecoLowTechMode: true,
      );

      expect(prompt, contains('KITCHEN LAB'));
      expect(prompt, contains('спички'));
      expect(prompt, contains('пуговицы'));
      expect(prompt, contains('Zero-Paper'));
      expect(prompt, contains('Эскиз оформления меловой доски'));
      expect(prompt, contains('Левая створка'));
      expect(prompt, contains('Центральная створка'));
      expect(prompt, contains('Правая створка'));
    });

    test('5. PromptBuilder extracts Chalkboard Layout and PISA Life Case correctly', () {
      const sampleText = '''
# Урок математики
Введение в сложение.

[CHALKBOARD_LAYOUT]
Панель 1: Числовой ряд 1..10.
Панель 2: Формула 5 + 3 = 8 с полоской Bar Model.
Панель 3: 3 примера для самопроверки в тетрадях.
[/CHALKBOARD_LAYOUT]

[PISA_LIFE_CASE]
Семья фермера собирает яблоки в ящики. В красном ящике 5 кг, в зелёном 3 кг. Сколько всего кг?
[/PISA_LIFE_CASE]

Заключение урока.
''';

      final chalkboard = PromptBuilder.extractChalkboardLayout(sampleText);
      expect(chalkboard, isNotNull);
      expect(chalkboard, contains('Панель 1: Числовой ряд'));
      expect(chalkboard, contains('Панель 3: 3 примера'));

      final pisaCase = PromptBuilder.extractPisaLifeCase(sampleText);
      expect(pisaCase, isNotNull);
      expect(pisaCase, contains('фермера собирает яблоки'));
    });

    test('6. PdfExportService generates valid Eco-Print 2-in-1 PDF bytes', () async {
      final conspect = Conspect(
        id: 'test_eco_1',
        title: 'Тест эко-печати: Состав числа 7',
        methodId: 'singapore_cpa',
        methodName: 'Сингапурский метод (CPA & PISA)',
        subject: 'Математика',
        ageGroup: 'grade_1',
        topic: 'Состав числа 7',
        duration: '40 мин',
        content: '''
## Цель урока
Познакомить учеников с составом числа 7.

## Этап 1: Предметный (Concrete)
Раскладываем 7 фасолин на 2 группы (3 и 4, 5 и 2).

## Этап 2: Схематический (Pictorial)
Зарисовываем полоски Bar Model.

## Домашнее задание
Уровень 1: 3 примера на сложение до 7.
Уровень 2: Придумать задачу про сбор урожая.
''',
        createdAt: DateTime.now(),
      );

      final pdfBytes = await PdfExportService.generateEcoPrint2in1PdfBytes(conspect);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      // PDF magic header %PDF-
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });

    test('7. AssistantAiService contains rural mentoring and Singapore CPA quick prompts', () {
      final prompts = AssistantAiService.quickPrompts;
      expect(prompts.any((p) => p.title.contains('ЗПР / ОВЗ')), isTrue);
      expect(prompts.any((p) => p.title.contains('Пособие из подручных средств')), isTrue);
      expect(prompts.any((p) => p.title.contains('Сингапурский CPA-мостик')), isTrue);
      expect(prompts.any((p) => p.title.contains('PISA-кейс в селе')), isTrue);
    });

    test('8. AppStoriesData contains singapore_pisa story group with 2 slides', () {
      final stories = AppStoriesData.getSampleStories();
      final singaporeStory = stories.firstWhere(
        (s) => s.id == 'singapore_pisa',
        orElse: () => throw Exception('Story group singapore_pisa not found'),
      );

      expect(singaporeStory.title, contains('Сингапур & PISA'));
      expect(singaporeStory.slides.length, 2);
      expect(singaporeStory.slides[0].title, contains('Сингапурский метод'));
      expect(singaporeStory.slides[1].title, contains('Функциональная грамотность'));
      expect(singaporeStory.slides[1].badge, contains('СЕЛЬСКАЯ ЛАБОРАТОРИЯ'));
    });
  });
}
