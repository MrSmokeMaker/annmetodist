import 'printable_card.dart';
import 'thematic_world.dart';

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
  final List<String> generatedMaterials;
  final String? parentAudioScript;
  final String? promptVersionId;
  final String parentNotes;
  final String? illustrationMascot;
  final String? illustrationColoring;
  final String? illustrationReward;
  final String? thematicWorldId;
  final bool isDeepLesson;
  final double? rubricScore;
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
    this.generatedMaterials = const ['conspect'],
    this.parentAudioScript,
    this.promptVersionId,
    this.parentNotes = '',
    this.illustrationMascot,
    this.illustrationColoring,
    this.illustrationReward,
    this.thematicWorldId,
    this.isDeepLesson = false,
    this.rubricScore,
    required this.createdAt,
    this.updatedAt,
  });

  Conspect copyWith({
    String? id, String? title, String? methodId, String? methodName,
    String? subject, String? ageGroup, String? topic, String? duration,
    String? review, String? notes, String? content, List<String>? feedbackTags,
    int? variantIndex, String? batchGroupId, List<PrintableCard>? cards,
    List<String>? generatedMaterials, String? parentAudioScript,
    String? promptVersionId, String? parentNotes,
    String? illustrationMascot, String? illustrationColoring, String? illustrationReward,
    String? thematicWorldId,
    bool? isDeepLesson,
    double? rubricScore,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Conspect(
      id: id ?? this.id, title: title ?? this.title,
      methodId: methodId ?? this.methodId, methodName: methodName ?? this.methodName,
      subject: subject ?? this.subject, ageGroup: ageGroup ?? this.ageGroup,
      topic: topic ?? this.topic, duration: duration ?? this.duration,
      review: review ?? this.review, notes: notes ?? this.notes,
      content: content ?? this.content, feedbackTags: feedbackTags ?? this.feedbackTags,
      variantIndex: variantIndex ?? this.variantIndex, batchGroupId: batchGroupId ?? this.batchGroupId,
      cards: cards ?? this.cards, generatedMaterials: generatedMaterials ?? this.generatedMaterials,
      parentAudioScript: parentAudioScript ?? this.parentAudioScript,
      promptVersionId: promptVersionId ?? this.promptVersionId,
      parentNotes: parentNotes ?? this.parentNotes,
      illustrationMascot: illustrationMascot ?? this.illustrationMascot,
      illustrationColoring: illustrationColoring ?? this.illustrationColoring,
      illustrationReward: illustrationReward ?? this.illustrationReward,
      thematicWorldId: thematicWorldId ?? this.thematicWorldId,
      isDeepLesson: isDeepLesson ?? this.isDeepLesson,
      rubricScore: rubricScore ?? this.rubricScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ThematicWorld get thematicWorld {
    if (thematicWorldId != null && thematicWorldId!.isNotEmpty) {
      return ThematicWorld.fromId(thematicWorldId);
    }
    return ThematicWorld.fromTopic(
      topic: topic,
      subject: subject,
      ageGroup: ageGroup,
      methodId: methodId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'methodId': methodId, 'methodName': methodName,
    'subject': subject, 'ageGroup': ageGroup, 'topic': topic, 'duration': duration,
    'review': review, 'notes': notes, 'content': content, 'feedbackTags': feedbackTags,
    'variantIndex': variantIndex, 'batchGroupId': batchGroupId,
    'cards': cards?.map((c) => c.toJson()).toList(),
    'generatedMaterials': generatedMaterials, 'parentAudioScript': parentAudioScript,
    'promptVersionId': promptVersionId, 'parentNotes': parentNotes,
    if (illustrationMascot != null) 'illustrationMascot': illustrationMascot,
    if (illustrationColoring != null) 'illustrationColoring': illustrationColoring,
    if (illustrationReward != null) 'illustrationReward': illustrationReward,
    if (thematicWorldId != null) 'thematicWorldId': thematicWorldId,
    'isDeepLesson': isDeepLesson,
    if (rubricScore != null) 'rubricScore': rubricScore,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Conspect.fromMap(Map<dynamic, dynamic> map) => Conspect(
    id: map['id'] as String? ?? '', title: map['title'] as String? ?? '',
    methodId: map['methodId'] as String? ?? '', methodName: map['methodName'] as String? ?? '',
    subject: map['subject'] as String? ?? '', ageGroup: map['ageGroup'] as String? ?? '',
    topic: map['topic'] as String? ?? '', duration: map['duration'] as String? ?? '',
    review: map['review'] as String? ?? '', notes: map['notes'] as String? ?? '',
    content: map['content'] as String? ?? '',
    feedbackTags: (map['feedbackTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    variantIndex: (map['variantIndex'] as num?)?.toInt() ?? 1,
    batchGroupId: map['batchGroupId'] as String?, cards: _readCards(map['cards']),
    generatedMaterials: (map['generatedMaterials'] as List<dynamic>?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? const ['conspect'],
    parentAudioScript: map['parentAudioScript'] as String?, promptVersionId: map['promptVersionId'] as String?,
    parentNotes: map['parentNotes'] as String? ?? '',
    illustrationMascot: map['illustrationMascot'] as String?,
    illustrationColoring: map['illustrationColoring'] as String?,
    illustrationReward: map['illustrationReward'] as String?,
    thematicWorldId: map['thematicWorldId'] as String?,
    isDeepLesson: map['isDeepLesson'] as bool? ?? false,
    rubricScore: (map['rubricScore'] as num?)?.toDouble(),
    createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
  );

  static List<PrintableCard>? _readCards(dynamic rawCards) {
    if (rawCards is! List) return null;
    final cards = <PrintableCard>[];
    for (final item in rawCards) {
      if (item is! Map) continue;
      try {
        final card = PrintableCard.fromJson(Map<String, dynamic>.from(item));
        if (card.frontText.isNotEmpty || card.backText.isNotEmpty) cards.add(card);
      } catch (_) {}
    }
    return cards.isEmpty ? null : cards;
  }

  Map<String, dynamic> toJson() => toMap();
  factory Conspect.fromJson(Map<String, dynamic> json) => Conspect.fromMap(json);
}
