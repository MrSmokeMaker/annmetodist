class LessonStage {
  final int stageNumber;
  final String title;
  final int durationMinutes;
  final String content;

  LessonStage({
    required this.stageNumber,
    required this.title,
    required this.durationMinutes,
    required this.content,
  });

  int get durationSeconds => durationMinutes * 60;

  static List<LessonStage> parseFromConspect(String content, String totalDurationStr) {
    // 1. Извлечь секцию «Ход занятия»
    String lessonWalkthrough = '';
    final sectionMatch = RegExp(
      r'#+\s*(?:3\.\s*)?Ход занятия[^\n]*\n([\s\S]*?)(?=(?:\n#+\s*(?:[4-9]|\w)|\Z))',
      caseSensitive: false,
    ).firstMatch(content);

    if (sectionMatch != null) {
      lessonWalkthrough = sectionMatch.group(1) ?? '';
    } else {
      lessonWalkthrough = content;
    }

    // Парсинг этапов
    final List<LessonStage> stages = [];
    final lines = lessonWalkthrough.split('\n');

    String currentTitle = '';
    int currentMinutes = 0;
    final StringBuffer currentBody = StringBuffer();
    int stageIndex = 1;

    // Регулярка для этапа: «1. Организационный момент (3 мин)», «## 2. ...», «Этап 3: ...»
    final stageHeaderRegex = RegExp(
      r'^(?:#+\s*)?(?:Этап\s+)?(\d+)[\.\)]\s*([^\n\(\—\-]+)(?:[\(\—\-]\s*(\d+)\s*(?:–\s*\d+)?\s*мин[^\)]*\)?)?',
      caseSensitive: false,
    );

    for (final line in lines) {
      final trimmed = line.trim();
      final match = stageHeaderRegex.firstMatch(trimmed);

      if (match != null && (trimmed.startsWith('#') || RegExp(r'^\d+[\.\)]').hasMatch(trimmed) || trimmed.toLowerCase().startsWith('этап'))) {
        if (currentTitle.isNotEmpty || currentBody.isNotEmpty) {
          stages.add(
            LessonStage(
              stageNumber: stageIndex++,
              title: currentTitle.isEmpty ? 'Вводная часть' : currentTitle,
              durationMinutes: currentMinutes > 0 ? currentMinutes : 5,
              content: currentBody.toString().trim(),
            ),
          );
          currentBody.clear();
        }

        currentTitle = match.group(2)?.trim() ?? 'Этап $stageIndex';
        final minutesStr = match.group(3);
        currentMinutes = minutesStr != null ? (int.tryParse(minutesStr) ?? 5) : 5;
      } else {
        currentBody.writeln(line);
      }
    }

    if (currentTitle.isNotEmpty || currentBody.isNotEmpty) {
      stages.add(
        LessonStage(
          stageNumber: stageIndex,
          title: currentTitle.isEmpty ? 'Ход занятия' : currentTitle,
          durationMinutes: currentMinutes > 0 ? currentMinutes : 5,
          content: currentBody.toString().trim(),
        ),
      );
    }

    // Фолбек: если модель выдала сплошной текст без четких номеров этапов
    if (stages.isEmpty) {
      final totalMins = _parseTotalMinutes(totalDurationStr);
      final parts = content.split(RegExp(r'\n(?=#+\s+)'));
      int idx = 1;
      for (final part in parts) {
        if (part.trim().isNotEmpty) {
          final firstLine = part.trim().split('\n').first.replaceAll(RegExp(r'^#+\s*'), '');
          stages.add(
            LessonStage(
              stageNumber: idx++,
              title: firstLine,
              durationMinutes: (totalMins / parts.length).round().clamp(2, 15),
              content: part.trim(),
            ),
          );
        }
      }
    }

    return stages.isNotEmpty
        ? stages
        : [
            LessonStage(
              stageNumber: 1,
              title: 'Проведение занятия',
              durationMinutes: _parseTotalMinutes(totalDurationStr),
              content: content,
            ),
          ];
  }

  static int _parseTotalMinutes(String durationStr) {
    final match = RegExp(r'(\d+)').firstMatch(durationStr);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 20;
    }
    return 20;
  }
}
