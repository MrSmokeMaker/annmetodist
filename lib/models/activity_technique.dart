/// Модель шага практического приёма/задания
class ActivityStep {
  final int order;
  final String title;
  final String description;
  final List<String> media;

  const ActivityStep({
    required this.order,
    required this.title,
    required this.description,
    this.media = const [],
  });

  factory ActivityStep.fromJson(Map<String, dynamic> json) {
    return ActivityStep(
      order: json['order'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'description': description,
      if (media.isNotEmpty) 'media': media,
    };
  }
}

/// Модель критериев оценки выполнения приёма
class ActivityAssessment {
  final String type;
  final List<String> criteria;

  const ActivityAssessment({
    required this.type,
    required this.criteria,
  });

  factory ActivityAssessment.fromJson(Map<String, dynamic> json) {
    return ActivityAssessment(
      type: json['type'] as String? ?? 'observation',
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'criteria': criteria,
    };
  }
}

/// Обогащенная модель педагогического приёма и практического задания
class ActivityTechnique {
  final String id;
  final String category;
  final String title;
  final String shortDescription;
  final String sampleText;
  final int? durationMinutes;
  final String? difficulty; // 'easy' | 'medium' | 'hard'
  final List<String> learningObjectives;
  final List<String> materials;
  final List<ActivityStep> steps;
  final ActivityAssessment? assessment;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? localizations;

  const ActivityTechnique({
    required this.id,
    required this.category,
    required this.title,
    required this.shortDescription,
    required this.sampleText,
    this.durationMinutes,
    this.difficulty,
    this.learningObjectives = const [],
    this.materials = const [],
    this.steps = const [],
    this.assessment,
    this.tags = const [],
    this.metadata,
    this.localizations,
  });

  /// Возвращает готовый для промпта текст приёма: либо готовый sampleText,
  /// либо динамически собираемый из шагов.
  String get effectiveSampleText {
    if (sampleText.trim().isNotEmpty) {
      return sampleText;
    }
    if (steps.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln("Приём '$title':");
      for (final step in steps) {
        buffer.writeln("- ${step.title}: ${step.description}");
      }
      return buffer.toString().trim();
    }
    return "$title: $shortDescription";
  }

  factory ActivityTechnique.fromJson(Map<String, dynamic> json) {
    // Парсинг шагов
    final rawSteps = json['steps'] as List<dynamic>?;
    final parsedSteps = rawSteps != null
        ? rawSteps
            .map((item) => ActivityStep.fromJson(item as Map<String, dynamic>))
            .toList()
        : <ActivityStep>[];

    // Парсинг оценки
    ActivityAssessment? parsedAssessment;
    if (json['assessment'] != null && json['assessment'] is Map<String, dynamic>) {
      parsedAssessment =
          ActivityAssessment.fromJson(json['assessment'] as Map<String, dynamic>);
    }

    return ActivityTechnique(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      sampleText: json['sample_text'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int?,
      difficulty: json['difficulty'] as String?,
      learningObjectives: (json['learning_objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      steps: parsedSteps,
      assessment: parsedAssessment,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      localizations: json['localizations'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'short_description': shortDescription,
      'sample_text': sampleText,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (learningObjectives.isNotEmpty)
        'learning_objectives': learningObjectives,
      if (materials.isNotEmpty) 'materials': materials,
      if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
      if (assessment != null) 'assessment': assessment!.toJson(),
      if (tags.isNotEmpty) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
      if (localizations != null) 'localizations': localizations,
    };
  }

  ActivityTechnique copyWith({
    String? id,
    String? category,
    String? title,
    String? shortDescription,
    String? sampleText,
    int? durationMinutes,
    String? difficulty,
    List<String>? learningObjectives,
    List<String>? materials,
    List<ActivityStep>? steps,
    ActivityAssessment? assessment,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? localizations,
  }) {
    return ActivityTechnique(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      sampleText: sampleText ?? this.sampleText,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      materials: materials ?? this.materials,
      steps: steps ?? this.steps,
      assessment: assessment ?? this.assessment,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      localizations: localizations ?? this.localizations,
    );
  }
}
