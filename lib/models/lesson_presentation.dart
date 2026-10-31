import 'dart:convert';
import 'package:flutter/material.dart';

enum SlideLayoutType {
  heroTitle,
  challengeHook,
  conceptBreakdown,
  visualScheme,
  interactivePractice,
  rubricCheck,
  conclusionReward,
}

class PresentationSlide {
  final int slideNumber;
  final SlideLayoutType layoutType;
  final String title;
  final String subtitle;
  final List<String> bulletPoints;
  final String speakerNotes;
  final String yandexArtPrompt;
  final int accentColorHex;
  final String badgeText;

  const PresentationSlide({
    required this.slideNumber,
    required this.layoutType,
    required this.title,
    this.subtitle = '',
    this.bulletPoints = const [],
    this.speakerNotes = '',
    this.yandexArtPrompt = '',
    this.accentColorHex = 0xFF4F46E5,
    this.badgeText = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'slideNumber': slideNumber,
      'layoutType': layoutType.name,
      'title': title,
      'subtitle': subtitle,
      'bulletPoints': bulletPoints,
      'speakerNotes': speakerNotes,
      'yandexArtPrompt': yandexArtPrompt,
      'accentColorHex': accentColorHex,
      'badgeText': badgeText,
    };
  }

  factory PresentationSlide.fromMap(Map<String, dynamic> map) {
    SlideLayoutType parsedType = SlideLayoutType.conceptBreakdown;
    final typeName = map['layoutType'] as String?;
    if (typeName != null) {
      for (final t in SlideLayoutType.values) {
        if (t.name == typeName) parsedType = t;
      }
    }
    return PresentationSlide(
      slideNumber: map['slideNumber'] as int? ?? 1,
      layoutType: parsedType,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      bulletPoints: (map['bulletPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      speakerNotes: map['speakerNotes'] as String? ?? '',
      yandexArtPrompt: map['yandexArtPrompt'] as String? ?? '',
      accentColorHex: map['accentColorHex'] as int? ?? 0xFF4F46E5,
      badgeText: map['badgeText'] as String? ?? '',
    );
  }
}

class LessonPresentation {
  final String id;
  final String title;
  final String topic;
  final String subject;
  final String ageGroup;
  final String methodName;
  final String thematicWorldId;
  final List<PresentationSlide> slides;
  final DateTime createdAt;

  const LessonPresentation({
    required this.id,
    required this.title,
    required this.topic,
    required this.subject,
    required this.ageGroup,
    required this.methodName,
    this.thematicWorldId = 'space',
    required this.slides,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'subject': subject,
      'ageGroup': ageGroup,
      'methodName': methodName,
      'thematicWorldId': thematicWorldId,
      'slides': slides.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LessonPresentation.fromMap(Map<String, dynamic> map) {
    return LessonPresentation(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      ageGroup: map['ageGroup'] as String? ?? '',
      methodName: map['methodName'] as String? ?? '',
      thematicWorldId: map['thematicWorldId'] as String? ?? 'space',
      slides: (map['slides'] as List<dynamic>?)
              ?.map((s) => PresentationSlide.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory LessonPresentation.fromJson(String source) =>
      LessonPresentation.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class PresentationPromptBuilder {
  /// Промпт для генерации структуры слайдов с правилами ведения урока
  static String buildSystemPrompt({
    required String subject,
    required String topic,
    required String ageGroup,
    required String methodology,
    String artStyle = 'акварельный скетч с четким контуром, чистый фон',
  }) {
    return '''Ты — ведущий дизайнер образовательных презентаций и методист высшей категории.
Твоя задача — создать сценарий презентации для ведения интерактивного урока в Microsoft PowerPoint.

### СТРОГИЕ ПРАВИЛА СОЗДАНИЯ СЛАЙДОВ УРОКА (Mobbin Design System):
1. ЛАКОНИЧНОСТЬ: Не более 1 ключевой идеи на слайд. Максимум 3-4 тезиса на слайде. Никаких «полотен» текста.
2. ИЕРАРХИЯ:
   - Четкий верхний бейдж (категория/фаза урока: ВВОДНАЯ МИССИЯ, ТРИЗ-ПРОТИВОРЕЧИЕ, ПРАКТИКУМ).
   - Крупный выразительный заголовок.
   - Подзаголовок-ориентир для учеников.
   - Карточки с акцентами в стиле Mobbin (чистый контраст, закругленные плашки).
3. УКАЗАНИЯ ДЛЯ УЧИТЕЛЯ (Speaker Notes): К каждому слайду ОБЯЗАТЕЛЬНО пропиши точный скрипт: что учитель говорит классу, какой вопрос задает, сколько минут длится слайд.
4. ПРОМПТ ДЛЯ YANDEXART: К каждому слайду напиши изолированный художественный промпт в стиле «$artStyle» для генерации наглядного визуального якоря (персонаж, наглядная схема, предметный объект).

### ОБЯЗАТЕЛЬНАЯ СТРУКТУРА ИЗ 7 СЛАЙДОВ:
Слайд 1: [HeroTitle] Титульный слайд темы «$topic» ($subject, $ageGroup, $methodology).
Слайд 2: [ChallengeHook] ТРИЗ-проблема / Загадка / Проблемный вопрос урока.
Слайд 3: [ConceptBreakdown] Главное правило / Теоретическая формула (3 наглядных тезиса).
Слайд 4: [VisualScheme] Схема / Алгоритм действия с промптом YandexART.
Слайд 5: [InteractivePractice] Интерактивный блиц у доски: найди ошибку / соедини пары.
Слайд 6: [RubricCheck] Критерии проверки и эталон решения для самооценки.
Слайд 7: [ConclusionReward] Итоги миссии, наградная медаль от маскота и домашнее задание.''';
  }
}
