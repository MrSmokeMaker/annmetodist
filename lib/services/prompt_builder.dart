class PromptBuilder {
  /// Базовый шаблон (каркас) промпта.
  static const String defaultTemplate = '''
Ты — опытный методист-практик начального образования и дошкольной педагогики.
Составь подробный, структурированный конспект занятия строго по указанным параметрам и методической концепции.

Параметры занятия:
- Методика и подход: {БЛОК_МЕТОДИКИ}
- Тема: {ТЕМА}
- Возрастная группа / класс: {КЛАСС}
- Планируемая длительность: {ДЛИТЕЛЬНОСТЬ}
- Повторение предыдущего материала: {ПОВТОРЕНИЕ}
- Особые замечания и пожелания учителя: {ЗАМЕЧАНИЯ}
{СИТУАЦИЯ_БЛОК}
{ПРИЕМЫ_БЛОК}

Требования к структуре конспекта:
1. # Цель и задачи занятия (обучающие, развивающие, воспитательные).
2. # Необходимые материалы и наглядные пособия.
3. # Ход занятия (пошаговый сценарий с таймингом для каждого этапа, репликами учителя и примерными ответами учеников).
4. # Дифференциация заданий (вариант 'проще' для детей с трудностями и 'сложнее' для опережающих детей).
5. # Лист заданий для печати (раздаточный материал: упражнения, прописи или карточки с заданиями).

Специальные правила:
- Если возрастная группа — дошкольники (4–6 лет), занятие должно проводиться в игровой сюжетной форме, длительность не более 15–25 минут, обязательна динамическая пауза / логоритмика.
- Если блок повторения не указан — этап повторения в ходе занятия пропустить и сразу перейти к теме.
- Все формулировки должны точно соответствовать духу и принципам выбранной методики.
''';

  static String buildSystemPrompt({
    required String methodBlock,
    required String topic,
    required String ageGroup,
    required String duration,
    String? review,
    String? notes,
    String? situationRules,
    List<String>? activitySamples,
    String? customTemplate,
  }) {
    final template = customTemplate ?? defaultTemplate;

    final effectiveTopic = topic.trim().isEmpty ? 'не указано' : topic.trim();
    final effectiveAge = ageGroup.trim().isEmpty ? 'не указано' : ageGroup.trim();
    final effectiveDuration = duration.trim().isEmpty ? 'не указано' : duration.trim();
    final effectiveNotes = (notes == null || notes.trim().isEmpty) ? 'не указано' : notes.trim();

    final effectiveReview = (review == null || review.trim().isEmpty)
        ? 'не указано (блок повторения пропустить)'
        : review.trim();

    String situationBlock = '';
    if (situationRules != null && situationRules.trim().isNotEmpty) {
      situationBlock = '- Особая ситуация урока: ${situationRules.trim()}';
    }

    String activitiesBlock = '';
    if (activitySamples != null && activitySamples.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('\nОбязательно включи в ход занятия следующие приёмы:');
      for (final sample in activitySamples) {
        buffer.writeln(sample.trim());
      }
      activitiesBlock = buffer.toString().trim();
    }

    return template
        .replaceAll('{БЛОК_МЕТОДИКИ}', methodBlock.trim())
        .replaceAll('{ТЕМА}', effectiveTopic)
        .replaceAll('{КЛАСС}', effectiveAge)
        .replaceAll('{ДЛИТЕЛЬНОСТЬ}', effectiveDuration)
        .replaceAll('{ПОВТОРЕНИЕ}', effectiveReview)
        .replaceAll('{ЗАМЕЧАНИЯ}', effectiveNotes)
        .replaceAll('{СИТУАЦИЯ_БЛОК}', situationBlock)
        .replaceAll('{ПРИЕМЫ_БЛОК}', activitiesBlock);
  }

  static String buildUserPrompt({
    required String methodName,
    required String topic,
    required String ageGroup,
    required String duration,
    String? situationTitle,
  }) {
    final situationPart = (situationTitle != null && situationTitle.isNotEmpty)
        ? ' (ситуация: $situationTitle)'
        : '';
    return 'Составь подробный конспект занятия по теме "$topic"$situationPart для "$ageGroup" (длительность: $duration) по методике: "$methodName".';
  }
}
