import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/method_prompt.dart';
import 'package:metodist/models/quarter_plan.dart';
import 'package:metodist/models/topic.dart';
import 'package:metodist/services/ai_service.dart';
import 'package:metodist/services/quarter_planning_service.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuarterPlanningService service;
  late MethodPrompt sampleMethod;
  late List<Topic> sampleTopics;

  setUp(() {
    final storage = StorageService();
    final gpt = YandexGptService(storageService: storage);
    final ai = AiService(storageService: storage, yandexGptService: gpt);
    service = QuarterPlanningService(aiService: ai);

    sampleMethod = const MethodPrompt(
      id: 'pchelko_math',
      name: 'Арифметика Пчёлко',
      subject: 'Математика',
      description: 'Советская классическая методика',
      promptBlock: 'Методика Пчёлко',
    );

    sampleTopics = [
      const Topic(id: 't1', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Счёт предметов до 10'),
      const Topic(id: 't2', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Число и цифра 5'),
      const Topic(id: 't3', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Состав числа 6'),
      const Topic(id: 't4', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Сложение и вычитание в пределах 10'),
      const Topic(id: 't5', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Решение текстовых задач на сложение'),
      const Topic(id: 't6', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Сравнение чисел с помощью знаков > < ='),
      const Topic(id: 't7', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Дециметр и измерение отрезков'),
      const Topic(id: 't8', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Числовые домики и закрепление'),
      const Topic(id: 't9', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Увеличение и уменьшение на несколько единиц'),
      const Topic(id: 't10', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Обобщающий практикум за 1 четверть'),
    ];
  });

  group('QuarterPlanningService Tests', () {
    test('1. Creates quarter plan with specified lessons count', () async {
      final plan = await service.createQuarterPlan(
        method: sampleMethod,
        ageGroup: '1 класс',
        quarterNumber: 1,
        lessonsCount: 8,
        repositoryTopics: sampleTopics,
        useAi: false,
      );

      expect(plan.quarterNumber, equals(1));
      expect(plan.topics.length, equals(8));
      expect(plan.topics.first.lessonIndex, equals(1));
      expect(plan.topics.last.lessonIndex, equals(8));
      expect(plan.completedLessons, equals(0));
      expect(plan.progress, equals(0.0));
      expect(plan.topics.first.title.isNotEmpty, isTrue);
    });

    test('2. Replaces topic with an alternative topic from repository pool', () async {
      final plan = await service.createQuarterPlan(
        method: sampleMethod,
        ageGroup: '1 класс',
        quarterNumber: 1,
        lessonsCount: 8,
        repositoryTopics: sampleTopics,
        useAi: false,
      );

      final originalTitle = plan.topics[2].title;
      final altTopic = await service.getAlternativeTopic(
        plan: plan,
        targetIndex: 2,
        repositoryTopics: sampleTopics,
      );

      expect(altTopic.isNotEmpty, isTrue);
      expect(altTopic, isNot(equals(originalTitle)));
    });

    test('3. Validates lesson completeness correctly (missing sections and answer leaks)', () {
      // 3.1 Полный идеальный конспект
      const completeLesson = '''
# Цель и задачи занятия
Обучающая цель: научить составу числа 5.

# Теоретическое обоснование и глубокое объяснение темы
Число 5 состоит из 4 и 1, 3 и 2.

# Ход занятия
[Тайминг: 10 мин] Вводная часть.
Учитель: "Ребята, сколько пальцев на руке?"
Дети: "Пять!"
Длинный подробный сценарий урока с разминками и играми...
Текст сценария продолжается подробно, чтобы превысить минимальный норматив знаков.
Пошаговая дословная речь учителя и учеников.

# Лист заданий для печати
Задание 1. Засели домик.
Задание 2. Сравни выражения.
## 🔑 Ключи и ответы для учителя:
Ответы: 4+1, 3+2.

# Домашняя работа
Памятка родителям. Трекер.
''';

      final res1 = service.validateLessonCompleteness(completeLesson);
      expect(res1.isValid, isTrue);
      expect(res1.missingSections.isEmpty, isTrue);
      expect(res1.hasAnswerLeaks, isFalse);

      // 3.2 Конспект с пропущенной домашкой и утечкой ответа
      const brokenLesson = '''
# Цель и задачи занятия
Цель: сложение.
# Теоретическое обоснование
Теория.
# Ход занятия
Учитель спросил.
# Лист заданий
Задание 1: Сколько будет 2+2? (ответ: 4)
## 🔑 Ключи
4.
''';

      final res2 = service.validateLessonCompleteness(brokenLesson);
      expect(res2.isValid, isFalse);
      expect(res2.missingSections.contains('Домашняя работа'), isTrue);
      expect(res2.hasAnswerLeaks, isTrue);
    });

    test('4. Calculates schedule dates evenly across chosen weekdays', () {
      final startDate = DateTime(2026, 9, 1); // 1 сентября 2026 (Вторник)
      final weekdays = [DateTime.monday, DateTime.wednesday, DateTime.friday];

      final dates = service.calculateScheduleDates(
        startDate: startDate,
        weekdays: weekdays,
        totalLessons: 6,
      );

      expect(dates.length, equals(6));
      for (final d in dates) {
        expect(weekdays.contains(d.weekday), isTrue,
            reason: 'Date $d must be on Monday, Wednesday, or Friday');
      }
      // Проверяем хронологический порядок
      for (int i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isTrue);
      }
    });
  });
}
