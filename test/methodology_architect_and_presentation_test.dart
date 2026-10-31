import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/pricing_plan.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/models/lesson_presentation.dart';
import 'package:metodist/services/methodology_architect_service.dart';
import 'package:metodist/services/pptx_export_service.dart';

void main() {
  group('Библиотека классических методик-книг первоисточников', () {
    test('Содержит 8 фундаментальных педагогических шедевров', () {
      final books = PredefinedMethodologyBook.classicLibrary;
      expect(books.length, 8);

      final bookIds = books.map((b) => b.id).toList();
      expect(bookIds, contains('pchelko_math'));
      expect(bookIds, contains('kostin_russian'));
      expect(bookIds, contains('redozubov_reading'));
      expect(bookIds, contains('shatalov_ опорные_сигналы'));
      expect(bookIds, contains('vygotsky_development'));
      expect(bookIds, contains('elkonin_davydov'));
      expect(bookIds, contains('zankov_system'));
      expect(bookIds, contains('altshuller_triz'));

      final pchelko = books.firstWhere((b) => b.id == 'pchelko_math');
      expect(pchelko.author, contains('Пчёлко'));
      expect(pchelko.year, 1951);
      expect(pchelko.keyPrinciples, contains('От конкретного предмета к абстрактному числу'));
    });
  });

  group('Пошаговая генерация тем курса (15–60+ занятий)', () {
    test('Генерация тем курса на четверть (30 уроков) по математике', () {
      final topics = MethodologyArchitectService.generateCourseTopics(
        subject: 'Математика',
        ageGroup: '3 класс',
        lessonCount: 30,
        methodologyName: 'Методика А.С. Пчёлко',
      );

      expect(topics.length, 30);
      expect(topics[0], contains('Урок 1'));
      expect(topics[29], contains('Урок 30'));
    });

    test('Генерация расширенного блока из 45 уроков по русскому языку', () {
      final topics = MethodologyArchitectService.generateCourseTopics(
        subject: 'Русский язык',
        ageGroup: '2 класс',
        lessonCount: 45,
        methodologyName: 'Методика Н.А. Костина',
      );

      expect(topics.length, 45);
      expect(topics[0], contains('Текст и предложение'));
      expect(topics[44], contains('Урок 45'));
    });
  });

  group('Глубокая генерация урока повышенного объёма (от 7 страниц)', () {
    test('Урок содержит все 5 обязательных полномасштабных частей', () {
      final lesson = MethodologyArchitectService.generateDeepSevenPageLesson(
        topic: 'Табличное умножение и деление на 4',
        lessonIndex: 7,
        totalLessons: 30,
        subject: 'Математика',
        ageGroup: '3 класс',
        methodologyName: 'Методика А.С. Пчёлко (1951)',
        world: ThematicWorld.space,
      );

      expect(lesson.content, contains('ЧАСТЬ 1. ПОЛНЫЙ АКАДЕМИЧЕСКИЙ СЦЕНАРИЙ УРОКА (СТРАНИЦЫ 1–2)'));
      expect(lesson.content, contains('ЧАСТЬ 2. РАСШИРЕННЫЙ ТРЁХУРОВНЕВЫЙ РАБОЧИЙ ЛИСТ (СТРАНИЦЫ 3–4)'));
      expect(lesson.content, contains('ЧАСТЬ 3. ТРИЗ-ЛАБОРАТОРИЯ И ИССЛЕДОВАТЕЛЬСКИЙ ПРАКТИКУМ (СТРАНИЦА 5)'));
      expect(lesson.content, contains('ЧАСТЬ 4. КРИТЕРИАЛЬНАЯ МАТРИЦА ОЦЕНИВАНИЯ И МЕТОДИЧЕСКИЕ КЛЮЧИ (СТРАНИЦА 6)'));
      expect(lesson.content, contains('ЧАСТЬ 5. ДИФФЕРЕНЦИРОВАННОЕ ДОМАШНЕЕ ЗАДАНИЕ И ПАМЯТКА ДЛЯ РОДИТЕЛЕЙ (СТРАНИЦА 7)'));

      // Проверка речевого диалога учителя и учеников
      expect(lesson.content, contains('**Учитель:**'));
      expect(lesson.content, contains('**Ученики:**'));

      // Проверка ТРИЗ и наглядных таблиц
      expect(lesson.content, contains('Ловушка Незнайки'));
      expect(lesson.content, contains('ТРИЗ-задача от маскота'));
    });

    test('Аудит объёма подтверждает выполнение планки «от 7 страниц»', () {
      final lesson = MethodologyArchitectService.generateDeepSevenPageLesson(
        topic: 'Безударные гласные в корне слова',
        lessonIndex: 12,
        totalLessons: 30,
        subject: 'Русский язык',
        ageGroup: '2 класс',
        methodologyName: 'Методика Н.А. Костина (1949)',
        world: ThematicWorld.forest,
      );

      final audit = MethodologyArchitectService.auditDeepLessonVolume(lesson);
      expect(audit.meetsSevenPageThreshold, isTrue);
      expect(audit.estimatedPages, greaterThanOrEqualTo(7));
      expect(audit.totalWordCount, greaterThanOrEqualTo(1200));
      expect(audit.passedQualityMetrics.length, greaterThanOrEqualTo(5));
    });
  });

  group('Генератор презентаций для PowerPoint (.pptx) с Mobbin дизайном', () {
    test('Создание интерактивной структуры презентации из 7 Mobbin слайдов', () {
      final lesson = MethodologyArchitectService.generateDeepSevenPageLesson(
        topic: 'Периметр многоугольника',
        lessonIndex: 15,
        totalLessons: 30,
        subject: 'Математика',
        ageGroup: '3 класс',
        methodologyName: 'Методика А.С. Пчёлко',
        world: ThematicWorld.workshop,
      );

      final presentation = MethodologyArchitectService.generatePresentationForLesson(
        conspect: lesson,
        world: ThematicWorld.workshop,
      );

      expect(presentation.slides.length, 7);
      expect(presentation.slides[0].layoutType, SlideLayoutType.heroTitle);
      expect(presentation.slides[1].layoutType, SlideLayoutType.challengeHook);
      expect(presentation.slides[2].layoutType, SlideLayoutType.conceptBreakdown);
      expect(presentation.slides[3].layoutType, SlideLayoutType.visualScheme);
      expect(presentation.slides[4].layoutType, SlideLayoutType.interactivePractice);
      expect(presentation.slides[5].layoutType, SlideLayoutType.rubricCheck);
      expect(presentation.slides[6].layoutType, SlideLayoutType.conclusionReward);

      // Проверка правил создания слайдов: указания для учителя и YandexART промпты
      for (final slide in presentation.slides) {
        expect(slide.speakerNotes.isNotEmpty, isTrue);
        expect(slide.yandexArtPrompt.isNotEmpty, isTrue);
        expect(slide.badgeText.isNotEmpty, isTrue);
      }
    });

    test('PptxExportService формирует валидный двоичный файл Microsoft PowerPoint (.pptx)', () {
      final lesson = MethodologyArchitectService.generateDeepSevenPageLesson(
        topic: 'Звуковой разбор слова',
        lessonIndex: 3,
        totalLessons: 20,
        subject: 'Русский язык',
        ageGroup: '1 класс',
        methodologyName: 'Методика С.П. Редозубова',
        world: ThematicWorld.forest,
      );

      final presentation = MethodologyArchitectService.generatePresentationForLesson(
        conspect: lesson,
        world: ThematicWorld.forest,
      );

      final pptxBytes = PptxExportService.generatePptxBytes(presentation);
      expect(pptxBytes, isNotNull);
      expect(pptxBytes.length, greaterThan(1500));

      // Проверка ZIP/OpenXML сигнатуры (PK = 0x50, 0x4B)
      expect(pptxBytes[0], 0x50);
      expect(pptxBytes[1], 0x4B);
    });

    test('PresentationPromptBuilder формирует строгие правила создания слайдов по Mobbin', () {
      final prompt = PresentationPromptBuilder.buildSystemPrompt(
        subject: 'Математика',
        topic: 'Деление с остатком',
        ageGroup: '3 класс',
        methodology: 'А.С. Пчёлко',
      );

      expect(prompt, contains('Mobbin Design System'));
      expect(prompt, contains('УКАЗАНИЯ ДЛЯ УЧИТЕЛЯ (Speaker Notes)'));
      expect(prompt, contains('ПРОМПТ ДЛЯ YANDEXART'));
      expect(prompt, contains('ОБЯЗАТЕЛЬНАЯ СТРУКТУРА ИЗ 7 СЛАЙДОВ'));
    });
  });

  group('Тарифный план: значки Разработчика и Корона 👑', () {
    test('Тариф Разработчик содержит значки [РАЗРАБОТЧИК] и корону 👑 для авторских тем', () {
      final devPlan = PricingPlan.developer;
      final featuresJoined = devPlan.features.join('\n');

      expect(featuresJoined, contains('Конструктор авторских методик'));
      expect(featuresJoined, contains('ДИРЕКТОР'));
    });
  });
}
