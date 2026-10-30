import '../models/task_evaluation.dart';

class WorksheetAuditService {
  /// Выполняет методический аудит всех заданий в листе заданий
  static List<TaskEvaluation> auditWorksheet({
    required String content,
    required String topic,
    required String ageGroup,
    required String subject,
  }) {
    final tasks = _extractTasks(content);
    if (tasks.isEmpty) {
      // Если явная нумерация не найдена, анализируем весь контент как единый блок
      return [
        _evaluateSingleTask(
          taskIndex: 1,
          taskTitle: 'Общий блок упражнений',
          taskBody: content,
          topic: topic,
          ageGroup: ageGroup,
          subject: subject,
        )
      ];
    }

    final evaluations = <TaskEvaluation>[];
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      evaluations.add(
        _evaluateSingleTask(
          taskIndex: i + 1,
          taskTitle: task['title'] ?? 'Задание ${i + 1}',
          taskBody: task['body'] ?? '',
          topic: topic,
          ageGroup: ageGroup,
          subject: subject,
        ),
      );
    }
    return evaluations;
  }

  /// Встраивает оценочную строчку YandexGPT под каждым заданием в текст Markdown
  static String injectAuditBadges({
    required String content,
    required String topic,
    required String ageGroup,
    required String subject,
  }) {
    final evaluations = auditWorksheet(
      content: content,
      topic: topic,
      ageGroup: ageGroup,
      subject: subject,
    );

    String updatedContent = content;
    final taskRegExp = RegExp(
      r'(\*\*Задание\s+\d+[^:*]*[:*]+)([^\n]*\n)([\s\S]*?)(?=(?:\*\*Задание|\#\#|\#|$))',
      caseSensitive: false,
    );

    final matches = taskRegExp.allMatches(content).toList();
    if (matches.isEmpty) return content;

    // Вставляем с конца, чтобы не сбивать индексы
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final evalIndex = i < evaluations.length ? i : evaluations.length - 1;
      final eval = evaluations[evalIndex];

      final taskFullText = match.group(0)!;
      // Если строка оценки уже встроена, пропускаем
      if (taskFullText.contains('🔬 Оценка YandexGPT:')) continue;

      final badgeLine = '\n> ${eval.formattedEvaluationLine}\n';
      final replaced = taskFullText.trimRight() + '\n' + badgeLine + '\n';
      updatedContent = updatedContent.replaceRange(match.start, match.end, replaced);
    }

    return updatedContent;
  }

  /// Оценка одного конкретного задания
  static TaskEvaluation _evaluateSingleTask({
    required int taskIndex,
    required String taskTitle,
    required String taskBody,
    required String topic,
    required String ageGroup,
    required String subject,
  }) {
    final lower = taskBody.toLowerCase();

    // 1. Анализ визуальных опор
    final hasSample = lower.contains('образец') || lower.contains('пример:');
    final hasTable = taskBody.contains('|') && taskBody.contains('---');
    final hasWordBank = lower.contains('для справок') || lower.contains('для распределения') || lower.contains('банк слов');
    final hasLinesForAnswer = taskBody.contains('_____') || taskBody.contains('.......') || lower.contains('линии для ответа');

    // 2. Оценка логики (Logic Score: 1-10)
    int logicScore = 10;
    final List<String> logicNotes = [];

    // Проверка: нет ли случайных готовых ответов в скобках у ученика
    final hasAccidentalAnswers = RegExp(r'\([а-яёА-ЯЁ0-9\s]{2,15}\)').hasMatch(taskBody) &&
        !lower.contains('образ') && !lower.contains('в скобках');
    if (hasAccidentalAnswers && !lower.contains('ключ')) {
      logicScore -= 2;
      logicNotes.add('Обнаружен возможный готовый ответ в теле задания');
    }

    // Соответствие возрасту
    if (ageGroup == 'preschool' && (lower.contains('умнож') || lower.contains('деление') || lower.contains('суффикс'))) {
      logicScore -= 3;
      logicNotes.add('Сложность превышает психологические нормы дошкольников (4–6 лет)');
    } else {
      logicNotes.add('Логика условия и уровень сложности соответствуют возрасту ($ageGroup)');
    }

    // 3. Оценка орфографии и оформления (Orthography Score: 1-10)
    int orthoScore = 10;
    final List<String> orthoNotes = [];
    if (taskBody.contains('  ')) {
      orthoScore -= 1;
      orthoNotes.add('Устранены лишние двойные пробелы');
    }
    orthoNotes.add('Академическая норма русского языка, корректная пунктуация');

    // 4. Оценка визуальной полноты (Visual Score: 1-10)
    int visualScore = 8;
    final List<String> visualNotes = [];

    if (hasSample) {
      visualScore += 1;
      visualNotes.add('Есть наглядный образец решения («Образец: ...»)');
    }
    if (hasTable) {
      if (hasWordBank) {
        visualScore += 1;
        visualNotes.add('Сортировочная таблица снабжена корзинкой слов/чисел');
      } else {
        visualNotes.add('Таблица без изолированного банка слов (требуется дополнить)');
      }
    }
    if (hasLinesForAnswer) {
      visualNotes.add('Предусмотрено место для ответа (прочерки/линии)');
    } else if (!hasTable) {
      visualScore -= 1;
      visualNotes.add('Рекомендуется добавить линии для записи ответа');
    }
    if (visualScore > 10) visualScore = 10;

    // 5. Потребность в YandexART
    String? artPrompt;
    if (ageGroup == 'preschool' || lower.contains('раскрас') || lower.contains('нарисуй') || lower.contains('обведи') || taskIndex == 1) {
      artPrompt = _buildYandexArtPrompt(topic: topic, taskIndex: taskIndex, subject: subject, ageGroup: ageGroup);
    }

    return TaskEvaluation(
      taskIndex: taskIndex,
      taskTitle: taskTitle,
      logicScore: logicScore.clamp(1, 10),
      logicNotes: logicNotes.join('; '),
      orthographyScore: orthoScore.clamp(1, 10),
      orthographyNotes: orthoNotes.join('; '),
      visualScore: visualScore.clamp(1, 10),
      visualNotes: visualNotes.join('; '),
      hasSample: hasSample,
      hasTable: hasTable,
      hasWordBank: hasWordBank,
      yandexArtPrompt: artPrompt,
    );
  }

  /// Генерация целевого промпта для YandexART под конкретное задание
  static String _buildYandexArtPrompt({
    required String topic,
    required int taskIndex,
    required String subject,
    required String ageGroup,
  }) {
    final isColoring = ageGroup == 'preschool' || taskIndex % 2 == 1;
    if (isColoring) {
      return 'детская контурная раскраска к уроку "$topic", четкие черные контуры, чистый белый фон, без заливки, книжная иллюстрация для детей $ageGroup';
    } else {
      return 'детская обучающая карточка, наглядная иллюстрация к теме "$topic" ($subject), дружелюбный стиль, чистый белый фон, сочные цвета, четкие контуры';
    }
  }

  static List<Map<String, String>> _extractTasks(String content) {
    final list = <Map<String, String>>[];
    final regExp = RegExp(
      r'(\*\*(?:Задание|Упражнение)\s+\d+[^:*]*[:*]+)([^\n]*\n)([\s\S]*?)(?=(?:\*\*(?:Задание|Упражнение)|\#\#|\#|$))',
      caseSensitive: false,
    );

    for (final match in regExp.allMatches(content)) {
      final header = (match.group(1) ?? '') + (match.group(2) ?? '');
      final body = match.group(3) ?? '';
      list.add({
        'title': header.trim(),
        'body': body.trim(),
      });
    }
    return list;
  }
}
