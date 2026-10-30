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
  final String? yandexArtPrompt;
  final String? artImageUrl;

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
    this.yandexArtPrompt,
    this.artImageUrl,
  });

  /// Средний балл по трем критериям (макс 10.0)
  double get overallScore => (logicScore + orthographyScore + visualScore) / 3.0;

  /// Статус качества задания
  bool get isFlawless => logicScore >= 9 && orthographyScore >= 9 && visualScore >= 9;

  /// Строка оценки YandexGPT для отладки
  String get formattedEvaluationLine {
    final artBadge = yandexArtPrompt != null ? ' | 🎨 YandexART: "$yandexArtPrompt"' : '';
    final tableBadge = hasTable ? (hasWordBank ? ' | 📊 Таблица с банком слов' : ' | 📊 Таблица') : '';
    final sampleBadge = hasSample ? ' | 📝 Образец есть' : '';
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
    'yandexArtPrompt': yandexArtPrompt,
    'artImageUrl': artImageUrl,
    'overallScore': overallScore,
  };
}
