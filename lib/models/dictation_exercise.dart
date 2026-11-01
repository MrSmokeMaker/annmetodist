/// Единица слухового диктанта (слово, слог или пример)
class DictationItem {
  final int index;
  final String spokenText;
  final String cleanWord;
  final String ruleHint;
  final int pauseSeconds;

  const DictationItem({
    required this.index,
    required this.spokenText,
    required this.cleanWord,
    required this.ruleHint,
    this.pauseSeconds = 5,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'spoken_text': spokenText,
        'clean_word': cleanWord,
        'rule_hint': ruleHint,
        'pause_seconds': pauseSeconds,
      };

  factory DictationItem.fromJson(Map<String, dynamic> json) => DictationItem(
        index: json['index'] as int? ?? 1,
        spokenText: json['spoken_text'] as String? ?? '',
        cleanWord: json['clean_word'] as String? ?? '',
        ruleHint: json['rule_hint'] as String? ?? '',
        pauseSeconds: json['pause_seconds'] as int? ?? 5,
      );
}

/// Упражнение «Интерактивный аудио-диктант»
class DictationExercise {
  final String title;
  final String subject;
  final String ageGroup;
  final List<DictationItem> items;
  final String introScript;
  final String conclusionScript;

  const DictationExercise({
    required this.title,
    required this.subject,
    required this.ageGroup,
    required this.items,
    this.introScript = 'Здравствуйте, ребята! Приготовьте тетрадь и ручку. Сначала послушайте весь диктант целиком.',
    this.conclusionScript = 'Диктант окончен! Возьмите зелёный карандаш и проверьте свою запись по образцу.',
  });

  String get fullTextForPreview => items.map((e) => '${e.index}. ${e.cleanWord}').join(', ');
}
