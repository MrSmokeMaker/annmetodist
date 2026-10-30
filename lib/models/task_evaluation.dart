/// Модель детальной методической оценки отдельного задания в листе заданий
class TaskEvaluation {
  final int taskIndex;
  final String taskTitle;
  final int logicScore; // 1-10: логическая непротиворечивость и соответствие возрасту
  final String logicNotes;
  final int orthographyScore; // 1-10: грамматическая чистота и академический стиль
  final String orthographyNotes;
  final int visualScore; // 1-10: визуальная полнота (образец, таблица, банк слов, разлиновка)
  final String visualNotes;
  final bool hasSample;
  final bool hasTable;
  final bool hasWordBank;
  final bool requiresArt; // Требуется ли YandexART для визуализации задания (целевой диапазон 10-15% заданий)
  final String? artType; // Тип арта: счет предметов, контурная раскраска, фонетическая опора, сюжетная иллюстрация, чертеж
  final String? yandexArtPrompt;
  final String? artImageUrl;
  final bool isArtLogicallyAligned; // Согласованы ли условие задания и сюжет иллюстрации YandexART
  final String? artAlignmentNotes;

  const TaskEvaluation({
    required this.taskIndex,
    required this.taskTitle,
    required this.logicScore,
    required this.logicNotes,
    required this.orthographyScore,
    required this.orthographyNotes,
    required this.visualScore,
    required this.visualNotes,
    this.hasSample = false,
    this.hasTable = false,
    this.hasWordBank = false,
    this.requiresArt = false,
    this.artType,
    this.yandexArtPrompt,
    this.artImageUrl,
    this.isArtLogicallyAligned = true,
    this.artAlignmentNotes,
  });

  /// Средний балл по трем критериям (макс 10.0)
  double get overallScore => (logicScore + orthographyScore + visualScore) / 3.0;

  /// Статус качества задания
  bool get isFlawless => logicScore >= 9 && orthographyScore >= 9 && visualScore >= 9 && (!requiresArt || isArtLogicallyAligned);

  /// Строка оценки YandexGPT для отладки
  String get formattedEvaluationLine {
    final sampleBadge = hasSample ? ' | 📝 Образец есть' : '';
    final tableBadge = hasTable ? (hasWordBank ? ' | 📊 Таблица с банком слов' : ' | 📊 Таблица') : '';
    final String artBadge;
    if (requiresArt && yandexArtPrompt != null) {
      final alignStr = isArtLogicallyAligned ? 'согласован 10/10' : 'требует уточнения';
      artBadge = ' | 🎨 YandexART [ДА, роль: $artType]: "$yandexArtPrompt" ($alignStr)';
    } else {
      artBadge = ' | 🎨 YandexART: [Не требуется: вербально-аналитическое упражнение]';
    }
    return '🔬 Оценка YandexGPT: Логика $logicScore/10 | Орфография $orthographyScore/10 | Визуал $visualScore/10$sampleBadge$tableBadge$artBadge';
  }

  Map<String, dynamic> toMap() => {
    'taskIndex': taskIndex,
    'taskTitle': taskTitle,
    'logicScore': logicScore,
    'logicNotes': logicNotes,
    'orthographyScore': orthographyScore,
    'orthographyNotes': orthographyNotes,
    'visualScore': visualScore,
    'visualNotes': visualNotes,
    'hasSample': hasSample,
    'hasTable': hasTable,
    'hasWordBank': hasWordBank,
    'requiresArt': requiresArt,
    'artType': artType,
    'yandexArtPrompt': yandexArtPrompt,
    'artImageUrl': artImageUrl,
    'isArtLogicallyAligned': isArtLogicallyAligned,
    'artAlignmentNotes': artAlignmentNotes,
    'overallScore': overallScore,
  };
}
