import 'package:uuid/uuid.dart';

/// Карточка итога прошедшего урока (эксклюзивно для тарифа Metodist Pro и выше)
class LessonSummaryCard {
  final String id;
  final String scheduledLessonId;
  final DateTime date;
  final String topic;
  final String studentOrClass;
  final String? conspectId;
  final String thematicWorldId;

  /// Оценки по критериям (от 1 до 5)
  final Map<String, int> criteriaScores;

  /// Пометки и теги учителя
  final List<String> tags;

  /// Личные заметки учителя по итогу урока
  final String teacherNotes;

  /// Назначенное домашнее задание (уровень 1, 2 или 3)
  final String homeworkAssigned;

  /// Педагогическая AI-рефлексия и рекомендации (YandexGPT Pro)
  final String? aiReflection;

  /// Готовое сообщение для родительского чата
  final String? parentChatMessage;

  final DateTime createdAt;
  final DateTime? updatedAt;

  LessonSummaryCard({
    String? id,
    required this.scheduledLessonId,
    required this.date,
    required this.topic,
    required this.studentOrClass,
    this.conspectId,
    this.thematicWorldId = 'world_space',
    Map<String, int>? criteriaScores,
    List<String>? tags,
    this.teacherNotes = '',
    this.homeworkAssigned = 'Уровень 1 (Базовый, ФГОС)',
    this.aiReflection,
    this.parentChatMessage,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        criteriaScores = criteriaScores ?? Map.from(defaultCriteria),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Предустановленные базовые академические критерии (1–5)
  static const Map<String, int> defaultCriteria = {
    'Усвоение нового правила / алгоритма': 5,
    'Самостоятельность выполнения заданий': 4,
    'Активность и вовлеченность на уроке': 5,
    'Дисциплина и тайминг этапов (СанПиН)': 5,
    'Логика и решение ТРИЗ-задач / ловушек': 4,
  };

  /// Предустановленный банк пометок и наблюдений
  static const List<String> defaultTagsPreset = [
    '⭐ Блестящий ответ у доски',
    '💡 Отличное ТРИЗ-решение',
    '⏱️ Справились с опережением тайминга',
    '⚠️ Трудности с каллиграфией',
    '🔄 Повторить на следующем уроке',
    '🏠 Рекомендовано ДЗ уровня 3 (ТРИЗ)',
    '👏 Активная работа в паре',
    '🎯 Полное понимание алгоритма',
    '🌿 Двигательная разминка на ура',
    '🪤 Поймали Незнайку на ошибке',
  ];

  /// Средний балл по критериям (от 1.0 до 5.0)
  double get averageScore {
    if (criteriaScores.isEmpty) return 5.0;
    final total = criteriaScores.values.fold<int>(0, (sum, val) => sum + val);
    return total / criteriaScores.length;
  }

  /// Процент успешности усвоения (0% – 100%)
  int get masteryPercent {
    return ((averageScore / 5.0) * 100).round().clamp(0, 100);
  }

  /// Академический вердикт по стандартам ФГОС
  String get academicStatus {
    final p = masteryPercent;
    if (p >= 90) return 'Высокий уровень усвоения (ФГОС: Отлично)';
    if (p >= 75) return 'Уверенный базовый уровень (ФГОС: Хорошо)';
    if (p >= 60) return 'Базовый уровень освоен (ФГОС: Удовл.)';
    return 'Требуется коррекционное повторение';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduledLessonId': scheduledLessonId,
      'date': date.toIso8601String(),
      'topic': topic,
      'studentOrClass': studentOrClass,
      'conspectId': conspectId,
      'thematicWorldId': thematicWorldId,
      'criteriaScores': criteriaScores,
      'tags': tags,
      'teacherNotes': teacherNotes,
      'homeworkAssigned': homeworkAssigned,
      'aiReflection': aiReflection,
      'parentChatMessage': parentChatMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LessonSummaryCard.fromMap(Map<String, dynamic> map) {
    Map<String, int> scores = {};
    if (map['criteriaScores'] is Map) {
      (map['criteriaScores'] as Map).forEach((k, v) {
        scores[k.toString()] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 5;
      });
    } else {
      scores = Map.from(defaultCriteria);
    }

    List<String> parsedTags = [];
    if (map['tags'] is List) {
      parsedTags = (map['tags'] as List).map((t) => t.toString()).toList();
    }

    return LessonSummaryCard(
      id: map['id']?.toString() ?? const Uuid().v4(),
      scheduledLessonId: map['scheduledLessonId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      topic: map['topic']?.toString() ?? '',
      studentOrClass: map['studentOrClass']?.toString() ?? '',
      conspectId: map['conspectId']?.toString(),
      thematicWorldId: map['thematicWorldId']?.toString() ?? 'world_space',
      criteriaScores: scores,
      tags: parsedTags,
      teacherNotes: map['teacherNotes']?.toString() ?? '',
      homeworkAssigned: map['homeworkAssigned']?.toString() ?? 'Уровень 1 (Базовый, ФГОС)',
      aiReflection: map['aiReflection']?.toString(),
      parentChatMessage: map['parentChatMessage']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }

  LessonSummaryCard copyWith({
    String? id,
    String? scheduledLessonId,
    DateTime? date,
    String? topic,
    String? studentOrClass,
    String? conspectId,
    String? thematicWorldId,
    Map<String, int>? criteriaScores,
    List<String>? tags,
    String? teacherNotes,
    String? homeworkAssigned,
    String? aiReflection,
    String? parentChatMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonSummaryCard(
      id: id ?? this.id,
      scheduledLessonId: scheduledLessonId ?? this.scheduledLessonId,
      date: date ?? this.date,
      topic: topic ?? this.topic,
      studentOrClass: studentOrClass ?? this.studentOrClass,
      conspectId: conspectId ?? this.conspectId,
      thematicWorldId: thematicWorldId ?? this.thematicWorldId,
      criteriaScores: criteriaScores != null ? Map.from(criteriaScores) : Map.from(this.criteriaScores),
      tags: tags != null ? List.from(tags) : List.from(this.tags),
      teacherNotes: teacherNotes ?? this.teacherNotes,
      homeworkAssigned: homeworkAssigned ?? this.homeworkAssigned,
      aiReflection: aiReflection ?? this.aiReflection,
      parentChatMessage: parentChatMessage ?? this.parentChatMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
