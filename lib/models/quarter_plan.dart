import 'dart:convert';

enum QuarterTopicStatus {
  pending,
  generating,
  completed,
  failed,
}

class QuarterTopicItem {
  final String id;
  final int lessonIndex;
  final String title;
  final String description;
  final QuarterTopicStatus status;
  final String? conspectId;
  final DateTime? scheduledDate;
  final String? errorMessage;

  const QuarterTopicItem({
    required this.id,
    required this.lessonIndex,
    required this.title,
    this.description = '',
    this.status = QuarterTopicStatus.pending,
    this.conspectId,
    this.scheduledDate,
    this.errorMessage,
  });

  QuarterTopicItem copyWith({
    String? id,
    int? lessonIndex,
    String? title,
    String? description,
    QuarterTopicStatus? status,
    String? conspectId,
    DateTime? scheduledDate,
    String? errorMessage,
  }) {
    return QuarterTopicItem(
      id: id ?? this.id,
      lessonIndex: lessonIndex ?? this.lessonIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      conspectId: conspectId ?? this.conspectId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonIndex': lessonIndex,
      'title': title,
      'description': description,
      'status': status.name,
      'conspectId': conspectId,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory QuarterTopicItem.fromMap(Map<String, dynamic> map) {
    return QuarterTopicItem(
      id: map['id']?.toString() ?? '',
      lessonIndex: (map['lessonIndex'] as num?)?.toInt() ?? 1,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: QuarterTopicStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuarterTopicStatus.pending,
      ),
      conspectId: map['conspectId']?.toString(),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.tryParse(map['scheduledDate'].toString())
          : null,
      errorMessage: map['errorMessage']?.toString(),
    );
  }
}

class QuarterPlan {
  final String id;
  final String subject;
  final String methodId;
  final String methodName;
  final String ageGroup;
  final int quarterNumber; // 1, 2, 3, 4
  final List<QuarterTopicItem> topics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCalendarScheduled;

  const QuarterPlan({
    required this.id,
    required this.subject,
    required this.methodId,
    required this.methodName,
    required this.ageGroup,
    required this.quarterNumber,
    required this.topics,
    required this.createdAt,
    required this.updatedAt,
    this.isCalendarScheduled = false,
  });

  QuarterPlan copyWith({
    String? id,
    String? subject,
    String? methodId,
    String? methodName,
    String? ageGroup,
    int? quarterNumber,
    List<QuarterTopicItem>? topics,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCalendarScheduled,
  }) {
    return QuarterPlan(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      methodId: methodId ?? this.methodId,
      methodName: methodName ?? this.methodName,
      ageGroup: ageGroup ?? this.ageGroup,
      quarterNumber: quarterNumber ?? this.quarterNumber,
      topics: topics ?? this.topics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCalendarScheduled: isCalendarScheduled ?? this.isCalendarScheduled,
    );
  }

  int get totalLessons => topics.length;
  int get completedLessons =>
      topics.where((t) => t.status == QuarterTopicStatus.completed).length;
  double get progress =>
      totalLessons == 0 ? 0.0 : completedLessons / totalLessons;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'methodId': methodId,
      'methodName': methodName,
      'ageGroup': ageGroup,
      'quarterNumber': quarterNumber,
      'topics': topics.map((t) => t.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCalendarScheduled': isCalendarScheduled,
    };
  }

  factory QuarterPlan.fromMap(Map<String, dynamic> map) {
    return QuarterPlan(
      id: map['id']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      methodId: map['methodId']?.toString() ?? '',
      methodName: map['methodName']?.toString() ?? '',
      ageGroup: map['ageGroup']?.toString() ?? '',
      quarterNumber: (map['quarterNumber'] as num?)?.toInt() ?? 1,
      topics: (map['topics'] as List<dynamic>?)
              ?.map((item) =>
                  QuarterTopicItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isCalendarScheduled: map['isCalendarScheduled'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory QuarterPlan.fromJson(String source) =>
      QuarterPlan.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
