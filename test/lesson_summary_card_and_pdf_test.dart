import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/lesson_summary_card.dart';
import 'package:metodist/models/pricing_plan.dart';
import 'package:metodist/models/scheduled_lesson.dart';
import 'package:metodist/models/tariff.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/services/assistant_ai_service.dart';
import 'package:metodist/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tariff & Permissions for Lesson Summary Card', () {
    test('canUseLessonSummaryCard is granted strictly to Metodist Pro and Director', () {
      const freeTariff = UserTariff(TariffLevel.free);
      expect(freeTariff.canUseLessonSummaryCard, isFalse);

      const practiceTariff = UserTariff(TariffLevel.practice);
      expect(practiceTariff.canUseLessonSummaryCard, isFalse);

      const proTariff = UserTariff(TariffLevel.pro);
      expect(proTariff.canUseLessonSummaryCard, isTrue);

      const directorTariff = UserTariff(TariffLevel.director);
      expect(directorTariff.canUseLessonSummaryCard, isTrue);
    });

    test('PricingPlan pro and director describe Lesson Summary Card feature', () {
      final proPlan = PricingPlan.defaultPlans.firstWhere((p) => p.id == 'pro');
      expect(proPlan.features.any((f) => f.contains('Карточка итога урока')), isTrue);

      final directorPlan = PricingPlan.director;
      expect(directorPlan.features.any((f) => f.contains('Карточка итога урока')), isTrue);
    });
  });

  group('LessonSummaryCard Model & Scoring', () {
    test('Correctly computes averageScore, masteryPercent and academicStatus', () {
      final card = LessonSummaryCard(
        scheduledLessonId: 'lesson_101',
        date: DateTime(2026, 10, 31),
        topic: 'Сложение с переходом через десяток',
        studentOrClass: '2-А класс',
        criteriaScores: {
          'Усвоение нового правила / алгоритма': 5,
          'Самостоятельность выполнения заданий': 5,
          'Активность и вовлеченность на уроке': 4,
          'Дисциплина и тайминг этапов (СанПиН)': 4,
          'Логика и решение ТРИЗ-задач / ловушек': 5,
        },
        tags: ['⭐ Блестящий ответ у доски', '💡 Отличное ТРИЗ-решение'],
        teacherNotes: 'Ребята отлично справились с опережением тайминга.',
      );

      // (5+5+4+4+5)/5 = 23/5 = 4.6
      expect(card.averageScore, closeTo(4.6, 0.01));
      // (4.6 / 5.0) * 100 = 92%
      expect(card.masteryPercent, 92);
      expect(card.academicStatus, contains('Высокий уровень усвоения'));
    });

    test('Allows adding custom criteria and custom tags', () {
      final customCard = LessonSummaryCard(
        scheduledLessonId: 'lesson_102',
        date: DateTime.now(),
        topic: 'Безударные гласные в корне',
        studentOrClass: 'Миша (1 класс)',
        criteriaScores: {
          'Каллиграфия элементов букв Мазиной': 5,
          'Слуховой самоконтроль': 4,
        },
        tags: ['📌 Занимался с увлечением', '⚠️ Нужна карточка домой'],
      );

      expect(customCard.criteriaScores.containsKey('Каллиграфия элементов букв Мазиной'), isTrue);
      expect(customCard.tags, contains('⚠️ Нужна карточка домой'));
      expect(customCard.averageScore, 4.5);
      expect(customCard.masteryPercent, 90);
    });

    test('Serializes to map and deserializes from map without data loss', () {
      final original = LessonSummaryCard(
        scheduledLessonId: 'lesson_103',
        date: DateTime(2026, 10, 30),
        topic: 'Таблица умножения на 3',
        studentOrClass: 'Иван',
        thematicWorldId: 'world_detective',
        criteriaScores: {'Алгоритм': 5, 'Скорость': 4},
        tags: ['⭐ Ответ у доски'],
        teacherNotes: 'Рекомендован уровень 3',
        homeworkAssigned: 'Уровень 3 (ТРИЗ-вызов)',
        aiReflection: 'Отличная динамика.',
        parentChatMessage: 'Здравствуйте, уважаемые родители!',
      );

      final map = original.toMap();
      final restored = LessonSummaryCard.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.topic, original.topic);
      expect(restored.studentOrClass, original.studentOrClass);
      expect(restored.thematicWorldId, 'world_detective');
      expect(restored.criteriaScores['Алгоритм'], 5);
      expect(restored.tags, contains('⭐ Ответ у доски'));
      expect(restored.homeworkAssigned, 'Уровень 3 (ТРИЗ-вызов)');
      expect(restored.aiReflection, 'Отличная динамика.');
    });
  });

  group('ScheduledLesson with LessonSummaryCard Integration', () {
    test('isPastOrToday identifies past and today lessons correctly', () {
      final now = DateTime.now();
      final pastLesson = ScheduledLesson(
        id: 'l_past',
        date: now.subtract(const Duration(days: 2)),
        time: '10:00',
        studentOrClass: '3-А',
        topic: 'Русский язык',
      );
      expect(pastLesson.isPastOrToday, isTrue);

      final todayLesson = ScheduledLesson(
        id: 'l_today',
        date: DateTime(now.year, now.month, now.day),
        time: '12:00',
        studentOrClass: '1-Б',
        topic: 'Математика',
      );
      expect(todayLesson.isPastOrToday, isTrue);

      final futureLesson = ScheduledLesson(
        id: 'l_future',
        date: now.add(const Duration(days: 5)),
        time: '14:00',
        studentOrClass: '2-В',
        topic: 'Окружающий мир',
      );
      expect(futureLesson.isPastOrToday, isFalse);
    });

    test('ScheduledLesson serializes summaryCard properly', () {
      final summary = LessonSummaryCard(
        scheduledLessonId: 'l_1',
        date: DateTime.now(),
        topic: 'Счёт',
        studentOrClass: 'Анна',
      );

      final lesson = ScheduledLesson(
        id: 'l_1',
        date: DateTime.now(),
        time: '10:00',
        studentOrClass: 'Анна',
        topic: 'Счёт',
        summaryCard: summary,
      );

      expect(lesson.hasSummaryCard, isTrue);
      final map = lesson.toMap();
      expect(map['summaryCard'], isNotNull);

      final restoredLesson = ScheduledLesson.fromMap(map);
      expect(restoredLesson.hasSummaryCard, isTrue);
      expect(restoredLesson.summaryCard?.topic, 'Счёт');
    });
  });

  group('AssistantAiService Lesson Summary Reflection (YandexGPT Pro & Fallback)', () {
    test('generateLessonSummaryReflection returns reflection and parent chat post', () async {
      final service = AssistantAiService();
      final card = LessonSummaryCard(
        scheduledLessonId: 'lesson_ai_1',
        date: DateTime.now(),
        topic: 'Безударные гласные в корне слова',
        studentOrClass: '2-Б класс',
        thematicWorldId: 'world_space',
        criteriaScores: {
          'Усвоение нового правила': 5,
          'Самостоятельность': 4,
          'ТРИЗ-задача': 5,
        },
        tags: ['⭐ Блестящий ответ у доски', '💡 Отличное ТРИЗ-решение'],
        teacherNotes: 'Занятие прошло с высоким темпом и активным участием.',
      );

      final res = await service.generateLessonSummaryReflection(
        card: card,
        world: ThematicWorld.space,
      );

      expect(res.containsKey('aiReflection'), isTrue);
      expect(res.containsKey('parentChatMessage'), isTrue);

      final reflection = res['aiReflection']!;
      expect(reflection, contains('Методический вывод'));
      expect(reflection, contains('Точки роста'));

      final parentChat = res['parentChatMessage']!;
      expect(parentChat, contains('Здравствуйте, уважаемые родители!'));
      expect(parentChat, contains('Безударные гласные в корне слова'));
    });
  });

  group('PdfExportService Mobbin Executive Lesson Summary PDF Export', () {
    test('generateLessonSummaryPdfBytes produces valid printable PDF bytes with all sections', () async {
      final card = LessonSummaryCard(
        scheduledLessonId: 'lesson_pdf_1',
        date: DateTime(2026, 10, 31),
        topic: 'Таблица умножения на 4',
        studentOrClass: 'Группа продлённого дня (2 класс)',
        thematicWorldId: 'world_workshop',
        criteriaScores: {
          'Усвоение нового правила': 5,
          'Самостоятельность': 4,
          'Активность на уроке': 5,
          'Каллиграфия цифр': 4,
        },
        tags: ['⭐ Блестящий ответ у доски', '⏱️ Опережение тайминга'],
        teacherNotes: 'Ученики уверенно воспроизводят числовой ряд четвёрки.',
        homeworkAssigned: 'Уровень 2 (Продвинутый, 10 мин)',
        aiReflection: '📌 Методический вывод: великолепная динамика.\n💡 Точки роста: автоматизация счета.',
        parentChatMessage: 'Здравствуйте! Сегодня на уроке ребята успешно освоили таблицу на 4.',
      );

      final pdfBytes = await PdfExportService.generateLessonSummaryPdfBytes(
        card,
        world: ThematicWorld.workshop,
        methodology: 'Методика А.С. Пчёлко',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(5000));

      // PDF header validation: starts with '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}
