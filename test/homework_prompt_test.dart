import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/prompt_builder.dart';

void main() {
  group('Homework Prompt and Template Tests', () {
    test('PromptBuilder contains modern homework structure requirements', () {
      final prompt = PromptBuilder.defaultTemplate;

      // 1. Памятка для родителей и регламент времени
      expect(prompt.contains('ПАМЯТКА ДЛЯ РОДИТЕЛЕЙ'), isTrue);
      expect(prompt.contains('1-минутный скрипт'), isTrue);
      expect(prompt.contains('Ориентир времени:'), isTrue);

      // 2. Три смысловых блока домашнего задания
      expect(prompt.contains('Блок 1: Тренировка'), isTrue);
      expect(prompt.contains('Блок 2: Исследование в быту'), isTrue);
      expect(prompt.contains('Блок 3: Семейный вызов'), isTrue);

      // 3. Минимизация рутинного письма
      expect(prompt.contains('Минимум ручного письма'), isTrue);

      // 4. Талон обратной связи родителя учителю
      expect(prompt.contains('ТАЛОН ОБРАТНОЙ СВЯЗИ УЧИТЕЛЮ'), isTrue);
      expect(prompt.contains('Время выполнения:'), isTrue);
      expect(prompt.contains('Сложность:'), isTrue);
      expect(prompt.contains('Вопрос или комментарий учителю:'), isTrue);
      expect(prompt.contains('Подпись родителя:'), isTrue);
    });
  });
}
