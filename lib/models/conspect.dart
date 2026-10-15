import 'printable_card.dart';

class Conspect {
  final String id;
  final String title;
  final String methodId;
  final String methodName;
  final String subject;
  final String ageGroup;
  final String topic;
  final String duration;
  final String review;
  final String notes;
  final String content;
  final List<String> feedbackTags;
  final int variantIndex;
  final String? batchGroupId;
  final List<PrintableCard>? cards;
  final String? parentAudioScript;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conspect({
    required this.id,
    required this.title,
    required this.methodId,
    required this.methodName,
    required this.subject,
    required this.ageGroup,
    required this.topic,
    required this.duration,
    this.review = '',
    this.notes = '',
    required this.content,
    this.feedbackTags = const [],
    this.variantIndex = 1,
    this.batchGroupId,
    this.cards,
    this.parentAudioScript,
    required this.createdAt,
    this.updatedAt,
  });

  Conspect copyWith({
    String? id,
    String? title,
    String? methodId,
    String? methodName,
    String? subject,
    String? ageGroup,
    String? topic,
    String? duration,
    String? review,
    String? notes,
    String? content,
    List<String>? feedbackTags,
    int? variantIndex,
    String? batchGroupId,
    List<PrintableCard>? cards,
    String? parentAudioScript,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conspect(
      id: id ?? this.id,
      title: title ?? this.title,
      methodId: methodId ?? this.methodId,
      methodName: methodName ?? this.methodName,
      subject: subject ?? this.subject,
      ageGroup: ageGroup ?? this.ageGroup,
      topic: topic ?? this.topic,
      duration: duration ?? this.duration,
      review: review ?? this.review,
      notes: notes ?? this.notes,
      content: content ?? this.content,
      feedbackTags: feedbackTags ?? this.feedbackTags,
      variantIndex: variantIndex ?? this.variantIndex,
      batchGroupId: batchGroupId ?? this.batchGroupId,
      cards: cards ?? this.cards,
      parentAudioScript: parentAudioScript ?? this.parentAudioScript,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'methodId': methodId,
      'methodName': methodName,
      'subject': subject,
      'ageGroup': ageGroup,
      'topic': topic,
      'duration': duration,
      'review': review,
      'notes': notes,
      'content': content,
      'feedbackTags': feedbackTags,
      'variantIndex': variantIndex,
      'batchGroupId': batchGroupId,
      'cards': cards?.map((c) => c.toJson()).toList(),
      'parentAudioScript': parentAudioScript,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Conspect.fromMap(Map<dynamic, dynamic> map) {
    return Conspect(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      methodId: map['methodId'] as String? ?? '',
      methodName: map['methodName'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      ageGroup: map['ageGroup'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      review: map['review'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      content: map['content'] as String? ?? '',
      feedbackTags: (map['feedbackTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      variantIndex: (map['variantIndex'] as num?)?.toInt() ?? 1,
      batchGroupId: map['batchGroupId'] as String?,
      cards: (map['cards'] as List<dynamic>?)
          ?.map((c) => PrintableCard.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
      parentAudioScript: map['parentAudioScript'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Conspect.fromJson(Map<String, dynamic> json) => Conspect.fromMap(json);
}
