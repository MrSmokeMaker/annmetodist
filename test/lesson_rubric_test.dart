import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/lesson_rubric_service.dart';

void main() {
  group('LessonRubricService Unit Tests', () {
    test('evaluateLesson calculates 5 criteria and overall score correctly for deep lesson', () {
      final buffer = StringBuffer();
      buffer.writeln('# Цель и задачи занятия');
      buffer.writeln('Обучающие задачи: освоить состав числа 6. Развивающие: логическое мышление. Воспитательные: интерес к математике.');
      buffer.writeln('\n# Теоретическое обоснование и глубокое объяснение темы');
      buffer.writeln('Главное правило урока: целое состоит из частей. Ловушка для внимательных: не путать знак плюс и равно.');
      buffer.writeln('\n# Ход занятия [Тайминг: 45 мин]');
      buffer.writeln('Учитель: "Ребята, посмотрите на домик!"');
      buffer.writeln('Дети хором: "Мы готовы!"');
      buffer.writeln('Двигательная пауза и разминка для пальчиков: раз, два, три, руки подними.');
      buffer.writeln('\n# Лист заданий для печати');
      buffer.writeln('Уровень 1: Старт. Образец: 4 + 2 = 6.');
      buffer.writeln('Уровень 2: Практик. Слова для распределения: 1, 2, 3, 4, 5.');
      buffer.writeln('Уровень 3: Детектив Pro. Шифровка и логическая задача.');
      buffer.writeln('Самооценка и рефлексия: ⭐⭐⭐');
      buffer.writeln('🔑 Ключи и ответы для учителя: 1) 6, 2) 4.');
      buffer.writeln('\n# Домашняя работа');
      buffer.writeln('Памятка для родителей: хвалите ребенка за старание.');

      // Add filler words to reach deep lesson volume
      for (int i = 0; i < 300; i++) {
        buffer.writeln('Учитель подробно поясняет дидактический шаг номер $i и дети внимательно записывают в тетради.');
      }

      final content = buffer.toString();
      final eval = LessonRubricService.evaluateLesson(
        content: content,
        topic: 'Состав числа 6',
        ageGroup: 'grade_1',
        subject: 'Математика',
        methodName: 'Методика А.С. Пчелко',
      );

      expect(eval.criteria.length, equals(5));
      expect(eval.overallScore, greaterThanOrEqualTo(8.5));
      expect(eval.testQuestions.length, equals(8)); // 5 multiple-choice + 3 open questions
      expect(eval.testQuestions.first.options.length, equals(4));
      expect(eval.testQuestions.last.isOpenQuestion, isTrue);
      expect(eval.isGood, isTrue);
    });
  });
}
