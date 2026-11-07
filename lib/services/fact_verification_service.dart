/// Результат автоматической верификации фактологии и педагогических данных
class FactVerificationResult {
  final String repairedContent;
  final List<String> appliedCorrections;
  final bool hasCorrections;

  const FactVerificationResult({
    required this.repairedContent,
    required this.appliedCorrections,
    required this.hasCorrections,
  });
}

/// Сервис автоматической верификации и коррекции фактологии (Guardrails & Fact-Checking).
/// Проверяет математические расчеты, правила начальной школы (фонетика, орфография)
/// и предотвращает утечку готовых ответов в раздаточные листы.
class FactVerificationService {
  /// Проверить и исправить конспект/материал
  static FactVerificationResult verifyAndRepair(
    String content, {
    String? subject,
    String? ageGroup,
    String? duration,
  }) {
    var text = content;
    final corrections = <String>[];

    // 1. Верификация математических примеров (вычисления сложения, вычитания, умножения)
    text = _verifyMathCalculations(text, corrections);

    // 2. Верификация фонетических и грамматических правил русского языка
    text = _verifyRussianLanguageRules(text, corrections);

    // 3. Санитизация детских заданий (удаление случайных подсказок и ответов в теле упражнений)
    text = _sanitizeWorksheetLeakage(text, corrections);

    // 4. Верификация соответствия хронометража этапов заявленной длительности
    if (duration != null && duration.trim().isNotEmpty) {
      text = _verifyStageTimings(text, duration, corrections);
    }

    return FactVerificationResult(
      repairedContent: text,
      appliedCorrections: corrections,
      hasCorrections: corrections.isNotEmpty,
    );
  }

  /// Проверка и контроль суммарного хронометража этапов урока под заявленную длительность
  static String _verifyStageTimings(String input, String declaredDuration, List<String> corrections) {
    final matchMins = RegExp(r'(\d+)').firstMatch(declaredDuration);
    if (matchMins == null) return input;
    final targetMins = int.tryParse(matchMins.group(1)!) ?? 45;

    final timingRegex = RegExp(r'\[\s*(?:Тайминг|Время|Хронометраж)\s*:\s*(\d+)\s*(?:–\s*\d+)?\s*мин[^\]]*\]', caseSensitive: false);
    final matches = timingRegex.allMatches(input).toList();

    if (matches.length >= 2) {
      int sumMins = 0;
      for (final m in matches) {
        sumMins += int.tryParse(m.group(1) ?? '0') ?? 0;
      }

      if (sumMins > 0 && (sumMins - targetMins).abs() > (targetMins * 0.25).round().clamp(3, 15)) {
        corrections.add('Зафиксировано расхождение хронометража этапов с заявленной длительностью урока ($sumMins мин при плане $targetMins мин)');
      }
    }

    return input;
  }

  /// Проверка арифметических выражений вида `X + Y = Z`, `X - Y = Z`, `X * Y = Z`
  static String _verifyMathCalculations(String input, List<String> corrections) {
    final eqRegex = RegExp(r'(?<!\w)(\d{1,4})\s*([\+\-\*×·:])\s*(\d{1,4})\s*=\s*(\d{1,5})(?!\w)');

    return input.replaceAllMapped(eqRegex, (match) {
      final a = int.tryParse(match.group(1) ?? '');
      final op = match.group(2) ?? '';
      final b = int.tryParse(match.group(3) ?? '');
      final declaredResult = int.tryParse(match.group(4) ?? '');

      if (a == null || b == null || declaredResult == null) {
        return match.group(0)!;
      }

      int? expected;
      if (op == '+') {
        expected = a + b;
      } else if (op == '-' && a >= b) {
        expected = a - b;
      } else if (op == '*' || op == '×' || op == '·') {
        expected = a * b;
      } else if ((op == ':' || op == '/') && b != 0 && a % b == 0) {
        expected = a ~/ b;
      }

      if (expected != null && expected != declaredResult) {
        corrections.add('Исправлена арифметическая ошибка: $a $op $b = $declaredResult -> $expected');
        return '$a $op $b = $expected';
      }

      return match.group(0)!;
    });
  }

  /// Проверка канонических правил начальной школы по русскому языку
  static String _verifyRussianLanguageRules(String input, List<String> corrections) {
    var text = input;

    // Ошибка: "10 гласных звуков" (в русском языке 10 гласных букв, но только 6 гласных звуков)
    final soundErrorRegex = RegExp(r'10\s+гласных\s+звуков', caseSensitive: false);
    if (soundErrorRegex.hasMatch(text)) {
      text = text.replaceAll(
        soundErrorRegex,
        '10 гласных букв и 6 основных гласных звуков ([а], [о], [у], [ы], [и], [э])',
      );
      corrections.add('Исправлено утверждение о количестве гласных звуков (в русском языке 6 звуков, 10 букв)');
    }

    // Ошибка: указание звука [й] как парного согласного
    final jSoftError = RegExp(r'звук\s*\[й\]\s*бывает\s*тв[её]рдым', caseSensitive: false);
    if (jSoftError.hasMatch(text)) {
      text = text.replaceAll(jSoftError, 'звук [й\'] всегда мягкий непарный');
      corrections.add('Исправлено свойство звука [й\'] (всегда мягкий)');
    }

    // Ошибка: утверждение что [ж] и [ш] бывают мягкими
    final zhShError = RegExp(r'звуки\s*\[ж\]\s*и\s*\[ш\]\s*бывают\s*мягкими', caseSensitive: false);
    if (zhShError.hasMatch(text)) {
      text = text.replaceAll(zhShError, 'звуки [ж] и [ш] всегда твёрдые непарные');
      corrections.add('Исправлено свойство звуков [ж] и [ш] (всегда твёрдые)');
    }

    return text;
  }

  /// Защита от утечки ответов в рабочих листах
  static String _sanitizeWorksheetLeakage(String input, List<String> corrections) {
    var text = input;

    // Удаление явных меток (ответ: ...) внутри заданий с пропусками
    final answerLeakRegex = RegExp(r'\(\s*(?:ответ|решение|проверка)\s*:[^\)]+\)', caseSensitive: false);
    if (answerLeakRegex.hasMatch(text)) {
      // Удаляем только из контекста заданий (не из методического блока для учителя)
      final parts = text.split(RegExp(r'(?=##\s*(?:Ответы|Методический блок|Критерии|Самооценка))', caseSensitive: false));
      if (parts.isNotEmpty) {
        var studentPart = parts.first;
        if (answerLeakRegex.hasMatch(studentPart)) {
          studentPart = studentPart.replaceAll(answerLeakRegex, '______');
          corrections.add('Удалена утечка готового ответа из блока заданий ученика');
          text = studentPart + (parts.length > 1 ? parts.sublist(1).join() : '');
        }
      }
    }

    // Удаление плейсхолдеров типа [вставьте слово]
    final placeholderRegex = RegExp(r'\[\s*(?:вставьте|укажите|напишите|слово\s*\d+)[^\]]*\]', caseSensitive: false);
    if (placeholderRegex.hasMatch(text)) {
      text = text.replaceAll(placeholderRegex, '________________');
      corrections.add('Заменены шаблонные плейсхолдеры [вставьте ...] на строки для заполнения');
    }

    return text;
  }
}
