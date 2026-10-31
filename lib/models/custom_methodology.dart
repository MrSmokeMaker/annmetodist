import 'dart:convert';

enum PedagogicalTone {
  academic('Академический классический', 'Строгий тон советской педагогики, точность определений'),
  triz('Игровой ТРИЗ и логические ловушки', 'Проблемные парадоксы, изобретательские задачи, познавательный азарт'),
  fairytale('Сказкотерапия и метафоры', 'Обучение через сюжетные сказочные образы, мягкая психологическая поддержка'),
  socratic('Сократический диалог', 'Обучение через систему наводящих эвристических вопросов'),
  inquiry('Исследовательский проектный подход', 'Упор на выдвижение гипотез, мини-эксперименты');

  final String label;
  final String description;
  const PedagogicalTone(this.label, this.description);

  // Aliases for compatibility
  static PedagogicalTone get trizGaming => PedagogicalTone.triz;
  static PedagogicalTone get fairyTaleTherapy => PedagogicalTone.fairytale;
  static PedagogicalTone get socraticDialogue => PedagogicalTone.socratic;
  static PedagogicalTone get projectInquiry => PedagogicalTone.inquiry;
}

/// Конструктор авторской методики (Тариф Директор)
class CustomMethodology {
  final String id;
  final String name;
  final String authorName;
  final String description;
  final PedagogicalTone tone;
  final List<String> stopWords;
  final List<String> forbiddenThemes;
  final List<String> structureBlocks;
  final String customSystemPrompt;
  final bool strictPchelkoMultiplierCheck;
  final bool requireReflectiveQuestions;
  final bool enforceFgosComplianceReport;
  final DateTime createdAt;

  CustomMethodology({
    required this.id,
    String? name,
    String? title,
    String? authorName,
    String? creatorName,
    this.description = '',
    this.tone = PedagogicalTone.academic,
    this.stopWords = const [],
    this.forbiddenThemes = const [],
    List<String>? structureBlocks,
    List<String>? customStages,
    String systemPromptTemplate = '',
    String customSystemPrompt = '',
    String customSystemPromptOverride = '',
    this.strictPchelkoMultiplierCheck = true,
    this.requireReflectiveQuestions = true,
    this.enforceFgosComplianceReport = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : name = name ?? title ?? 'Новая авторская методика',
        authorName = authorName ?? creatorName ?? 'Учитель-методист',
        structureBlocks = structureBlocks ??
            customStages ??
            const [
              '1. Мотивационный парадокс (ТРИЗ-загадка)',
              '2. Выдвижение гипотез учениками',
              '3. Академическое обоснование и вывод правила',
              '4. Практикум на листе заданий с игровым сюжетом',
              '5. Рефлексия открытий и самооценка',
            ],
        customSystemPrompt = systemPromptTemplate.isNotEmpty
            ? systemPromptTemplate
            : (customSystemPromptOverride.isNotEmpty ? customSystemPromptOverride : customSystemPrompt),
        createdAt = createdAt ?? updatedAt ?? DateTime.now();

  // Getters for compatibility
  String get title => name;
  List<String> get customStages => structureBlocks;
  String get customSystemPromptOverride => customSystemPrompt;
  DateTime get updatedAt => createdAt;

  String get toneLabel => tone.label;

  String buildSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('Ты — ведущий методист-архитектор по авторской методике «$name» ($authorName).');
    buffer.writeln('Педагогический стиль и тон: $toneLabel.');
    if (stopWords.isNotEmpty) {
      buffer.writeln('Категорические стоп-слова: ${stopWords.join(', ')}.');
    }
    buffer.writeln('Обязательные структурные блоки занятия:');
    for (final block in structureBlocks) {
      buffer.writeln('- $block');
    }
    if (customSystemPrompt.isNotEmpty) {
      buffer.writeln('Дополнительные авторские инструкции: $customSystemPrompt');
    }
    return buffer.toString();
  }

  static CustomMethodology defaultLyceumMethodology() {
    return CustomMethodology(
      id: 'method_lyceum_1',
      name: 'Методика Лицейского исследовательского поиска',
      authorName: 'Кафедра математики и словесности Лицея №1',
      tone: PedagogicalTone.triz,
      stopWords: [
        'просто запомни',
        'не задавай вопросов',
        'это слишком сложно для вас',
        'шаблонное решение',
      ],
      forbiddenThemes: [
        'Поверхностное заучивание без вывода формул',
        'Нарушение порядка множителей в задачах на умножение',
        'Задания без наглядной практической привязки',
      ],
      structureBlocks: [
        '1. Мотивационный парадокс (ТРИЗ-загадка)',
        '2. Выдвижение гипотез учениками',
        '3. Академическое обоснование и вывод правила',
        '4. Практикум на листе заданий с игровым сюжетом',
        '5. Рефлексия открытий и самооценка',
      ],
      strictPchelkoMultiplierCheck: true,
      requireReflectiveQuestions: true,
      enforceFgosComplianceReport: true,
      customSystemPrompt:
          'Ты — элитный методист лицея. Формируй конспекты с глубоким проблемно-поисковым погружением.',
    );
  }

  CustomMethodology copyWith({
    String? id,
    String? name,
    String? title,
    String? authorName,
    String? description,
    PedagogicalTone? tone,
    List<String>? stopWords,
    List<String>? forbiddenThemes,
    List<String>? structureBlocks,
    List<String>? customStages,
    String? customSystemPrompt,
    String? customSystemPromptOverride,
    bool? strictPchelkoMultiplierCheck,
    bool? requireReflectiveQuestions,
    bool? enforceFgosComplianceReport,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomMethodology(
      id: id ?? this.id,
      name: name ?? title ?? this.name,
      authorName: authorName ?? this.authorName,
      description: description ?? this.description,
      tone: tone ?? this.tone,
      stopWords: stopWords ?? this.stopWords,
      forbiddenThemes: forbiddenThemes ?? this.forbiddenThemes,
      structureBlocks: structureBlocks ?? customStages ?? this.structureBlocks,
      customSystemPrompt: customSystemPrompt ?? customSystemPromptOverride ?? this.customSystemPrompt,
      strictPchelkoMultiplierCheck: strictPchelkoMultiplierCheck ?? this.strictPchelkoMultiplierCheck,
      requireReflectiveQuestions: requireReflectiveQuestions ?? this.requireReflectiveQuestions,
      enforceFgosComplianceReport: enforceFgosComplianceReport ?? this.enforceFgosComplianceReport,
      createdAt: createdAt ?? updatedAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'authorName': authorName,
      'description': description,
      'tone': tone.name,
      'stopWords': stopWords,
      'forbiddenThemes': forbiddenThemes,
      'structureBlocks': structureBlocks,
      'customSystemPrompt': customSystemPrompt,
      'strictPchelkoMultiplierCheck': strictPchelkoMultiplierCheck,
      'requireReflectiveQuestions': requireReflectiveQuestions,
      'enforceFgosComplianceReport': enforceFgosComplianceReport,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomMethodology.fromMap(Map<String, dynamic> map) {
    PedagogicalTone parsedTone = PedagogicalTone.academic;
    final toneStr = map['tone'] as String?;
    if (toneStr != null) {
      for (final t in PedagogicalTone.values) {
        if (t.name == toneStr) parsedTone = t;
      }
    }
    return CustomMethodology(
      id: map['id'] as String? ?? 'custom_method_default',
      name: map['name'] as String? ?? map['title'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Учитель',
      description: map['description'] as String? ?? '',
      tone: parsedTone,
      stopWords: (map['stopWords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      forbiddenThemes: (map['forbiddenThemes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      structureBlocks: (map['structureBlocks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (map['customStages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      customSystemPrompt: map['customSystemPrompt'] as String? ?? map['customSystemPromptOverride'] as String? ?? '',
      strictPchelkoMultiplierCheck: map['strictPchelkoMultiplierCheck'] as bool? ?? true,
      requireReflectiveQuestions: map['requireReflectiveQuestions'] as bool? ?? true,
      enforceFgosComplianceReport: map['enforceFgosComplianceReport'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CustomMethodology.fromJson(String source) =>
      CustomMethodology.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
