import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/lesson_context_service.dart';

void main() {
  group('LessonContextService Unit Tests', () {
    test('estimateTokenCount estimates Russian tokens with morphology ratio', () {
      const sampleText = 'Учитель: "Ребята, посмотрите на наш числовой домик. На крыше живёт число 6."';
      final tokens = LessonContextService.estimateTokenCount(sampleText);

      expect(tokens, greaterThan(10));
      expect(tokens, lessThan(35));
    });

    test('evaluateLessonParams verifies deep lesson (2000-3000 words) fits in YandexGPT Pro 8k limit', () {
      final estimate = LessonContextService.evaluateLessonParams(
        modelName: 'yandexgpt',
        isDeepLesson: true,
        variantsCount: 1,
      );

      expect(estimate.estimatedWords, equals(2600));
      expect(estimate.estimatedTokens, greaterThan(3000));
      expect(estimate.estimatedTokens, lessThan(4200));
      expect(estimate.modelContextLimit, equals(8000));
      expect(estimate.fitsInContext, isTrue);
      expect(estimate.contextUsagePercent, lessThan(60.0));
      expect(estimate.statusDescription, contains('полной безопасности'));
    });

    test('evaluateLessonParams detects chunking requirement for small context limits', () {
      final estimate = LessonContextService.evaluateLessonParams(
        modelName: 'yandexgpt-lite', // 4000 limit
        isDeepLesson: true,
        variantsCount: 1,
      );

      expect(estimate.modelContextLimit, equals(4000));
      expect(estimate.requiresChunking, isTrue);
    });

    test('splitIntoLogicalChunks and assembleChunks work seamlessly', () {
      const fullLesson = '''
# Цель и задачи занятия
Обучающие, развивающие и воспитательные цели.

# Ход занятия
Учитель: "Здравствуйте, дети!"
Дети: "Здравствуйте!"

# Лист заданий для печати
Уровень 1: Старт
Задание 1: Образец решения.

# Домашняя работа
Памятка для родителей и тренировочные упражнения.
''';

      final chunks = LessonContextService.splitIntoLogicalChunks(fullLesson);
      expect(chunks.length, greaterThanOrEqualTo(2));

      final assembled = LessonContextService.assembleChunks(chunks);
      expect(assembled, contains('# Цель и задачи занятия'));
      expect(assembled, contains('# Ход занятия'));
      expect(assembled, contains('# Лист заданий для печати'));
      expect(assembled, contains('# Домашняя работа'));
    });
  });
}
