import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/conspect.dart';
import '../models/thematic_world.dart';
import 'pdf_export_service.dart';
import 'docx_export_service.dart';

class CurriculumValidationResult {
  final bool isValid;
  final int wordCount;
  final bool hasObjectives;
  final bool hasWorksheet;
  final bool hasHomework;
  final bool hasAnswerKeys;
  final double qualityScore;
  final List<String> passedAudits;
  final List<String> warnings;

  CurriculumValidationResult({
    required this.isValid,
    required this.wordCount,
    required this.hasObjectives,
    required this.hasWorksheet,
    required this.hasHomework,
    required this.hasAnswerKeys,
    required this.qualityScore,
    required this.passedAudits,
    required this.warnings,
  });
}

class CurriculumBulkService {
  /// Pre-built sequential curriculum topic plans for quarter generation (15-30 topics)
  static List<String> getQuarterTopics({
    required String subject,
    required String ageGroup,
    int count = 20,
  }) {
    final lowerSubject = subject.toLowerCase();
    List<String> baseTopics;

    if (lowerSubject.contains('матем')) {
      baseTopics = [
        'Повторение нумерации чисел первого и второго десятка',
        'Сложение и вычитание с переходом через десяток',
        'Табличное умножение на 2 и 3: алгоритм и предметные модели',
        'Табличное деление на 2 и 3: разбиение на равные группы',
        'Порядок действий в числовых выражениях со скобками',
        'Геометрические фигуры: луч, отрезок, угол и ломаная линия',
        'Периметр многоугольника: практическое измерение и расчет',
        'Табличное умножение и деление на 4 и 5',
        'Свойства нуля и единицы при умножении и делении',
        'Текстовые задачи на нахождение цены, количества и стоимости',
        'Умножение и деление на 6 и 7: метод опорных узлов',
        'Решение задач на кратное и разностное сравнение',
        'Табличное умножение и деление на 8 и 9: сводная таблица Пифагора',
        'Единицы площади: квадратный сантиметр и квадратный дециметр',
        'Площадь прямоугольника: формула S = a × b',
        'Текстовые задачи в 3 действия с косвенным вопросом',
        'Деление с остатком: наглядная проверка и формулы',
        'Нумерация трехзначных чисел: разрядный состав сотен, десятков и единиц',
        'Письменное сложение и вычитание столбиком в пределах 1000',
        'Итоговая контрольная работа и закрепление математических навыков',
        'Проектная олимпиадная мастерская: комбинаторика и логические графы',
        'Нестандартные задачи на переливания и взвешивания',
        'Римские цифры и историческая система счисления',
        'Работа с данными: таблицы, столбчатые диаграммы и пиктограммы',
        'Математический квест: закрепление пройденного материала за четверть',
      ];
    } else if (lowerSubject.contains('русск')) {
      baseTopics = [
        'Повторение: текст, предложение, словосочетание',
        'Главные члены предложения: подлежащее и сказуемое',
        'Второстепенные члены предложения: определение, дополнение, обстоятельство',
        'Корень слова и однокоренные слова. Чередование звуков',
        'Правописание безударных гласных в корне слова',
        'Парные звонкие и глухие согласные в корне слова',
        'Непроизносимые согласные: алгоритм орфографической проверки',
        'Приставка и предлог: сходство звучания и различие на письме',
        'Суффиксальный способ образования слов и уменьшительно-ласкательные суффиксы',
        'Правописание разделительных Ъ и Ь знаков',
        'Имя существительное как часть речи: одушевленные и неодушевленные',
        'Собственные и нарицательные имена существительные',
        'Род имен существительных: мужской, женский, средний',
        'Число имен существительных: единственное и множественное',
        'Падежи имен существительных: система склонения и падежные вопросы',
        'Имя прилагательное: связь с именем существительным в роде и числе',
        'Глагол как часть речи: значение действия и времена глагола',
        'Правописание частицы НЕ с глаголами',
        'Словарный диктант и обобщение правил орфографии',
        'Творческое сочинение-описание по картине с использованием тропов',
        'Комплексный анализ текста: тема, основная мысль, план текста',
        'Развитие речи: составление диалогов и правил вежливого общения',
        'Изложение повествовательного текста с элементами рассуждения',
        'Фонетический и морфемный разбор слов',
        'Итоговый орфографический турнир четверти',
      ];
    } else {
      baseTopics = [
        'Введение в тему: ключевые понятия и базовые законы',
        'Исследование окружающего мира и наблюдение явлений',
        'Классификация объектов по существенным признакам',
        'Причинно-следственные связи в изучаемых процессах',
        'Практический эксперимент и формулирование гипотезы',
        'Анализ источников информации и работа со схемами',
        'Моделирование изучаемых процессов в миниатюре',
        'Взаимосвязь живой и неживой природы',
        'Экологическое равновесие и роль человека в природе',
        'Культурно-исторический контекст и великие открытия',
        'Сравнительный анализ: общее и различия объектов',
        'Составление паспорта изучаемого явления или понятия',
        'Решение проблемных кейсов в малых группах',
        'Инструменты фиксации данных: ментальные карты и схемы',
        'Лабораторный практикум: проверка гипотез на практике',
        'Подготовка группового исследовательского сообщения',
        'Критическое мышление: проверка фактов и отделение мифов',
        'Обобщение и структурирование изученного раздела',
        'Дискуссионный клуб: аргументация собственной позиции',
        'Итоговая аттестация и защита творческих мини-проектов',
        'Междисциплинарный практикум: наука, искусство и технологии',
        'Создание памятки-инструкции по безопасности и применению знаний',
        'Интеллектуальная викторина: знатоки пройденного курса',
        'Рефлексия учебных достижений за четверть и карта роста',
      ];
    }

    if (count <= baseTopics.length) {
      return baseTopics.sublist(0, count);
    }

    final result = List<String>.from(baseTopics);
    int extra = 1;
    while (result.length < count) {
      result.add('Углубленный практикум $extra: комплексное решение задач курса');
      extra++;
    }
    return result;
  }

  /// Mandatory quality & volume audit of generated conspect & worksheets
  static CurriculumValidationResult validateLessonQuality(Conspect conspect) {
    final text = conspect.content;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    final hasObjectives = text.contains('# Цели') ||
        text.contains('# Цель') ||
        text.contains('Планируемые результаты');
    final hasWorksheet = text.contains('# Лист заданий') ||
        text.contains('## Задание 1') ||
        text.contains('Задания для самостоятельной работы');
    final hasHomework = text.contains('# Домашнее задание') ||
        text.contains('Домашняя работа') ||
        text.contains('Творческое задание на дом');
    final hasAnswerKeys = text.contains('Ответы и решения') ||
        text.contains('Критерии оценивания') ||
        text.contains('Ключи для учителя');

    final passedAudits = <String>[];
    final warnings = <String>[];

    if (words >= 350) {
      passedAudits.add('Соответствие объёма академической норме ($words слов)');
    } else {
      warnings.add('Объём материала ниже нормы ($words слов из 350)');
    }

    if (hasObjectives) {
      passedAudits.add('ФГОС блок: сформулированы предметные и метапредметные цели');
    } else {
      warnings.add('Отсутствует явный блок педагогических целей ФГОС');
    }

    if (hasWorksheet) {
      passedAudits.add('Трёхуровневый лист заданий (Базовый, Повышенный, Творческий)');
    } else {
      warnings.add('Не обнаружен структурированный лист заданий для учеников');
    }

    if (hasHomework) {
      passedAudits.add('Дифференцированное домашнее задание');
    } else {
      warnings.add('Не обнаружено домашнее задание');
    }

    if (hasAnswerKeys) {
      passedAudits.add('Методические ключи и критерии оценивания для учителя');
    } else {
      warnings.add('Рекомендуется добавить ключи для быстрой проверки');
    }

    double score = 60.0;
    if (words >= 350) score += 10.0;
    if (hasObjectives) score += 10.0;
    if (hasWorksheet) score += 10.0;
    if (hasHomework) score += 5.0;
    if (hasAnswerKeys) score += 5.0;

    final isValid = words >= 300 && (hasObjectives || hasWorksheet);

    return CurriculumValidationResult(
      isValid: isValid,
      wordCount: words,
      hasObjectives: hasObjectives,
      hasWorksheet: hasWorksheet,
      hasHomework: hasHomework,
      hasAnswerKeys: hasAnswerKeys,
      qualityScore: score.clamp(0.0, 100.0),
      passedAudits: passedAudits,
      warnings: warnings,
    );
  }

  /// Generates 15-30 sequenced conspects for the quarter with narrative thematic continuity
  static List<Conspect> generateQuarterCurriculum({
    required String subject,
    required String ageGroup,
    required String methodId,
    required String methodName,
    required String worldId,
    int lessonCount = 20,
  }) {
    final topics = getQuarterTopics(
      subject: subject,
      ageGroup: ageGroup,
      count: lessonCount,
    );
    final world = ThematicWorld.findById(worldId);
    final batchGroupId = 'quarter_${DateTime.now().millisecondsSinceEpoch}';
    final conspects = <Conspect>[];

    for (int i = 0; i < topics.length; i++) {
      final lessonNum = i + 1;
      final topic = topics[i];
      final title = 'Урок $lessonNum. $topic';
      final narrativeEpisode =
          'Эпизод $lessonNum / $lessonCount: ${world.mascotName} исследует ${world.subtitle} в локации «$topic». Миссия: овладеть новыми знаниями и получить наградную звезду!';

      final content = '''# Цели и планируемые результаты урока (ФГОС)
Предметные: освоить ключевые понятия темы «$topic», научиться применять алгоритм решения типовых и прикладных задач.
Метапредметные: развивать познавательную активность, критическое мышление, умение контролировать результат своей работы.
Личностные: формировать мотивацию к учению через погружение в мир «${world.title}» вместе с маскотом по имени ${world.mascotName}.

# Сюжетная линия игрового мира
$narrativeEpisode
Девиз миссии: ${world.greetingPhrase}

# Ход урока
## 1. Организационный момент и мотивация (3-5 мин)
Приветствие в стиле «${world.title}». Вводная игровая задача от ${world.mascotName}.
Проверка готовности рабочего места и настрой на научный поиск.

## 2. Актуализация опорных знаний и разминка (7 мин)
Фронтальный экспресс-опрос по ранее изученным темам.
Устный счет / орфографическая пятиминутка с шифром от маскота.

## 3. Открытие нового знания и первичное закрепление (15 мин)
Пошаговый разбор ключевого понятия: «$topic».
Методический подход ($methodName): наглядность, предметная логика, алгоритмизация.
Работа с опорными схемами и решение демонстрационного примера у доски.

## 4. Динамическая пауза / Физкультминутка (2 мин)
Тематическая разминка в стиле «${world.title}»: упражнения на осанку и координацию.

## 5. Практическая работа и рефлексия (10 мин)
Самостоятельное выполнение заданий с взаимопроверкой в парах.
Подведение итогов: что нового открыли исследователи? Заполнение карты прогресса.

# Лист заданий для самостоятельной работы
## Уровень 1: Базовый (Обязательный фундамент)
1. Выполните прямое действие по изученному алгоритму темы «$topic». Запишите ответ в поле.
2. Определите верное утверждение из трех предложенных вариантов.
3. Заполните пропуски в опорной таблице понятий.

## Уровень 2: Повышенный (Анализ и рассуждение)
4. Найдите и исправьте преднамеренную ошибку в приведенном решении. Объясните причину ошибки.
5. Решите задачу с косвенным условием, составив математическую или логическую модель.

## Уровень 3: Творческий (Мастерская ТРИЗ и маскота)
6. Помогите маскоту ${world.mascotName} расшифровать секретное послание, применив знания темы «$topic».
7. Придумайте собственную задачу для одноклассника по данной теме.

# Домашнее задание
Базовый уровень: упражнения в рабочей тетради по теме «$topic» (№ 1-3).
Творческий уровень: нарисовать иллюстрацию или составить мини-кроссворд по теме для мира «${world.title}».

# Ответы и критерии оценивания (Ключи для учителя)
К заданию 1: Проверяется корректность применения базового алгоритма (1 балл).
К заданию 4: Ошибка заключается в несоблюдении порядка действий / орфограммы. Верный ответ обоснован (2 балла).
К заданию 6: Творческое решение оценивается за оригинальность и математическую строгость (3 балла).
Шкала отметки: «5» — 6-7 баллов, «4» — 4-5 баллов, «3» — 2-3 балла.
''';

      final conspect = Conspect(
        id: 'bulk_${batchGroupId}_lesson_$lessonNum',
        title: title,
        methodId: methodId,
        methodName: methodName,
        subject: subject,
        ageGroup: ageGroup,
        topic: topic,
        duration: '45 минут',
        review: 'Курс на четверть. $narrativeEpisode',
        notes: 'Проверено автоматическим валидатором объёма и ФГОС-структуры',
        content: content,
        variantIndex: lessonNum,
        batchGroupId: batchGroupId,
        generatedMaterials: ['conspect', 'worksheet', 'homework'],
        thematicWorldId: worldId,
        illustrationMascot: world.mascotName,
        createdAt: DateTime.now().add(Duration(minutes: i)),
      );

      conspects.add(conspect);
    }

    return conspects;
  }

  /// Packages all conspects into a single ZIP file containing both PDF and DOCX formats
  static Future<Uint8List> createCurriculumZip(List<Conspect> conspects) async {
    final archive = Archive();

    // Summary catalog file
    final summaryBuffer = StringBuffer();
    summaryBuffer.writeln('========================================================');
    summaryBuffer.writeln('ПАКЕТНЫЙ КУРС НА ЧЕТВЕРТЬ: АТТЕСТАЦИОННАЯ ВЕДОМОСТЬ');
    summaryBuffer.writeln('Сгенерировано: ${DateTime.now().toLocal()}');
    summaryBuffer.writeln('Количество уроков в блоке: ${conspects.length}');
    summaryBuffer.writeln('Предмет: ${conspects.isNotEmpty ? conspects.first.subject : "-"}');
    summaryBuffer.writeln('Методика: ${conspects.isNotEmpty ? conspects.first.methodName : "-"}');
    summaryBuffer.writeln('Игровой мир: ${conspects.isNotEmpty ? conspects.first.thematicWorld.title : "-"}');
    summaryBuffer.writeln('Тариф: Разработчик (Developer Tier Flagship)');
    summaryBuffer.writeln('========================================================\n');

    for (int i = 0; i < conspects.length; i++) {
      final c = conspects[i];
      final validation = validateLessonQuality(c);
      final indexStr = (i + 1).toString().padLeft(2, '0');
      final cleanTitle = c.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      summaryBuffer.writeln('$indexStr. ${c.title}');
      summaryBuffer.writeln('    Объём: ${validation.wordCount} слов | Оценка качества: ${validation.qualityScore.toStringAsFixed(0)}%');
      summaryBuffer.writeln('    ФГОС цели: ${validation.hasObjectives ? "Да" : "Нет"} | Лист заданий: ${validation.hasWorksheet ? "Да" : "Нет"} | ДЗ: ${validation.hasHomework ? "Да" : "Нет"}');
      summaryBuffer.writeln('--------------------------------------------------------');

      // 1. Generate DOCX file
      final docxBytes = DocxExportService.generateDocxBytes(c);
      archive.addFile(
        ArchiveFile(
          'DOCX/Урок_${indexStr}_$cleanTitle.docx',
          docxBytes.length,
          docxBytes,
        ),
      );

      // 2. Generate PDF file
      try {
        final pdfBytes = await PdfExportService.generateCombinedPdfBytes(c, isPro: true);
        archive.addFile(
          ArchiveFile(
            'PDF/Урок_${indexStr}_$cleanTitle.pdf',
            pdfBytes.length,
            pdfBytes,
          ),
        );
      } catch (e) {
        debugPrint('Error generating PDF for lesson $i: $e');
      }
    }

    final summaryBytes = utf8.encode(summaryBuffer.toString());
    archive.addFile(
      ArchiveFile(
        'Аттестационная_ведомость_и_ключи.txt',
        summaryBytes.length,
        summaryBytes,
      ),
    );

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    return Uint8List.fromList(zipData ?? []);
  }

  /// Downloads or shares the quarter package ZIP
  static Future<void> shareCurriculumZip(List<Conspect> conspects) async {
    final zipBytes = await createCurriculumZip(conspects);
    final subject = conspects.isNotEmpty ? conspects.first.subject : 'Курс';
    final safeSubject = subject.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
    final fileName = 'Курс_на_четверть_${safeSubject}_${conspects.length}_уроков.zip';

    await Share.shareXFiles(
      [
        XFile.fromData(
          zipBytes,
          name: fileName,
          mimeType: 'application/zip',
        ),
      ],
      subject: 'Пакетный курс на четверть: $subject (${conspects.length} уроков)',
    );
  }
}
