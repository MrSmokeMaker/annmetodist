import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/constants.dart';
import 'package:metodist/services/interactive_quiz_export_service.dart';
import 'package:metodist/services/prompt_builder.dart';

void main() {
  group('InteractiveQuizExportService Tests', () {
    const sampleContent = '''
# Конспект занятия: Состав числа 5
**Главное правило урока:** Число 5 состоит из 1 и 4, 2 и 3, 3 и 2, 4 и 1.
Незнайка говорит: "Число 5 состоит из 2 и 4!"
Шифровка:
Найди секретный код замка: сложение цифр в кружочках.
    ''';

    test('extractQuizQuestions parses rules, traps, and ciphers correctly', () {
      final questions = InteractiveQuizExportService.extractQuizQuestions(
        content: sampleContent,
        topic: 'Состав числа 5',
        subject: 'Математика',
        ageGroup: '1 класс',
      );

      expect(questions.isNotEmpty, isTrue);
      // Verify trap question was generated
      final hasTrap = questions.any((q) => q.question.contains('Незнайка'));
      expect(hasTrap, isTrue);

      // Verify rule question was generated
      final hasRule = questions.any((q) => q.question.contains('правило'));
      expect(hasRule, isTrue);

      // Verify cipher question
      final hasCipher = questions.any((q) => q.question.contains('шифровка') || q.question.contains('секрет'));
      expect(hasCipher, isTrue);
    });

    test('formatForTelegramQuiz outputs correct Markdown and answers', () {
      final questions = InteractiveQuizExportService.extractQuizQuestions(
        content: sampleContent,
        topic: 'Состав числа 5',
        subject: 'Математика',
        ageGroup: '1 класс',
      );

      final tgText = InteractiveQuizExportService.formatForTelegramQuiz(questions, 'Состав числа 5');
      expect(tgText.contains('Telegram-викторина'), isTrue);
      expect(tgText.contains('Вопрос 1:'), isTrue);
      expect(tgText.contains('✅'), isTrue);
      expect(tgText.contains('💡'), isTrue);
    });

    test('formatForYandexForms outputs structured form text', () {
      final questions = InteractiveQuizExportService.extractQuizQuestions(
        content: sampleContent,
        topic: 'Состав числа 5',
        subject: 'Математика',
        ageGroup: '1 класс',
      );

      final yandexText = InteractiveQuizExportService.formatForYandexForms(questions, 'Состав числа 5');
      expect(yandexText.contains('Яндекс.Формы'), isTrue);
      expect(yandexText.contains('ВЕРНЫЙ - 1 балл'), isTrue);
    });

    test('formatToJson outputs valid JSON structure', () {
      final questions = InteractiveQuizExportService.extractQuizQuestions(
        content: sampleContent,
        topic: 'Состав числа 5',
        subject: 'Математика',
        ageGroup: '1 класс',
      );

      final jsonStr = InteractiveQuizExportService.formatToJson(questions, 'Состав числа 5');
      expect(jsonStr.contains('"topic": "Состав числа 5"'), isTrue);
      expect(jsonStr.contains('"questions":'), isTrue);
      expect(jsonStr.contains('"correct_option_id": 0'), isTrue);
    });
  });

  group('PromptBuilder Advanced Directives Tests', () {
    test('buildEnhancedPrompt includes inclusion mode directives', () {
      final prompt = PromptBuilder.buildEnhancedPrompt(
        methodBlock: 'Пчёлко А.С. Методика преподавания арифметики',
        topic: 'Число и цифра 5',
        subject: 'Математика',
        ageGroup: '1 класс',
        duration: '40 мин',
        inclusionMode: true,
      );

      final systemPrompt = prompt['systemPrompt']!;
      expect(systemPrompt.contains('РЕЖИМ НЕЙРОАДАПТАЦИИ И ИНКЛЮЗИИ'), isTrue);
      expect(systemPrompt.contains('ОВЗ / СДВГ'), isTrue);
      expect(systemPrompt.contains('микро-пауз'), isTrue);
    });

    test('buildEnhancedPrompt contains attention hooks and descriptors', () {
      final prompt = PromptBuilder.buildEnhancedPrompt(
        methodBlock: 'Костин Н.А. Методика русского языка',
        topic: 'Правописание ЖИ-ШИ',
        subject: 'Русский язык',
        ageGroup: '1 класс',
        duration: '40 мин',
      );

      final systemPrompt = prompt['systemPrompt']!;
      expect(systemPrompt.contains('КРЮЧКИ ВНИМАНИЯ'), isTrue);
      expect(systemPrompt.contains('РИФМОВКИ'), isTrue);
      expect(systemPrompt.contains('ДЕЙСТВИЙ ДЛЯ ЭЛЕКТРОННОГО ЖУРНАЛА'), isTrue);
    });

    test('buildEnhancedPrompt contains SanPiN badge and helper card directives', () {
      final prompt = PromptBuilder.buildEnhancedPrompt(
        methodBlock: 'Пчёлко А.С. Методика преподавания арифметики',
        topic: 'Вычитание чисел',
        subject: 'Математика',
        ageGroup: '1 класс',
        duration: '40 мин',
        materials: {GenerationType.worksheet, GenerationType.homework},
      );

      final systemPrompt = prompt['systemPrompt']!;
      expect(systemPrompt.contains('НОРМАТИВ САНПИН 10–15 МИНУТ'), isTrue);
      expect(systemPrompt.contains('ОТРЕЗНАЯ КАРТОЧКА-ПОМОЩНИЦА'), isTrue);
      expect(systemPrompt.contains('ТРЕКЕР ПРИВЫЧЕК НА ХОЛОДИЛЬНИК'), isTrue);
    });
  });

  group('GenerationType Enum and Constants Tests', () {
    test('GenerationType includes conspect, worksheet and homework with correct attributes', () {
      final worksheet = GenerationType.worksheet;
      expect(worksheet.label, equals('Лист заданий'));
      expect(worksheet.description.isNotEmpty, isTrue);
    });
  });
}
