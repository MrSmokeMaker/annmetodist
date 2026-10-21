import 'dart:convert';
import '../models/printable_card.dart';
import 'child_interaction_service.dart';
import 'topic_explanation_service.dart';

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
{АДАПТАЦИЯ_БЛОК}
{ВАРИАНТ_БЛОК}

Требования к структуре конспекта:
1. # Цель и задачи занятия (обучающие, развивающие, воспитательные).
2. # Необходимые материалы и наглядные пособия.
3. # Ход занятия (пошаговый сценарий с таймингом для каждого этапа, репликами учителя и примерными ответами учеников).
4. # Дифференциация заданий (вариант 'проще' для детей с трудностями и 'сложнее' для опережающих детей).
5. # Лист заданий для печати (раздаточный материал: упражнения, прописи или карточки с заданиями).
6. # Подсказка для родителя (текстовая заготовка на 30–60 секунд для родителя: как мягко и доступно объяснить тему ребенку, на что обратить внимание и как поддержать).
7. # Карточки для занятия (раздаточные карточки для листа А4. В конце этого раздела обязательно приведи строго валидный JSON-блок с 4–6 карточками:
```json
[
  {
    "front_text": "буква/слог/слово/вопрос",
    "back_text": "пояснение или подсказка",
    "image_hint": "описание зрительного образа",
    "type": "letter|syllable|word|task"
  }
]
).

ВАЖНЫЕ ОБНОВЛЕНИЯ ДЛЯ УЛУЧШЕНИЯ КАЧЕСТВА КОНСПЕКТОВ:

8. # Блок дополнительных заданий для домашней работы (5-7 разнообразных заданий):
   - 2-3 творческих задания для закрепления темы
   - 2-3 практических упражнения на применение знаний
   - 1-2 игровых задания для мотивации ребенка

9. # Секция "Как объяснить ребенку" (простое объяснение темы словами ребенка):
   - Объяснение ключевых понятий на языке, понятном ребенку
   - Примеры из жизни ребенка для лучшего понимания
   - Ответы на вероятные вопросы ребенка по теме

10. # Диалоговые сценарии для учителя и ученика:
    - Типичные вопросы, которые может задать ребенок
    - Примерные ответы учителя на эти вопросы
    - Стимулирующие вопросы для развития мышления ребенка

11. # Варианты взаимодействия с ребенком:
    - 3-4 способа поддержать ребенка, если он не понял тему
    - 2-3 способа усложнить задание для одаренных детей
    - Игровые приемы для вовлечения в учебный процесс

Специальные правила:
- Если возрастная группа — дошкольники (4–6 лет), занятие должно проводиться в игровой сюжетной форме, длительность не более 15–25 минут, обязательна динамическая пауза / логоритмика.
- Если блок повторения не указан — этап повторения в ходе занятия пропустить и сразу перейти к теме.
- Все формулировки должны точно соответствовать духу и принципам выбранной методики.
- Обеспечить БОЛЬШЕ ЗАДАНИЙ и упражнений разного уровня сложности.
- Добавить ЭМОЦИОНАЛЬНУЮ СОСТАВЛЯЮЩУЮ в общение с ребенком (похвалу, поддержку, мотивацию).
- Предусмотреть ПРАКТИЧЕСКИЕ ПРИМЕРЫ из повседневной жизни ребенка.
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
    List<String>? historicalFeedbackTags,
    int? variantIndex,
    int? totalVariants,
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

    // Шаг 2: Адаптация по обратной связи из истории
    String adaptationBlock = '';
    if (historicalFeedbackTags != null && historicalFeedbackTags.isNotEmpty) {
      final List<String> rules = [];
      if (historicalFeedbackTags.contains('Слишком много письма')) {
        rules.add('- Правило адаптации: в предыдущих занятиях было слишком много письма. Сократи объём письменных заданий на 30%, переведя закрепление в устную или игровую форму.');
      }
      if (historicalFeedbackTags.contains('Было трудно')) {
        rules.add('- Правило адаптации: ребенку было трудно на прошлом уроке. Упрости объяснения, снизь темп и добавь больше пошаговых примеров и наглядных опор.');
      }
      if (historicalFeedbackTags.contains('Справился легко')) {
        rules.add('- Правило адаптация: ребенок легко справился с предыдущим материалом. Предложи более вариативные задания с элементами эвристики и повышенной сложности.');
      }
      if (historicalFeedbackTags.contains('Скучно было')) {
        rules.add('- Правило адаптация: ребенку было скучно на предыдущем занятии. Добавь больше игровых элементов, загадок, интерактивных заданий и соревновательных моментов.');
      }
      if (historicalFeedbackTags.contains('Нужно больше практики')) {
        rules.add('- Правило адаптация: ребенку требуется больше практических упражнений. Увеличь количество практических заданий на 40% и добавь дополнительные тренировочные упражнения.');
      }
      if (rules.isNotEmpty) {
        adaptationBlock = rules.join('\n');
      }
    }

    // Шаг 2: Вариант при пакетной генерации
    String variantBlock = '';
    if (variantIndex != null && totalVariants != null && totalVariants > 1) {
      variantBlock = '- Инструкция по варианту: это вариант $variantIndex из $totalVariants. Сделай его заметно отличным от остальных (предложи другую сюжетную линию, другие игровые упражнения и примеры).';
    }

    return template
        .replaceAll('{БЛОК_МЕТОДИКИ}', methodBlock.trim())
        .replaceAll('{ТЕМА}', effectiveTopic)
        .replaceAll('{КЛАСС}', effectiveAge)
        .replaceAll('{ДЛИТЕЛЬНОСТЬ}', effectiveDuration)
        .replaceAll('{ПОВТОРЕНИЕ}', effectiveReview)
        .replaceAll('{ЗАМЕЧАНИЯ}', effectiveNotes)
        .replaceAll('{СИТУАЦИЯ_БЛОК}', situationBlock)
        .replaceAll('{ПРИЕМЫ_БЛОК}', activitiesBlock)
        .replaceAll('{АДАПТАЦИЯ_БЛОК}', adaptationBlock)
        .replaceAll('{ВАРИАНТ_БЛОК}', variantBlock);
  }

  static String buildUserPrompt({
    required String methodName,
    required String topic,
    required String ageGroup,
    required String duration,
    String? situationTitle,
    int? variantIndex,
  }) {
    final situationPart = (situationTitle != null && situationTitle.isNotEmpty)
        ? ' (ситуация: $situationTitle)'
        : '';
    final variantPart = (variantIndex != null && variantIndex > 1)
        ? ' (Вариант $variantIndex)'
        : '';
    return 'Составь подробный конспект занятия$variantPart по теме "$topic"$situationPart для "$ageGroup" (длительность: $duration) по методике: "$methodName". Включи больше заданий разного уровня сложности, диалоговые сценарии и простое объяснение темы для ребенка.';
  }

  /// Шаг 3: Извлечение аудио-подсказки для родителя из текста конспекта
  static String? extractParentAudioScript(String content) {
    final regExp = RegExp(
      r'#+\s*Подсказка для родителя[^\n]*\n([\s\S]*?)(?=(?:\n#+|\n```json|\Z))',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(content);
    if (match != null) {
      final text = match.group(1)?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  /// Шаг 3: Извлечение структурированного JSON-блока с карточками
  static List<PrintableCard> extractPrintableCards(String content) {
    try {
      // Ищем блок ```json [...] ``` или просто [...]
      final jsonBlockRegex = RegExp(r'```(?:json)?\s*(\[\s*\{[\s\S]*?\}\s*\])\s*```');
      final match = jsonBlockRegex.firstMatch(content);
      String? jsonStr = match?.group(1);

      if (jsonStr == null) {
        final rawArrayRegex = RegExp(r'(\[\s*\{[\s\S]*?\}\s*\])');
        final rawMatch = rawArrayRegex.firstMatch(content);
        jsonStr = rawMatch?.group(1);
      }

      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded
              .map((item) => PrintableCard.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
    } catch (_) {
      // В случае сбоя парсинга JSON
    }
    return [];
  }

  /// Шаг 3: Промпт для генерации карточек по готовому конспекту (отвечать ТОЛЬКО валидным JSON)
  static Map<String, String> buildCardsOnlyPrompt({
    required String topic,
    required String ageGroup,
    required String conspectContent,
  }) {
    final systemPrompt = '''
Ты — методист дошкольного и начального образования.
Создай набор из 6 раздаточных карточек на лист А4 для занятия по теме "$topic" ($ageGroup).
Формат ответа: СТРОГО только валидный JSON-массив без какого-либо дополнительного текста или markdown-разметки.

Схема каждого объекта:
{
  "front_text": "крупный текст лицевой стороны (буква, слог, слово или краткое задание)",
  "back_text": "подсказка, проверочный ответ или пояснение для ребенка",
  "image_hint": "описание зрительного образа (например: Яблоко, Дом)",
  "type": "letter|syllable|word|task"
}
''';

    final userPrompt = '''
На основе следующего конспекта сформируй ровно 6 карточек для распечатки на листе А4:
$conspectContent

Верни СТРОГО один JSON-массив из 6 карточек.
''';

    return {
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
    };
  }

  /// Создать расширенный промпт с использованием новых сервисов
  static Map<String, String> buildEnhancedPrompt({
    required String methodBlock,
    required String topic,
    required String ageGroup,
    required String duration,
    required String subject,
    String? review,
    String? notes,
    String? situationRules,
    List<String>? activitySamples,
    List<String>? historicalFeedbackTags,
    int? variantIndex,
    int? totalVariants,
  }) {
    final baseSystemPrompt = buildSystemPrompt(
      methodBlock: methodBlock,
      topic: topic,
      ageGroup: ageGroup,
      duration: duration,
      review: review,
      notes: notes,
      situationRules: situationRules,
      activitySamples: activitySamples,
      historicalFeedbackTags: historicalFeedbackTags,
      variantIndex: variantIndex,
      totalVariants: totalVariants,
    );

    // Добавляем рекомендации из новых сервисов
    final enhancedGuidelines = '''

ДОПОЛНИТЕЛЬНЫЕ РЕКОМЕНДАЦИИ ДЛЯ КАЧЕСТВЕННОГО КОНСПЕКТА:

${ChildInteractionService.getExplanationGuidelines(ageGroup)}

Популярные темы для объяснения: ${TopicExplanationService.getPopularTopics(subject, ageGroup).join(', ')}

Пример диалогового сценария:
${ChildInteractionService.createDialogueScenario(topic, ageGroup, false)}

Простое объяснение темы:
${ChildInteractionService.createSimpleExplanation(topic, subject, ageGroup)}

Дополнительные задания для домашней работы:
${ChildInteractionService.createHomeworkAssignments(topic, subject, ageGroup, 7).map((a) => '- $a').join('\n')}

ИГРОВЫЕ ПРИЕМЫ ДЛЯ ВОВЛЕЧЕНИЯ:
- ${ChildInteractionService.getGameTechnique(ageGroup)}
- ${ChildInteractionService.getGameTechnique(ageGroup)}

ВОПРОСЫ ДЛЯ АКТИВАЦИИ МЫШЛЕНИЯ:
- ${ChildInteractionService.getRandomThinkingQuestion()}
- ${ChildInteractionService.getRandomThinkingQuestion()}
''';

    final userPrompt = buildUserPrompt(
      methodName: methodBlock.split('\n').first.replaceAll('Методический подход ', '').replaceAll(':', ''),
      topic: topic,
      ageGroup: ageGroup,
      duration: duration,
      situationTitle: situationRules,
      variantIndex: variantIndex,
    );

    return {
      'systemPrompt': baseSystemPrompt + enhancedGuidelines,
      'userPrompt': userPrompt,
    };
  }

  /// Создать промпт специально для объяснения темы ребенку
  static Map<String, String> buildChildExplanationPrompt({
    required String topic,
    required String subject,
    required String ageGroup,
    required String methodName,
  }) {
    final systemPrompt = '''
Ты — опытный педагог, который умеет объяснять сложные темы простым языком детям.
Твоя задача — создать понятное, интересное объяснение темы "$topic" по предмету "$subject" для $ageGroup.

Используй следующие принципы:
${ChildInteractionService.getExplanationGuidelines(ageGroup)}

Будь креативным, используй аналогии, примеры из жизни ребенка, игровые элементы.
Объяснение должно быть эмоционально окрашенным, поддерживающим и мотивирующим.

Структура объяснения:
1. Введение: заинтересовать ребенка
2. Основное объяснение: просто и понятно
3. Примеры из жизни: показать практическую пользу
4. Игровой элемент: вовлечь в процесс
5. Закрепление: вопросы и практическое задание
''';

    final explanationTemplate = TopicExplanationService.getExplanation(subject, topic, ageGroup) ?? 
        'Объясни тему "$topic" так, чтобы было интересно и понятно ребенку.';

    final userPrompt = '''
Создай объяснение темы "$topic" ($subject) для $ageGroup по методике "$methodName".

Используй этот шаблон как основу:
$explanationTemplate

Добавь:
- 2-3 ярких примера из жизни ребенка
- 1 игровой элемент для закрепления
- 3 вопроса для проверки понимания
- Поддерживающие и мотивирующие фразы

Объяснение должно быть на 1-2 минуты чтения вслух.
''';

    return {
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
    };
  }
}
