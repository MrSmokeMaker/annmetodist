/// Оценка по конкретному методическому критерию
class RubricCriterion {
  final String id;
  final String title;
  final String description;
  final int score; // 1-10
  final String feedback;
  final bool isPassed;

  const RubricCriterion({
    required this.id,
    required this.title,
    required this.description,
    required this.score,
    required this.feedback,
    required this.isPassed,
  });
}

/// Вопрос теста для промежуточного или итогового контроля
class LessonTestQuestion {
  final int index;
  final String question;
  final List<String> options;
  final int correctOptionIndex; // 0-based
  final String explanation;
  final bool isOpenQuestion;

  const LessonTestQuestion({
    required this.index,
    required this.question,
    this.options = const [],
    this.correctOptionIndex = -1,
    required this.explanation,
    this.isOpenQuestion = false,
  });
}

/// Полный результат методического аудита урока (QA YandexGPT Pro)
class LessonRubricEvaluation {
  final double overallScore; // 1.0 - 10.0
  final int wordCount;
  final int estimatedTokens;
  final List<RubricCriterion> criteria;
  final List<LessonTestQuestion> testQuestions;
  final List<String> strengthPoints;
  final List<String> recommendations;
  final Map<String, dynamic> lessonMetadata;

  const LessonRubricEvaluation({
    required this.overallScore,
    required this.wordCount,
    required this.estimatedTokens,
    required this.criteria,
    required this.testQuestions,
    required this.strengthPoints,
    required this.recommendations,
    required this.lessonMetadata,
  });

  bool get isFlawless => overallScore >= 9.0;
  bool get isGood => overallScore >= 7.5;
}

/// Сервис профессионального методического аудита урока и парсинга контрольных материалов
class LessonRubricService {
  /// Проводит аудит качества конспекта по 5 ключевым критериям ФГОС и отечественной методики
  static LessonRubricEvaluation evaluateLesson({
    required String content,
    required String topic,
    required String ageGroup,
    required String subject,
    String? methodName,
  }) {
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final estimatedTokens = (words * 1.35).ceil();

    final criteria = <RubricCriterion>[];

    // Критерий 1: ФГОС и дидактические цели
    final hasGoals = content.contains('# Цель и задачи') || content.contains('Цели занятия:');
    final hasThreefold = (content.contains('Обучающ') || content.contains('образовательн')) &&
        (content.contains('Развивающ') || content.contains('развити')) &&
        (content.contains('Воспитательн') || content.contains('воспитани'));
    int c1Score = 6;
    if (hasGoals) c1Score += 2;
    if (hasThreefold) c1Score += 2;
    criteria.add(RubricCriterion(
      id: 'goals_fgos',
      title: 'ФГОС и триединые цели',
      description: 'Наличие обучающих, развивающих и воспитательных задач с измеримыми результатами.',
      score: c1Score,
      feedback: hasThreefold
          ? 'Отлично: триединая цель структурирована по канонам педагогики.'
          : 'Рекомендуется четко разделить задачи на обучающие, развивающие и воспитательные.',
      isPassed: c1Score >= 8,
    ));

    // Критерий 2: Драматургия урока и живые диалоги
    final hasTeacherSpeech = content.contains('Учитель:') || content.contains('Педагог:') || content.contains('Ведущий:');
    final hasChildrenSpeech = content.contains('Дети:') || content.contains('Ученик') || content.contains('хором');
    final hasTiming = RegExp(r'\[Тайминг:|\(\d+\s*мин\)|мин\]').hasMatch(content);
    final hasMotorBreak = content.contains('двигательн') || content.contains('Разминка') || content.contains('Физкультминутка');
    int c2Score = 5;
    if (hasTeacherSpeech) c2Score += 2;
    if (hasChildrenSpeech) c2Score += 1;
    if (hasTiming) c2Score += 1;
    if (hasMotorBreak) c2Score += 1;
    criteria.add(RubricCriterion(
      id: 'dramaturgy',
      title: 'Драматургия и живой диалог',
      description: 'Пошаговый сценарий, дословная речь учителя, реплики детей, двигательная пауза.',
      score: c2Score,
      feedback: (hasTeacherSpeech && hasChildrenSpeech)
          ? 'Живой диалог учителя и детей выдержан превосходно.'
          : 'Добавьте больше дословной речи учителя и предполагаемых ответов детей.',
      isPassed: c2Score >= 8,
    ));

    // Критерий 3: Глубина объяснения темы и анти-заблуждение
    final hasMetaphor = content.contains('метафор') || content.contains('образ') || content.contains('домик') || content.contains('сказк');
    final hasTrap = content.contains('Ловушка') || content.contains('типичн') || content.contains('ошибк');
    final hasMnemonic = content.contains('Главное правило') || content.contains('мнемоник') || content.contains('стишок') || content.contains('алгоритм');
    int c3Score = 6;
    if (hasMetaphor) c3Score += 1;
    if (hasTrap) c3Score += 2;
    if (hasMnemonic) c3Score += 1;
    criteria.add(RubricCriterion(
      id: 'explanation_depth',
      title: 'Глубина темы и анти-заблуждение',
      description: 'Осязаемые детские метафоры, вскрытие ловушек мышления и простое мнемоническое правило.',
      score: c3Score,
      feedback: hasTrap
          ? 'Ловушка мышления вскрыта, дана опора на предупреждение детских ошибок.'
          : 'Рекомендуется ярче выделить типичное заблуждение учеников в данной теме.',
      isPassed: c3Score >= 8,
    ));

    // Критерий 4: Дифференциация и практическая дидактика
    final hasLevels = content.contains('Уровень 1') && content.contains('Уровень 2');
    final hasWordBank = content.contains('Слова для') || content.contains('Корзинк') || content.contains('буквы-помощницы');
    final hasStepDownUp = content.contains('Ступенька вниз') || content.contains('Ступенька вверх') || content.contains('отстающ');
    int c4Score = 5;
    if (hasLevels) c4Score += 2;
    if (hasWordBank) c4Score += 2;
    if (hasStepDownUp) c4Score += 1;
    criteria.add(RubricCriterion(
      id: 'differentiation',
      title: 'Дифференциация заданий',
      description: 'Разноуровневые задания (Старт / Практик / Детектив Pro), банк слов, индивидуальная траектория.',
      score: c4Score,
      feedback: hasWordBank
          ? 'Раздаточный материал снабжен банком слов и образцом решения.'
          : 'Убедитесь, что все упражнения содержат готовые дидактические банки данных.',
      isPassed: c4Score >= 8,
    ));

    // Критерий 5: Контроль, рефлексия и ключи
    final hasKeys = content.contains('Ключи и ответы') || content.contains('🔑');
    final hasReflection = content.contains('Самооценка') || content.contains('рефлекси') || content.contains('⭐⭐⭐');
    final hasHomeNotes = content.contains('Памятка для родителей') || content.contains('ПАМЯТКА');
    int c5Score = 5;
    if (hasKeys) c5Score += 2;
    if (hasReflection) c5Score += 2;
    if (hasHomeNotes) c5Score += 1;
    criteria.add(RubricCriterion(
      id: 'assessment_control',
      title: 'Контроль, рефлексия и ключи',
      description: 'Эталонные ключи для быстрой проверки учителем, лист самооценки и памятка родителю.',
      score: c5Score,
      feedback: hasKeys
          ? 'Учительский проверочный лист сформирован в полном объеме.'
          : 'Добавьте блок эталонных ответов для педагога.',
      isPassed: c5Score >= 8,
    ));

    // Итоговый балл
    final totalSum = criteria.fold<int>(0, (sum, c) => sum + c.score);
    final overall = double.parse((totalSum / criteria.length).toStringAsFixed(1));

    // Сильные стороны
    final strengths = <String>[];
    if (words >= 2000) strengths.add('Глубокий академический объем: $words слов (исчерпывающее методическое наполнение).');
    if (hasTeacherSpeech && hasChildrenSpeech) strengths.add('Прямая драматургия урока с активным вовлечением класса.');
    if (hasLevels) strengths.add('Трехуровневая дифференциация дидактического листа.');
    if (hasKeys) strengths.add('Наличие скрытого ключа с ответами для педагога.');

    // Рекомендации
    final recommendations = <String>[];
    for (final c in criteria) {
      if (c.score < 8) {
        recommendations.add('${c.title}: ${c.feedback}');
      }
    }
    if (words < 1500) {
      recommendations.add('Для максимальной методической пользы разверните диалоги и дидактические механики до 2000+ слов.');
    }

    // Извлечение тестов из контента (если модель сгенерировала их) или синтез
    final testQuestions = _extractOrGenerateTestQuestions(content, topic, subject);

    final metadata = {
      'topic': topic,
      'subject': subject,
      'ageGroup': ageGroup,
      'methodName': methodName ?? 'Классическая методика',
      'wordCount': words,
      'estimatedTokens': estimatedTokens,
      'overallScore': overall,
      'evaluatedAt': DateTime.now().toIso8601String(),
    };

    return LessonRubricEvaluation(
      overallScore: overall,
      wordCount: words,
      estimatedTokens: estimatedTokens,
      criteria: criteria,
      testQuestions: testQuestions,
      strengthPoints: strengths,
      recommendations: recommendations,
      lessonMetadata: metadata,
    );
  }

  /// Извлекает сгенерированные тесты из текста или строит структурированный контрольный срез
  static List<LessonTestQuestion> _extractOrGenerateTestQuestions(
    String content,
    String topic,
    String subject,
  ) {
    final List<LessonTestQuestion> questions = [];

    // Попытка спарсить вопросы с вариантами из текста
    final questionPattern = RegExp(
      r'(?:Вопрос|Задание|Тест)\s+(\d+)[:.]\s*([^\n]+)\n\s*A\)\s*([^\n]+)\n\s*B\)\s*([^\n]+)\n\s*C\)\s*([^\n]+)\n\s*D\)\s*([^\n]+)',
      caseSensitive: false,
    );

    final matches = questionPattern.allMatches(content).toList();
    if (matches.isNotEmpty) {
      for (final m in matches) {
        final idx = int.tryParse(m.group(1) ?? '1') ?? 1;
        final qText = m.group(2)?.trim() ?? '';
        final optA = m.group(3)?.trim() ?? '';
        final optB = m.group(4)?.trim() ?? '';
        final optC = m.group(5)?.trim() ?? '';
        final optD = m.group(6)?.trim() ?? '';

        questions.add(LessonTestQuestion(
          index: idx,
          question: qText,
          options: [optA, optB, optC, optD],
          correctOptionIndex: 0, // По умолчанию правильный вариант A
          explanation: 'Правильный ответ основан на главном правиле урока.',
          isOpenQuestion: false,
        ));
      }
    }

    // Если в тексте не было готового блока тестов — формируем эталонный срез по теме урока
    if (questions.isEmpty) {
      questions.addAll([
        LessonTestQuestion(
          index: 1,
          question: 'Какое главное правило лежит в основе темы «$topic»?',
          options: [
            'Точное применение изученного алгоритма на практике',
            'Заучивание наизусть без понимания сути',
            'Игнорирование промежуточных этапов проверки',
            'Случайный подбор подходящего ответа',
          ],
          correctOptionIndex: 0,
          explanation: 'Понимание сути алгоритма обеспечивает осознанное применение правила.',
        ),
        LessonTestQuestion(
          index: 2,
          question: 'В чем заключается типичная ошибка («ловушка для внимательных») в теме «$topic»?',
          options: [
            'Поспешный вывод без проверки условия задачи',
            'Использование предметной наглядности',
            'Орфографическое проговаривание по слогам',
            'Выделение ключевых слов в условии',
          ],
          correctOptionIndex: 0,
          explanation: 'Типичная детская ловушка связана с механическим действием без анализа.',
        ),
        LessonTestQuestion(
          index: 3,
          question: 'Какой практический прием помогает быстрее всего проверить правильность решения?',
          options: [
            'Составление обратной задачи или самопроверка по ключу',
            'Немедленный переход к следующему заданию',
            'Стирание записи ластиком',
            'Отказ от сверки с образцом',
          ],
          correctOptionIndex: 0,
          explanation: 'Обратная проверка формирует навык самоконтроля по методике Пчелко/Костина.',
        ),
        LessonTestQuestion(
          index: 4,
          question: 'Какая ассоциация или метафора наилучшим образом раскрывает понятие урока?',
          options: [
            'Наглядная модель (числовой домик / волшебный поезд звуков)',
            'Сухое абстрактное определение из академического словаря',
            'Сложная таблица без предварительного объяснения',
            'Длинный список исключений',
          ],
          correctOptionIndex: 0,
          explanation: 'Осязаемая метафора переводит абстрактное знание во внутренний план ребенка.',
        ),
        LessonTestQuestion(
          index: 5,
          question: 'Как поддержать уверенность ребенка при возникновении трудностей в этой теме?',
          options: [
            'Применить технику «Зеленого карандаша» и разобрать образец',
            'Указать на ошибки красной ручкой с критикой',
            'Заставить переписать работу целиком',
            'Сравнить результат с более успешным учеником',
          ],
          correctOptionIndex: 0,
          explanation: 'Техника «Зеленого карандаша» фокусирует внимание на успехе и росте.',
        ),
        // 3 открытых вопроса (эвристические и проблемные)
        LessonTestQuestion(
          index: 6,
          question: 'Объясните своими словами: почему важно соблюдать правило по теме «$topic» в жизненных ситуациях?',
          explanation: 'Оценивается умение ученика связать абстрактное школьное правило с реальным бытовым опытом.',
          isOpenQuestion: true,
        ),
        LessonTestQuestion(
          index: 7,
          question: 'Придумайте свое задание-ловушку для Незнайки по теме «$topic» и напишите, как ее исправить.',
          explanation: 'Творческое моделирование типичной ошибки свидетельствует о наивысшем уровне освоения материала.',
          isOpenQuestion: true,
        ),
        LessonTestQuestion(
          index: 8,
          question: 'Какой совет вы дали бы однокласснику, который только начинает изучать «$topic»?',
          explanation: 'Развитие рефлексии и метакогнитивных навыков формулирования алгоритма помощи.',
          isOpenQuestion: true,
        ),
      ]);
    }

    return questions;
  }
}
