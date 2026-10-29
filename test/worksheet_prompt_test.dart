import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/basic_task.dart';
import 'package:metodist/services/prompt_builder.dart';

void main() {
  group('Worksheet Prompt and Task Model Tests', () {
    test('PromptBuilder contains 6 didactic mechanics and age adaptation', () {
      final prompt = PromptBuilder.defaultTemplate;

      expect(prompt.contains('[СОЕДИНИ СТРЕЛКАМИ]'), isTrue);
      expect(prompt.contains('[СОРТИРОВОЧНАЯ ТАБЛИЦА / МАТРИЦА]'), isTrue);
      expect(prompt.contains('[ЛОВУШКА НЕЗНАЙКИ]'), isTrue);
      expect(prompt.contains('[ЧИСЛОВОЙ ДОМИК / ГРАФОМОТОРНАЯ ДОРОЖКА]'), isTrue);
      expect(prompt.contains('[ШИФРОВКА ИЛИ КРОССВОРД]'), isTrue);
      expect(prompt.contains('[КОРЗИНКА СЛОВ ДЛЯ СПРАВОК]'), isTrue);

      // Проверка возрастных акцентов
      expect(prompt.contains('Дошкольники (4–6 лет)'), isTrue);
      expect(prompt.contains('1 класс'), isTrue);
      expect(prompt.contains('2 класс'), isTrue);
    });

    test('BASIC_TASKS contains enriched interactive tasks', () {
      final taskIds = BASIC_TASKS.map((t) => t.id).toSet();

      expect(taskIds.contains('matching_pairs'), isTrue);
      expect(taskIds.contains('bug_hunt'), isTrue);
      expect(taskIds.contains('number_house'), isTrue);
      expect(taskIds.contains('cipher_code'), isTrue);
      expect(taskIds.contains('word_bank_fill'), isTrue);
    });
  });
}
