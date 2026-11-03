import 'dart:convert';
import '../models/method_prompt.dart';
import '../models/quarter_plan.dart';
import '../models/topic.dart';
import 'ai_service.dart';

class QuarterPlanningService {
  final AiService _aiService;

  QuarterPlanningService({required AiService aiService}) : _aiService = aiService;

  /// Формирует план на четверть из 8-16 уроков
  Future<QuarterPlan> createQuarterPlan({
    required MethodPrompt method,
    required String ageGroup,
    required int quarterNumber,
    required int lessonsCount,
    required List<Topic> repositoryTopics,
    bool useAi = true,
  }) async {
    final matchingTopics = repositoryTopics.where((t) {
      final methodMatch = t.methodId == method.id;
      final ageMatch = t.ageGroup == ageGroup ||
          (ageGroup == '1 класс' && t.ageGroup == 'grade_1') ||
          (ageGroup == '2 класс' && t.ageGroup == 'grade_2') ||
          (ageGroup.toLowerCase().contains('дошкол') && t.ageGroup == 'preschool');
      return methodMatch && ageMatch;
    }).toList();

    List<QuarterTopicItem> generatedTopics = [];

    if (useAi && _aiService.hasAnyKeyConfigured()) {
      try {
        generatedTopics = await _generateTopicsWithAi(
          method: method,
          ageGroup: ageGroup,
          quarterNumber: quarterNumber,
          lessonsCount: lessonsCount,
          matchingRepoTopics: matchingTopics,
        );
      } catch (_) {
        // Fallback на локальный банк тем
        generatedTopics = _generateTopicsFromRepo(
          method: method,
          quarterNumber: quarterNumber,
          lessonsCount: lessonsCount,
          matchingRepoTopics: matchingTopics,
        );
      }
    } else {
      generatedTopics = _generateTopicsFromRepo(
        method: method,
        quarterNumber: quarterNumber,
        lessonsCount: lessonsCount,
        matchingRepoTopics: matchingTopics,
      );
    }

    final planId = '${DateTime.now().millisecondsSinceEpoch}_q${quarterNumber}_${method.id}';
    return QuarterPlan(
      id: planId,
      subject: method.subject,
      methodId: method.id,
      methodName: method.name,
      ageGroup: ageGroup,
      quarterNumber: quarterNumber,
      topics: generatedTopics,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCalendarScheduled: false,
    );
  }

  /// Локальная генерация тем из проверенного банка тем
  List<QuarterTopicItem> _generateTopicsFromRepo({
    required MethodPrompt method,
    required int quarterNumber,
    required int lessonsCount,
    required List<Topic> matchingRepoTopics,
  }) {
    final List<QuarterTopicItem> result = [];
    final pool = List<Topic>.from(matchingRepoTopics);

    // Смещаем выборку в зависимости от номера четверти
    final offset = ((quarterNumber - 1) * lessonsCount) % (pool.isEmpty ? 1 : pool.length);
    final sortedPool = pool.isEmpty ? <Topic>[] : [...pool.sublist(offset), ...pool.sublist(0, offset)];

    for (int i = 0; i < lessonsCount; i++) {
      if (i < sortedPool.length) {
        final t = sortedPool[i];
        result.add(QuarterTopicItem(
          id: '${t.id}_$i',
          lessonIndex: i + 1,
          title: t.title,
          description: t.description.isNotEmpty ? t.description : 'Урок $i четверти $quarterNumber',
          status: QuarterTopicStatus.pending,
        ));
      } else {
        result.add(QuarterTopicItem(
          id: 'generated_topic_${quarterNumber}_${i + 1}',
          lessonIndex: i + 1,
          title: 'Тема ${i + 1}: Закрепление и практикум по предмету "${method.subject}"',
          description: 'Обобщающий урок по методике ${method.name}',
          status: QuarterTopicStatus.pending,
        ));
      }
    }

    return result;
  }

  /// ИИ-генерация календарно-тематического плана на четверть
  Future<List<QuarterTopicItem>> _generateTopicsWithAi({
    required MethodPrompt method,
    required String ageGroup,
    required int quarterNumber,
    required int lessonsCount,
    required List<Topic> matchingRepoTopics,
  }) async {
    final repoSample = matchingRepoTopics.take(6).map((t) => t.title).join('; ');

    final systemPrompt = '''
Ты — ведущий завуч и методист начального образования высшей квалификационной категории.
Твоя задача — составить последовательный, дидактически безупречный календарно-тематический план (КТП) на $quarterNumber четверть по предмету "${method.subject}" (${method.name}) для возраста: $ageGroup.
Количество уроков: строго $lessonsCount уроков.

Примеры тем из программы: $repoSample.

ТРЕБОВАНИЯ К КТП:
1. Логическая преемственность: от простого к сложному.
2. В первой трети четверти — входное повторение и ввод ключевых понятий.
3. В середине — углубленная практика и дифференциация.
4. В конце — обобщение, проверочный практикум и рефлексия.
5. Формат ответа — строго валидный JSON-массив строк без лишнего текста:
["Тема 1: ...", "Тема 2: ...", ..., "Тема $lessonsCount: ..."]
''';

    final userPrompt = 'Сгенерируй список из $lessonsCount тем на $quarterNumber четверть:';

    final response = await _aiService.generate(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    final cleanJson = _extractJsonArray(response);
    if (cleanJson != null && cleanJson.isNotEmpty) {
      final List<QuarterTopicItem> result = [];
      for (int i = 0; i < cleanJson.length && i < lessonsCount; i++) {
        final title = cleanJson[i].toString().replaceAll(RegExp(r'^(?:Тема\s*\d+[:\.\s]*|Урок\s*\d+[:\.\s]*)'), '').trim();
        result.add(QuarterTopicItem(
          id: 'ai_quarter_topic_${quarterNumber}_${i + 1}',
          lessonIndex: i + 1,
          title: title.isNotEmpty ? title : 'Урок ${i + 1}',
          description: 'Урок $quarterNumber четверти по методике ${method.name}',
          status: QuarterTopicStatus.pending,
        ));
      }
      if (result.length == lessonsCount) {
        return result;
      }
    }

    throw Exception('AI JSON parsing fallback required');
  }

  /// Предлагает альтернативную тему для замены
  Future<String> getAlternativeTopic({
    required QuarterPlan plan,
    required int targetIndex,
    required List<Topic> repositoryTopics,
    String? teacherHint,
  }) async {
    final prevTitle = targetIndex > 0 ? plan.topics[targetIndex - 1].title : 'Начало четверти';
    final nextTitle = targetIndex < plan.topics.length - 1 ? plan.topics[targetIndex + 1].title : 'Конец четверти';

    if (_aiService.hasAnyKeyConfigured()) {
      try {
        final sysPrompt = '''
Ты — методист начальной школы. Пользователь хочет заменить тему урока №${targetIndex + 1} в КТП на ${plan.quarterNumber} четверть.
Предмет: ${plan.subject}.
Методика: ${plan.methodName}.
Возраст: ${plan.ageGroup}.
Предыдущий урок: "$prevTitle".
Следующий урок: "$nextTitle".
Пожелание учителя: ${teacherHint ?? "предложи актуальную тему, идеально связывающую предыдущий и следующий уроки"}.

Верни ТОЛЬКО одну емкую и красивую формулировку темы на 4-8 слов без кавычек и префиксов.
''';
        final userPrompt = 'Предложи замену для урока №${targetIndex + 1}:';
        final res = await _aiService.generate(systemPrompt: sysPrompt, userPrompt: userPrompt);
        final clean = res.replaceAll(RegExp(r'^["«]+|["»]+$'), '').trim();
        if (clean.isNotEmpty && clean.length > 3) {
          return clean;
        }
      } catch (_) {}
    }

    // Локальный подбор из неиспользованных тем репозитория
    final currentTitles = plan.topics.map((t) => t.title.toLowerCase()).toSet();
    final unused = repositoryTopics.where((t) => !currentTitles.contains(t.title.toLowerCase())).toList();
    if (unused.isNotEmpty) {
      return unused.first.title;
    }

    return 'Практикум и закрепление темы "$prevTitle"';
  }

  /// Проверяет полноту и качество сгенерированного конспекта урока
  ({bool isValid, List<String> missingSections, bool hasAnswerLeaks, int charCount}) validateLessonCompleteness(
    String content, {
    int minCharCount = 400,
  }) {
    final lower = content.toLowerCase();
    final missing = <String>[];

    final hasGoals = lower.contains('# цель') || lower.contains('# задачи') || lower.contains('цели и задачи');
    if (!hasGoals) missing.add('Цели и задачи');

    final hasTheory = lower.contains('# теор') || lower.contains('теоретическ') || lower.contains('объяснение темы');
    if (!hasTheory) missing.add('Теория / Объяснение темы');

    final hasScenario = lower.contains('# ход занятия') || lower.contains('ход урока') || lower.contains('сценарий');
    if (!hasScenario) missing.add('Ход занятия');

    final hasWorksheet = lower.contains('# лист заданий') || lower.contains('рабочий лист') || lower.contains('раздаточный лист');
    if (!hasWorksheet) missing.add('Раздаточный лист');

    final hasHomework = lower.contains('# домашн') || lower.contains('домашняя работа') || lower.contains('домашнее задание');
    if (!hasHomework) missing.add('Домашняя работа');

    final hasKeys = lower.contains('ключи') || lower.contains('ответы для учителя');
    if (!hasKeys) missing.add('Ключи для учителя');

    // Проверка на утечки ответов
    final hasAnswerLeaks = lower.contains('(ответ:') ||
        lower.contains('(решение:') ||
        lower.contains('[вставьте') ||
        lower.contains('[укажите') ||
        lower.contains('[слово 1]');

    final charCount = content.trim().length;
    final isLengthValid = charCount >= minCharCount;

    final isValid = missing.isEmpty && !hasAnswerLeaks && isLengthValid;
    return (
      isValid: isValid,
      missingSections: missing,
      hasAnswerLeaks: hasAnswerLeaks,
      charCount: charCount,
    );
  }

  /// Распределяет даты занятий по календарю с шагом по выбранным дням недели
  List<DateTime> calculateScheduleDates({
    required DateTime startDate,
    required List<int> weekdays, // e.g. [DateTime.monday, DateTime.wednesday, DateTime.friday]
    required int totalLessons,
  }) {
    if (weekdays.isEmpty || totalLessons <= 0) return [];

    final List<DateTime> dates = [];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);

    while (dates.length < totalLessons) {
      if (weekdays.contains(current.weekday)) {
        dates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  static List<dynamic>? _extractJsonArray(String raw) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        final jsonStr = raw.substring(start, end + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) return decoded;
      }
    } catch (_) {}
    return null;
  }
}
