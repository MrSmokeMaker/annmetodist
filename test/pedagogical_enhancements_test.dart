import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/pedagogical_golden_standards.dart';
import 'package:metodist/services/fact_verification_service.dart';
import 'package:metodist/services/prompt_builder.dart';
import 'package:metodist/services/lesson_duration_service.dart';

void main() {
  group('1. Two-Step Generation (Plan-then-Write)', () {
    test('buildArchitecturePlanPrompt generates valid Blueprint prompt', () {
      final prompt = PromptBuilder.buildArchitecturePlanPrompt(
        methodBlock: 'Петерсон: деятельностный подход',
        topic: 'Сложение с переходом через десяток',
        ageGroup: '1 класс',
        duration: '40 минут',
        subject: 'Математика',
      );

      expect(prompt['systemPrompt'], contains('архитектурный план (Blueprint)'));
      expect(prompt['systemPrompt'], contains('СКВОЗНАЯ СЮЖЕТНАЯ КАНВА'));
      expect(prompt['systemPrompt'], contains('ДИДАКТИЧЕСКОЕ ЯДРО'));
      expect(prompt['systemPrompt'], contains('ПОМИНУТНЫЙ МЕТОДИЧЕСКИЙ МАРШРУТ'));
      expect(prompt['userPrompt'], contains('Сложение с переходом через десяток'));
    });

    test('buildConspectFromPlanPrompt bundles architecture plan into execution prompt', () {
      final basePrompt = {
        'systemPrompt': 'Ты — методист высшей категории.',
        'userPrompt': 'Составь урок по теме "Состав числа 7".',
      };

      const mockPlan = '''
1. Легенда: "Академия волшебных чисел"
2. Дидактическое ядро: 7 это 4 да 3. Ловушка Незнайки: 4 + 2 = 7.
3. Маршрут: 1) Мотивация 5м, 2) Нейрогимнастика 3м, 3) Открытие 15м, 4) Физкультминутка 3м, 5) Закрепление 10м, 6) Рефлексия 4м.
''';

      final finalPrompt = PromptBuilder.buildConspectFromPlanPrompt(
        architecturePlan: mockPlan,
        baseEnhancedPrompt: basePrompt,
      );

      expect(finalPrompt['systemPrompt'], contains('УТВЕРЖДЕННЫЙ АРХИТЕКТУРНЫЙ КАРКАС УРОКА (BLUEPRINT)'));
      expect(finalPrompt['systemPrompt'], contains('Академия волшебных чисел'));
      expect(finalPrompt['userPrompt'], equals(basePrompt['userPrompt']));
    });
  });

  group('2. Few-Shot Golden Standards Library', () {
    test('Math standard provides Peterson Socratic dialogue', () {
      final standard = PedagogicalGoldenStandards.getGoldenStandard(subject: 'Математика');
      expect(standard, contains('ЗОЛОТОЙ ЭТАЛОН ПЕДАГОГИЧЕСКОГО ДИАЛОГА: МАТЕМАТИКА'));
      expect(standard, contains('сократовский перехват сомнения'));
      expect(standard, contains('числовой домик'));
    });

    test('Russian language standard provides Mazina/Kostin orthographic dialogue', () {
      final standard = PedagogicalGoldenStandards.getGoldenStandard(subject: 'Русский язык');
      expect(standard, contains('ЗОЛОТОЙ ЭТАЛОН ПЕДАГОГИЧЕСКОГО ДИАЛОГА: РУССКИЙ ЯЗЫК'));
      expect(standard, contains('Глухой звук [п]'));
      expect(standard, contains('сорвать маску с хитрого звука'));
    });

    test('World exploration standard provides Zankov scientific discovery dialogue', () {
      final standard = PedagogicalGoldenStandards.getGoldenStandard(subject: 'Окружающий мир');
      expect(standard, contains('ЗОЛОТОЙ ЭТАЛОН ПЕДАГОГИЧЕСКОГО ДИАЛОГА: ОКРУЖАЮЩИЙ МИР'));
      expect(standard, contains('Солнечный свет!'));
    });

    test('buildEnhancedPrompt includes golden standard', () {
      final prompt = PromptBuilder.buildEnhancedPrompt(
        methodBlock: 'Петерсон',
        topic: 'Сложение чисел',
        ageGroup: '1 класс',
        duration: '40 минут',
        subject: 'Математика',
      );

      expect(prompt['systemPrompt'], contains('ЗОЛОТОЙ ЭТАЛОН ПЕДАГОГИЧЕСКОГО ДИАЛОГА'));
    });
  });

  group('3. FactVerificationService Guardrails', () {
    test('Corrects arithmetic calculation errors in math tasks', () {
      const wrongMath = '''
Пример 1: 7 + 5 = 11 (ошибка модели)
Пример 2: 12 - 4 = 8 (верно)
Пример 3: 6 * 4 = 28 (ошибка модели)
''';

      final result = FactVerificationService.verifyAndRepair(wrongMath, subject: 'Математика');
      expect(result.hasCorrections, isTrue);
      expect(result.repairedContent, contains('7 + 5 = 12'));
      expect(result.repairedContent, contains('12 - 4 = 8'));
      expect(result.repairedContent, contains('6 * 4 = 24'));
      expect(result.appliedCorrections.length, equals(2));
    });

    test('Corrects Russian phonetic and grammar misconceptions', () {
      const wrongGrammar = '''
В русском языке 10 гласных звуков.
Помните, что звук [й] бывает твёрдым в некоторых словах.
Также звуки [ж] и [ш] бывают мягкими.
''';

      final result = FactVerificationService.verifyAndRepair(wrongGrammar, subject: 'Русский язык');
      expect(result.hasCorrections, isTrue);
      expect(result.repairedContent, contains('10 гласных букв и 6 основных гласных звуков'));
      expect(result.repairedContent, contains('звук [й\'] всегда мягкий непарный'));
      expect(result.repairedContent, contains('звуки [ж] и [ш] всегда твёрдые непарные'));
    });

    test('Sanitizes leaked answers and placeholders from worksheet body', () {
      const leakedWorksheet = '''
### Задание 1. Подбери проверочное слово
Слово: гриб (ответ: грибок)
Подбери [вставьте слово] для проверки.
''';

      final result = FactVerificationService.verifyAndRepair(leakedWorksheet, subject: 'Русский язык');
      expect(result.hasCorrections, isTrue);
      expect(result.repairedContent, isNot(contains('(ответ: грибок)')));
      expect(result.repairedContent, isNot(contains('[вставьте слово]')));
      expect(result.repairedContent, contains('______'));
      expect(result.repairedContent, contains('________________'));
    });
  });

  group('4. Lesson Duration Profile & Character Scaling', () {
    test('LessonDurationProfile scales volume and tasks correctly between 20 min and 60 min', () {
      final shortLesson = LessonDurationProfile.fromDurationString('20 минут');
      final longLesson = LessonDurationProfile.fromDurationString('60 минут');

      // 20 min lesson
      expect(shortLesson.totalMinutes, equals(20));
      expect(shortLesson.targetCharactersRange, contains('1800–2800'));
      expect(shortLesson.targetStagesCount, equals(4));
      expect(shortLesson.worksheetTasksCount, equals(3));

      // 60 min lesson
      expect(longLesson.totalMinutes, equals(60));
      expect(longLesson.targetCharactersRange, contains('7000–9800'));
      expect(longLesson.targetStagesCount, equals(7));
      expect(longLesson.worksheetTasksCount, equals(8));

      // Significant difference in character bounds
      expect(longLesson.minCharacters, greaterThan(shortLesson.maxCharacters * 2));
    });

    test('buildSystemPrompt injects duration-specific character volume', () {
      final prompt20 = PromptBuilder.buildSystemPrompt(
        methodBlock: 'Петерсон',
        topic: 'Число 5',
        ageGroup: 'Дошкольники',
        duration: '20 минут',
      );

      final prompt60 = PromptBuilder.buildSystemPrompt(
        methodBlock: 'Петерсон',
        topic: 'Уравнения',
        ageGroup: '4 класс',
        duration: '60 минут',
      );

      expect(prompt20, contains('1800–2800 знаков'));
      expect(prompt20, contains('СТРУКТУРА НА 20 МИНУТ'));
      expect(prompt60, contains('7000–9800 знаков'));
      expect(prompt60, contains('СТРУКТУРА НА 60 МИНУТ'));
    });

    test('buildUserPrompt adapts worksheet tasks count to lesson duration', () {
      final userPrompt20 = PromptBuilder.buildUserPrompt(
        methodName: 'Петерсон',
        topic: 'Число 5',
        ageGroup: 'Дошкольники',
        duration: '20 минут',
      );

      final userPrompt60 = PromptBuilder.buildUserPrompt(
        methodName: 'Петерсон',
        topic: 'Уравнения',
        ageGroup: '4 класс',
        duration: '60 минут',
      );

      expect(userPrompt20, contains('ровно 3 упражнения под длительность 20 мин'));
      expect(userPrompt60, contains('ровно 8 упражнения под длительность 60 мин'));
    });
  });
}
