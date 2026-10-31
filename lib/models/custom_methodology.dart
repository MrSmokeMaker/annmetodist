import 'dart:convert';

enum PedagogicalTone {
  academic,
  triz,
  fairytale,
  socratic,
  inquiry,
}

class CustomMethodology {
  final String id;
  final String name;
  final String authorName;
  final String description;
  final PedagogicalTone tone;
  final List<String> stopWords;
  final List<String> structureBlocks;
  final String customSystemPrompt;
  final DateTime createdAt;

  CustomMethodology({
    required this.id,
    required this.name,
    String? authorName,
    String? creatorName,
    this.description = '',
    this.tone = PedagogicalTone.academic,
    this.stopWords = const [],
    this.structureBlocks = const [
      'Цель и задачи занятия',
      'Разминка и актуализация',
      'Теоретическое погружение',
      'Физкультминутка',
      'Лист заданий (3 уровня)',
      'Рефлексия и самооценка',
      'Домашнее задание',
    ],
    String systemPromptTemplate = '',
    String customSystemPrompt = '',
    DateTime? createdAt,
  })  : authorName = authorName ?? creatorName ?? 'Учитель',
        customSystemPrompt = systemPromptTemplate.isNotEmpty ? systemPromptTemplate : customSystemPrompt,
        createdAt = createdAt ?? DateTime.now();

  String get toneLabel {
    switch (tone) {
      case PedagogicalTone.triz:
        return 'Игровой ТРИЗ и логические ловушки';
      case PedagogicalTone.fairytale:
        return 'Сказкотерапия и сюжетные метафоры';
      case PedagogicalTone.socratic:
        return 'Сократический диалог и проблемные вопросы';
      case PedagogicalTone.inquiry:
        return 'Исследовательский проектный подход';
      case PedagogicalTone.academic:
      default:
        return 'Академический классический (ФГОС)';
    }
  }

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'authorName': authorName,
      'description': description,
      'tone': tone.name,
      'stopWords': stopWords,
      'structureBlocks': structureBlocks,
      'customSystemPrompt': customSystemPrompt,
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
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Учитель',
      description: map['description'] as String? ?? '',
      tone: parsedTone,
      stopWords: (map['stopWords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      structureBlocks: (map['structureBlocks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      customSystemPrompt: map['customSystemPrompt'] as String? ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CustomMethodology.fromJson(String source) =>
      CustomMethodology.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
