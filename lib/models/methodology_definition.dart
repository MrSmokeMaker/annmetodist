import 'dart:convert';
import 'method_prompt.dart';

/// Предпочитаемый стиль оформления иллюстраций YandexART для методики
enum ArtStylePreference {
  classicBookGraphic('Классическая советская книжная графика', 'Мягкие цвета, чёткий контур, академическая ясность'),
  cpaRealistic('Сингапурский наглядный CPA-реализм', 'Объёмные осязаемые предметы для счёта на белом фоне'),
  minimalistEngraving('Академическая гравюра и чертёж', 'Строгие геометрические контуры и наглядные схемы'),
  cleanColoringOutline('Контурная раскраска', 'Толстые чёрные контуры без заливки и теней');

  final String label;
  final String description;
  const ArtStylePreference(this.label, this.description);
}

/// Профиль предпочитаемых дидактических полей ответов методики
class DidacticFieldProfile {
  final bool preferNarrowObliqueRuling65; // Узкая косая линейка под 65° (по Мазиной)
  final bool preferMathGrid5x5;          // Тетрадная клетка 5х5 мм (по Пчёлке)
  final bool preferNumberHouses;         // Числовые домики состава чисел
  final bool preferLetterBoxes;          // Орфографические окошки для букв
  final bool preferCipherGrids;          // Таблицы-шифровки и коды
  final bool preferTrizContradiction;    // Таблицы анализа «Хорошо-Плохо»
  final bool preferMultipleChoice;       // Тестовые варианты с чекбоксами

  const DidacticFieldProfile({
    this.preferNarrowObliqueRuling65 = true,
    this.preferMathGrid5x5 = true,
    this.preferNumberHouses = false,
    this.preferLetterBoxes = false,
    this.preferCipherGrids = false,
    this.preferTrizContradiction = false,
    this.preferMultipleChoice = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferNarrowObliqueRuling65': preferNarrowObliqueRuling65,
      'preferMathGrid5x5': preferMathGrid5x5,
      'preferNumberHouses': preferNumberHouses,
      'preferLetterBoxes': preferLetterBoxes,
      'preferCipherGrids': preferCipherGrids,
      'preferTrizContradiction': preferTrizContradiction,
      'preferMultipleChoice': preferMultipleChoice,
    };
  }

  factory DidacticFieldProfile.fromMap(Map<String, dynamic> map) {
    return DidacticFieldProfile(
      preferNarrowObliqueRuling65: map['preferNarrowObliqueRuling65'] as bool? ?? true,
      preferMathGrid5x5: map['preferMathGrid5x5'] as bool? ?? true,
      preferNumberHouses: map['preferNumberHouses'] as bool? ?? false,
      preferLetterBoxes: map['preferLetterBoxes'] as bool? ?? false,
      preferCipherGrids: map['preferCipherGrids'] as bool? ?? false,
      preferTrizContradiction: map['preferTrizContradiction'] as bool? ?? false,
      preferMultipleChoice: map['preferMultipleChoice'] as bool? ?? false,
    );
  }
}

/// Полный паспорт и декларативное описание педагогической методики
class MethodologyDefinition {
  final String id;
  final String name;
  final String authorName;
  final int year;
  final String subjectArea;
  final String paradigm;
  final List<String> keyPrinciples;
  final List<String> targetAgeGroups;
  final List<String> structureBlocks;
  final List<String> stopWords;
  final String customSystemPrompt;
  final DidacticFieldProfile fieldProfile;
  final ArtStylePreference artStyle;
  final DateTime createdAt;

  const MethodologyDefinition({
    required this.id,
    required this.name,
    required this.authorName,
    this.year = 2024,
    required this.subjectArea,
    required this.paradigm,
    this.keyPrinciples = const [],
    this.targetAgeGroups = const ['1 класс', '2 класс', '3-4 класс'],
    this.structureBlocks = const [
      '1. Организационный момент и актуализация',
      '2. Открытие нового знания',
      '3. Практическое закрепление (3 уровня заданий)',
      '4. Физкультминутка и пальчиковая разминка',
      '5. Рефлексия и ключи для учителя',
    ],
    this.stopWords = const [],
    this.customSystemPrompt = '',
    this.fieldProfile = const DidacticFieldProfile(),
    this.artStyle = ArtStylePreference.classicBookGraphic,
    required this.createdAt,
  });

  /// Формирует обогащённый системный блок промпта для ИИ-генератора
  String buildMethodPromptBlock() {
    final buffer = StringBuffer();
    buffer.writeln('МЕТОДИЧЕСКИЙ ПОДХОД: $name ($authorName, $year г.)');
    buffer.writeln('Предметная область: $subjectArea. Парадигма: $paradigm.');
    if (keyPrinciples.isNotEmpty) {
      buffer.writeln('Фундаментальные принципы:');
      for (final p in keyPrinciples) {
        buffer.writeln('• $p');
      }
    }
    if (stopWords.isNotEmpty) {
      buffer.writeln('Категорические стоп-слова и запрещённые приёмы: ${stopWords.join(", ")}.');
    }
    if (customSystemPrompt.isNotEmpty) {
      buffer.writeln('Специфические указания методики: $customSystemPrompt');
    }
    buffer.writeln('Требования к рабочему листу:');
    if (fieldProfile.preferNarrowObliqueRuling65) {
      buffer.writeln('- Все задания по письму и списыванию оформлять в частую узкую косую линейку под 65° по Мазиной.');
    }
    if (fieldProfile.preferMathGrid5x5) {
      buffer.writeln('- Все математические вычисления оформлять в тетрадную клетку 5х5 мм по Пчёлке.');
    }
    if (fieldProfile.preferNumberHouses) {
      buffer.writeln('- Обязательно включать числовые домики состава числа [числовой домик] с парными ячейками.');
    }
    if (fieldProfile.preferLetterBoxes) {
      buffer.writeln('- Для орфографических упражнений использовать окошки для букв [окошки].');
    }
    if (fieldProfile.preferCipherGrids) {
      buffer.writeln('- Включать детективные шифровки и дешифраторы [шифр] на 3 уровне сложности.');
    }
    if (fieldProfile.preferTrizContradiction) {
      buffer.writeln('- Включать задания на разрешение противоречий [хорошо-плохо].');
    }

    return buffer.toString();
  }

  /// Преобразует в легковесный `MethodPrompt` для совместимости со всей кодовой базой
  MethodPrompt toMethodPrompt() {
    return MethodPrompt(
      id: id,
      name: '$name ($authorName)',
      subject: subjectArea,
      description: '$paradigm. Принципы: ${keyPrinciples.join("; ")}',
      promptBlock: buildMethodPromptBlock(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'authorName': authorName,
      'year': year,
      'subjectArea': subjectArea,
      'paradigm': paradigm,
      'keyPrinciples': keyPrinciples,
      'targetAgeGroups': targetAgeGroups,
      'structureBlocks': structureBlocks,
      'stopWords': stopWords,
      'customSystemPrompt': customSystemPrompt,
      'fieldProfile': fieldProfile.toMap(),
      'artStyle': artStyle.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MethodologyDefinition.fromMap(Map<String, dynamic> map) {
    ArtStylePreference parsedArt = ArtStylePreference.classicBookGraphic;
    final artStr = map['artStyle'] as String?;
    if (artStr != null) {
      for (final a in ArtStylePreference.values) {
        if (a.name == artStr) parsedArt = a;
      }
    }

    return MethodologyDefinition(
      id: map['id'] as String? ?? 'custom_method_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Новая методика',
      authorName: map['authorName'] as String? ?? 'Педагог-методист',
      year: map['year'] as int? ?? DateTime.now().year,
      subjectArea: map['subjectArea'] as String? ?? 'Начальная школа',
      paradigm: map['paradigm'] as String? ?? 'Классическая развивающая дидактика',
      keyPrinciples: (map['keyPrinciples'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetAgeGroups: (map['targetAgeGroups'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['1 класс', '2 класс', '3-4 класс'],
      structureBlocks: (map['structureBlocks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stopWords: (map['stopWords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      customSystemPrompt: map['customSystemPrompt'] as String? ?? '',
      fieldProfile: map['fieldProfile'] != null
          ? DidacticFieldProfile.fromMap(map['fieldProfile'] as Map<String, dynamic>)
          : const DidacticFieldProfile(),
      artStyle: parsedArt,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory MethodologyDefinition.fromJson(String source) =>
      MethodologyDefinition.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
