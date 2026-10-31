import 'lesson_summary_card.dart';

class ScheduledLesson {
  final String id;
  final DateTime date;
  final String time; // e.g. "10:30"
  final String studentOrClass; // e.g. "Миша (1 класс)" or "3-Б класс"
  final String topic; // e.g. "Сложение с переходом через десяток"
  final String? conspectId; // reference to generated Conspect
  final bool hasConspect;
  final bool hasWorksheet;
  final bool hasHomework;
  final String? notes;
  final LessonSummaryCard? summaryCard;
  final DateTime createdAt;

  ScheduledLesson({
    required this.id,
    required this.date,
    required this.time,
    required this.studentOrClass,
    required this.topic,
    this.conspectId,
    this.hasConspect = true,
    this.hasWorksheet = true,
    this.hasHomework = true,
    this.notes,
    this.summaryCard,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasSummaryCard => summaryCard != null;

  /// Является ли занятие прошедшим или сегодняшним (готовым к подведению итогов)
  bool get isPastOrToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lessonDay = DateTime(date.year, date.month, date.day);
    return !lessonDay.isAfter(today);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'time': time,
      'studentOrClass': studentOrClass,
      'topic': topic,
      'conspectId': conspectId,
      'hasConspect': hasConspect,
      'hasWorksheet': hasWorksheet,
      'hasHomework': hasHomework,
      'notes': notes,
      'summaryCard': summaryCard?.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduledLesson.fromMap(Map<String, dynamic> map) {
    return ScheduledLesson(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      time: map['time']?.toString() ?? '10:00',
      studentOrClass: map['studentOrClass']?.toString() ?? 'Ученик',
      topic: map['topic']?.toString() ?? 'Без темы',
      conspectId: map['conspectId']?.toString(),
      hasConspect: map['hasConspect'] == true || map['hasConspect'] == 1,
      hasWorksheet: map['hasWorksheet'] == true || map['hasWorksheet'] == 1,
      hasHomework: map['hasHomework'] == true || map['hasHomework'] == 1,
      notes: map['notes']?.toString(),
      summaryCard: map['summaryCard'] != null
          ? LessonSummaryCard.fromMap(Map<String, dynamic>.from(map['summaryCard']))
          : null,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  ScheduledLesson copyWith({
    String? id,
    DateTime? date,
    String? time,
    String? studentOrClass,
    String? topic,
    String? conspectId,
    bool? hasConspect,
    bool? hasWorksheet,
    bool? hasHomework,
    String? notes,
    LessonSummaryCard? summaryCard,
    bool clearSummaryCard = false,
    DateTime? createdAt,
  }) {
    return ScheduledLesson(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      studentOrClass: studentOrClass ?? this.studentOrClass,
      topic: topic ?? this.topic,
      conspectId: conspectId ?? this.conspectId,
      hasConspect: hasConspect ?? this.hasConspect,
      hasWorksheet: hasWorksheet ?? this.hasWorksheet,
      hasHomework: hasHomework ?? this.hasHomework,
      notes: notes ?? this.notes,
      summaryCard: clearSummaryCard ? null : (summaryCard ?? this.summaryCard),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
