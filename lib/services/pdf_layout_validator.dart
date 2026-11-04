import '../models/conspect.dart';
import 'pdf_export_service.dart';
import 'topic_explanation_service.dart';

/// Отчёт об аудите и автоматическом исправлении вёрстки PDF-материалов
class PdfLayoutAuditReport {
  /// Валиден ли контент (все задания соединены с дидактическими полями, нет сиротских заголовков)
  final bool isValid;

  /// Общее количество найденных упражнений/заданий
  final int totalTasksFound;

  /// Количество заданий с гарантированными дидактическими полями
  final int tasksWithDidacticFields;

  /// Количество устранённых сиротских заголовков
  final int orphanHeadersFound;

  /// Список обнаруженных и устранённых дефектов вёрстки
  final List<String> issues;

  /// Очищенный и нормализованный Markdown-контент с гарантированной неразрывностью
  final String repairedContent;

  const PdfLayoutAuditReport({
    required this.isValid,
    required this.totalTasksFound,
    required this.tasksWithDidacticFields,
    required this.orphanHeadersFound,
    required this.issues,
    required this.repairedContent,
  });
}

/// Сервис аудита и защиты структуры документов перед генерацией PDF
class PdfLayoutIntegrityValidator {
  /// Список всех поддерживаемых дидактических маркеров приложения
  static const List<String> didacticMarkers = [
    '[прописи]',
    '[клетка]',
    '[математическая сетка]',
    '[числовой домик]',
    '[домик числа]',
    '[сравнение]',
    '[знаки сравнения]',
    '[окошки]',
    '[шифр]',
    '[шифровка]',
    '[числовой луч]',
    '[хорошо-плохо]',
    '[выбор]',
    '[предметный счет]',
    '[схема предложения]',
    '[состав слова]',
    '[морфемный разбор]',
    '[цепочка]',
    '[числовая цепочка]',
    '[пирамида]',
    '[числовая пирамида]',
    '[графический диктант]',
    '[диаграмма венна]',
    '[круги эйлера]',
    '[кластер]',
    '[древо понятий]',
    '[соедини стрелками]',
    '[ловушка]',
    '[образец]',
    '[звуковой анализ]',
    '[сортировка]',
    '____',
    'линии для ответа',
    'место для ответа',
    'слова для распределения',
    'слова для справок',
    'буквы-помощницы',
    'ловушка',
    'найди ошибк',
    'образец выполнения',
    'образец:',
    'соедини пары',
    'соедини стрелками',
    'секретный код',
    'детектив pro',
    'разгадай',
  ];

  /// Проводит аудит Markdown-контента и устраняет дефекты вёрстки:
  /// 1. Привязывает дидактические поля к каждому заданию без разрывов
  /// 2. Устраняет пустые/сиротские заголовки
  /// 3. Схлопывает лишние пустые строки между заданием и полем для выполнения
  /// 4. Изолирует ключи и предотвращает утечки ответов в тело заданий
  static PdfLayoutAuditReport auditAndRepair(
    String markdownContent, {
    PdfMaterialType? type,
    String? subject,
    String? topic,
    String? ageGroup,
  }) {
    if (markdownContent.trim().isEmpty) {
      return const PdfLayoutAuditReport(
        isValid: false,
        totalTasksFound: 0,
        tasksWithDidacticFields: 0,
        orphanHeadersFound: 0,
        issues: ['Пустой контент документа'],
        repairedContent: '',
      );
    }

    final issues = <String>[];
    int totalTasks = 0;
    int tasksWithFields = 0;
    int orphanHeaders = 0;

    final PedagogicalPackage? pkg = (subject != null && topic != null && ageGroup != null)
        ? TopicExplanationService.getPedagogicalPackage(subject, topic, ageGroup)
        : null;

    final lines = markdownContent.split('\n');
    final processedLines = <String>[];

    String? currentTaskHeader;
    final currentTaskBody = <String>[];
    bool inWorksheetOrHomework = false;
    bool inKeysSection = false;

    void flushTaskBlock() {
      if (currentTaskHeader == null) return;

      // Удаляем любые ошибочно попавшие в тело подзаголовки заданий
      currentTaskBody.removeWhere((b) {
        final bTrim = b.trim().toLowerCase();
        return (bTrim.startsWith('### задание') || bTrim.startsWith('задание:') || bTrim.startsWith('**задание:')) &&
            (bTrim.contains('найди ошибку') || bTrim.contains('исправь') || bTrim.contains('—'));
      });

      final fullTaskText = (currentTaskHeader! + '\n' + currentTaskBody.join('\n')).trim();
      final lower = fullTaskText.toLowerCase();

      totalTasks++;

      // 1. Каноническая нормализация заданий типа «Ловушка Незнайки»
      if (lower.contains('ловушка') || lower.contains('незнайк')) {
        if (pkg != null) {
          for (int b = 0; b < currentTaskBody.length; b++) {
            final bLow = currentTaskBody[b].toLowerCase();
            if (bLow.contains('путаница') || bLow.contains('определение рода') || bLow.contains('типичная ошибка')) {
              currentTaskBody[b] = 'Незнайка утверждает: "${pkg.neznaykaMistake}"';
              issues.add('Заменено теоретическое описание на прямую речь Незнайки из методики');
            }
          }
          if (!currentTaskBody.any((b) => b.contains('Незнайка') || b.contains('незнайк'))) {
            currentTaskBody.insert(0, 'Незнайка утверждает: "${pkg.neznaykaMistake}"');
          }
          if (!currentTaskBody.any((b) => b.toLowerCase().contains('инструкция'))) {
            currentTaskBody.insert(1, '**Инструкция**: Найди ошибку Незнайки и запиши правильный ответ.');
          }
        }
      }

      // 2. Каноническая нормализация сортировочных таблиц
      if (lower.contains('таблиц') || lower.contains('распредели') || lower.contains('по группам')) {
        if (pkg != null && !currentTaskBody.any((b) => b.toLowerCase().contains('слова для распределения') || b.toLowerCase().contains('банк'))) {
          currentTaskBody.add('**Слова для распределения**: ${pkg.wordBank.join(', ')}');
          issues.add('К таблице добавлен эталонный банк слов из методики');
        }
      }

      // 3. Запрет математической клетки на предметах русского языка и чтения
      final isRussianSubject = (subject != null && !subject.toLowerCase().contains('матем')) ||
          lower.contains('слово') ||
          lower.contains('букв') ||
          lower.contains('предложен') ||
          lower.contains('текст') ||
          lower.contains('прилагательн') ||
          lower.contains('существительн') ||
          lower.contains('глагол') ||
          lower.contains('звук') ||
          lower.contains('слог') ||
          lower.contains('падеж') ||
          lower.contains('род ') ||
          lower.contains('читай') ||
          lower.contains('чистописан');

      if (isRussianSubject) {
        for (int b = 0; b < currentTaskBody.length; b++) {
          if (currentTaskBody[b].contains('[клетка]') || currentTaskBody[b].contains('[математическая сетка]')) {
            currentTaskBody[b] = '[прописи]';
            issues.add('Математическая клетка заменена на косую линовку чистописания 65° для языкового предмета');
          }
        }
      }

      // Проверяем наличие дидактического поля внутри блока задания
      bool hasDidacticField = false;
      for (final marker in didacticMarkers) {
        if (lower.contains(marker)) {
          hasDidacticField = true;
          break;
        }
      }

      // Проверка на таблицы Markdown
      if (!hasDidacticField && fullTaskText.contains('|') && fullTaskText.contains('---')) {
        hasDidacticField = true;
      }

      // Если задание находится в листе заданий или домашке, но не имеет поля — автоматически добавляем его!
      if (!hasDidacticField && inWorksheetOrHomework && !inKeysSection) {
        final isRussianOrNonMath = lower.contains('слово') ||
            lower.contains('букв') ||
            lower.contains('предложен') ||
            lower.contains('текст') ||
            lower.contains('прилагательн') ||
            lower.contains('существительн') ||
            lower.contains('глагол') ||
            lower.contains('звук') ||
            lower.contains('слог') ||
            lower.contains('орфограмм') ||
            lower.contains('падеж') ||
            lower.contains('род ') ||
            lower.contains('читай') ||
            lower.contains('чистописан') ||
            lower.contains('пропис') ||
            lower.contains('каллиграф') ||
            lower.contains('сказк');

        final isMath = !isRussianOrNonMath &&
            (lower.contains('вычисли') ||
                lower.contains('реши пример') ||
                lower.contains('задач') ||
                lower.contains('уравнен') ||
                lower.contains('счет') ||
                RegExp(r'\d+\s*[\+\-\*\/]\s*\d+').hasMatch(lower));

        final isWriting = lower.contains('спиши') ||
            lower.contains('прописи') ||
            lower.contains('букв') ||
            lower.contains('предложен') ||
            lower.contains('каллиграф') ||
            lower.contains('чистописан');

        if (isMath) {
          currentTaskBody.add('[клетка]');
          issues.add('К заданию "${_cleanHeader(currentTaskHeader!)}" автоматически привязано математическое поле клеток [клетка]');
        } else if (isWriting) {
          currentTaskBody.add('[прописи]');
          issues.add('К заданию "${_cleanHeader(currentTaskHeader!)}" автоматически привязана косая разлиновка чистописания [прописи]');
        } else {
          currentTaskBody.add('Линии для ответа: _______________________');
          issues.add('К заданию "${_cleanHeader(currentTaskHeader!)}" автоматически привязаны строки для аккуратного ответа');
        }
        hasDidacticField = true;
      }

      // Если в задании с образцом остался только сам образец без пунктов для работы ученика
      if (lower.contains('образец') && !currentTaskBody.any((b) => b.contains('1)') || b.contains('1.') || b.contains('___'))) {
        currentTaskBody.add('**Инструкция**: Прочитай образец и выполни задание для остальных слов (сделай сам):');
        if (pkg != null && pkg.wordBank.length >= 3) {
          currentTaskBody.add('1) ${pkg.wordBank[1]} — _______________________');
          currentTaskBody.add('2) ${pkg.wordBank[2]} — _______________________');
          currentTaskBody.add('3) ${pkg.wordBank.length > 3 ? pkg.wordBank[3] : pkg.wordBank[0]} — _______________________');
        } else {
          currentTaskBody.add('1) _______________________ — _______________________');
          currentTaskBody.add('2) _______________________ — _______________________');
          currentTaskBody.add('3) _______________________ — _______________________');
        }
        issues.add('К заданию с образцом добавлены интерактивные пункты для самостоятельной работы ученика');
      }

      if (hasDidacticField) {
        tasksWithFields++;
      }

      // Добавляем неразрывный блок задания в итоговый контент
      processedLines.add(currentTaskHeader!);
      for (final bLine in currentTaskBody) {
        processedLines.add(bLine);
      }

      currentTaskHeader = null;
      currentTaskBody.clear();
    }

    int i = 0;
    while (i < lines.length) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      // Отслеживание перехода в разделы листа заданий / домашки / ключей
      final lowerTrimmed = trimmed.toLowerCase();
      if (trimmed.startsWith('#')) {
        final isMajorSectionHeader = (trimmed.startsWith('# ') && !trimmed.startsWith('##')) ||
            lowerTrimmed.contains('лист заданий') ||
            lowerTrimmed.contains('рабочий лист') ||
            lowerTrimmed.contains('домашн') ||
            lowerTrimmed.contains('раздаточн') ||
            lowerTrimmed.contains('ключи') ||
            lowerTrimmed.contains('ответы');

        if (isMajorSectionHeader) {
          flushTaskBlock();

          if (lowerTrimmed.contains('лист заданий') ||
              lowerTrimmed.contains('рабочий лист') ||
              lowerTrimmed.contains('домашн') ||
              lowerTrimmed.contains('раздаточн')) {
            inWorksheetOrHomework = true;
            inKeysSection = false;
          } else if (lowerTrimmed.contains('ключи') || lowerTrimmed.contains('ответы')) {
            inKeysSection = true;
          } else if (trimmed.startsWith('# ') && !trimmed.startsWith('##')) {
            inWorksheetOrHomework = false;
            inKeysSection = false;
          }
        }
        // Проверка на сиротский заголовок (заголовок без содержимого перед следующим заголовком)
        if (i + 1 < lines.length) {
          int nextIdx = i + 1;
          while (nextIdx < lines.length && lines[nextIdx].trim().isEmpty) {
            nextIdx++;
          }
          if (nextIdx < lines.length && lines[nextIdx].trim().startsWith('#')) {
            final nextHeader = lines[nextIdx].trim();
            // Если подряд идут два заголовка без текста между ними
            if (!trimmed.startsWith('# ') && !nextHeader.startsWith('# ')) {
              orphanHeaders++;
              issues.add('Обнаружен пустой сиротский заголовок: "$trimmed" — нормализован');
              // Пропускаем пустой заголовок, чтобы не плодить пустые карточки
              i++;
              continue;
            }
          }
        }
      }

      // Проверка на обнаружение заголовка задания
      final isTaskHeader = _isTaskHeaderLine(trimmed);

      // 1. Проверяем, не является ли это ложным заголовком-инструкцией от предыдущей ловушки
      final bool isFollowupTrapInstruction = isTaskHeader &&
          currentTaskHeader != null &&
          (lowerTrimmed.contains('найди ошибк') ||
              lowerTrimmed.contains('исправь ошибк') ||
              lowerTrimmed.contains('незнайк') ||
              lowerTrimmed.contains('запиши правильн')) &&
          (currentTaskHeader!.toLowerCase().contains('ловушк') ||
              currentTaskBody.any((b) => b.toLowerCase().contains('незнайк')));

      if (isFollowupTrapInstruction) {
        final cleanInstruction = trimmed.replaceAll(
          RegExp(r'^#{1,6}\s*(?:задание|упражнение)?[:\.\-\s]*', caseSensitive: false),
          '',
        ).trim();
        if (cleanInstruction.isNotEmpty) {
          currentTaskBody.add('**Инструкция**: $cleanInstruction');
          issues.add('Объединен дублирующий заголовок инструкции ловушки с основным заданием');
        }
        i++;
        continue;
      }

      // 2. Проверяем, не является ли это пунктом-решением, ошибочно оформленным как отдельный заголовок после Образца
      final bool isFollowupSampleItem = isTaskHeader &&
          currentTaskHeader != null &&
          (currentTaskHeader!.toLowerCase().contains('образец') ||
              currentTaskBody.any((b) => b.toLowerCase().contains('образец'))) &&
          trimmed.contains('—') &&
          !lowerTrimmed.contains('задание 2') &&
          !lowerTrimmed.contains('задание 3');

      if (isFollowupSampleItem) {
        final cleanItem = trimmed.replaceAll(
          RegExp(r'^#{1,6}\s*(?:задание|упражнение)?[:\.\-\s]*', caseSensitive: false),
          '',
        ).trim();
        final parts = cleanItem.split('—');
        if (parts.length >= 2) {
          final wordPart = parts[0].trim();
          currentTaskBody.add('1) $wordPart — _______________________');
        } else {
          currentTaskBody.add('1) $cleanItem');
        }
        issues.add('Преобразован решенный пункт образца в интерактивное упражнение с пропуском');
        i++;
        continue;
      }

      if (isTaskHeader && !inKeysSection) {
        flushTaskBlock();
        currentTaskHeader = trimmed;
        i++;
        continue;
      }

      // Если мы внутри блока задания — накапливаем строки задания
      if (currentTaskHeader != null) {
        // Если встретили новый заголовок раздела — сбрасываем текущее задание
        if (trimmed.startsWith('#')) {
          flushTaskBlock();
          processedLines.add(trimmed);
        } else {
          // Игнорируем пустые строки в начале блока задания
          if (currentTaskBody.isNotEmpty || trimmed.isNotEmpty) {
            currentTaskBody.add(trimmed);
          }
        }
        i++;
        continue;
      }

      processedLines.add(trimmed);
      i++;
    }

    flushTaskBlock();

    final repairedText = processedLines.join('\n');
    final isValid = (totalTasks == 0 || tasksWithFields == totalTasks);

    return PdfLayoutAuditReport(
      isValid: isValid,
      totalTasksFound: totalTasks,
      tasksWithDidacticFields: tasksWithFields,
      orphanHeadersFound: orphanHeaders,
      issues: issues,
      repairedContent: repairedText,
    );
  }

  /// Проверяет, является ли строка заголовком задания
  static bool _isTaskHeaderLine(String line) {
    if (line.isEmpty) return false;
    final lower = line.toLowerCase();

    // Задание 1..., **Задание 1**, ### Задание 1...
    if (lower.contains('задание')) {
      final hasNumberOrColon = RegExp(r'(?:задание|упражнение)\s*(?:\d+|:|\.)', caseSensitive: false).hasMatch(lower);
      final hasBoldMarker = lower.contains('**задание') || lower.contains('## задание');
      return hasNumberOrColon || hasBoldMarker;
    }

    // 1. ..., 2) ... на верхнем уровне
    if (RegExp(r'^(?:#{2,6}\s+)?\d+[\.\)]\s+').hasMatch(line)) {
      return true;
    }

    return false;
  }

  static String _cleanHeader(String raw) {
    return raw.replaceAll(RegExp(r'[#\*]'), '').trim();
  }
}
