import 'dart:convert';
import 'package:flutter/material.dart';

/// Конфигурация авторского мира школы / класса (Тариф Директор)
class CustomWorldConfig {
  final String id;
  final String schoolName;
  final String mascotName;
  final String? mascotImageUrl;
  final String missionTitle;
  final List<String> teacherSlogans;
  final int primaryColorHex;
  final int secondaryColorHex;
  final String yandexArtStylePrompt;
  final String yandexArtNegativePrompt;
  final bool isCustomHeaderGenerated;
  final String? generatedHeaderUrl;
  final DateTime updatedAt;

  const CustomWorldConfig({
    required this.id,
    required this.schoolName,
    required this.mascotName,
    this.mascotImageUrl,
    required this.missionTitle,
    required this.teacherSlogans,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.yandexArtStylePrompt,
    this.yandexArtNegativePrompt = 'размытость, текст с ошибками, низкое разрешение, деформация',
    this.isCustomHeaderGenerated = false,
    this.generatedHeaderUrl,
    required this.updatedAt,
  });

  Color get primaryColor => Color(primaryColorHex);
  Color get secondaryColor => Color(secondaryColorHex);

  static const List<String> popularArtStyles = [
    'Советский диафильм 70-х, теплая пастель, мягкий зернистый свет',
    'Чертёж тушью и акварельная отмывка, академическая графика',
    'Акварельный скетч с четким контуром, живая ботаническая иллюстрация',
    'Старинная гравюра на меди, утончённая штриховка, винтажный пергамент',
    'Пластилиновая 3D-анимация, тактильная фактура, мягкие тени',
    'Неоновый киберпанк-конструктивизм, футуристическая геометрия',
  ];

  static CustomWorldConfig defaultLyceum() {
    return CustomWorldConfig(
      id: 'custom_world_default',
      schoolName: 'Лицей №1 «Интеллект»',
      mascotName: 'Учёный Кот Архимед',
      missionTitle: 'Миссия Лицея: От смелой гипотезы к великому открытию',
      teacherSlogans: [
        'Ошибки — это ступени к настоящему открытию!',
        'Думай логично, действуй уверенно, твори свободно!',
        'Каждая сложная задача скрывает красивое решение.',
      ],
      primaryColorHex: 0xFF4F46E5, // Indigo
      secondaryColorHex: 0xFF06B6D4, // Cyan
      yandexArtStylePrompt: 'Советский диафильм 70-х, теплая пастель, мягкий зернистый свет',
      isCustomHeaderGenerated: true,
      generatedHeaderUrl: 'assets/images/custom_lyceum_header.png',
      updatedAt: DateTime.now(),
    );
  }

  CustomWorldConfig copyWith({
    String? id,
    String? schoolName,
    String? mascotName,
    String? mascotImageUrl,
    String? missionTitle,
    List<String>? teacherSlogans,
    int? primaryColorHex,
    int? secondaryColorHex,
    String? yandexArtStylePrompt,
    String? yandexArtNegativePrompt,
    bool? isCustomHeaderGenerated,
    String? generatedHeaderUrl,
    DateTime? updatedAt,
  }) {
    return CustomWorldConfig(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      mascotName: mascotName ?? this.mascotName,
      mascotImageUrl: mascotImageUrl ?? this.mascotImageUrl,
      missionTitle: missionTitle ?? this.missionTitle,
      teacherSlogans: teacherSlogans ?? this.teacherSlogans,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      yandexArtStylePrompt: yandexArtStylePrompt ?? this.yandexArtStylePrompt,
      yandexArtNegativePrompt: yandexArtNegativePrompt ?? this.yandexArtNegativePrompt,
      isCustomHeaderGenerated: isCustomHeaderGenerated ?? this.isCustomHeaderGenerated,
      generatedHeaderUrl: generatedHeaderUrl ?? this.generatedHeaderUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolName': schoolName,
      'mascotName': mascotName,
      'mascotImageUrl': mascotImageUrl,
      'missionTitle': missionTitle,
      'teacherSlogans': teacherSlogans,
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
      'yandexArtStylePrompt': yandexArtStylePrompt,
      'yandexArtNegativePrompt': yandexArtNegativePrompt,
      'isCustomHeaderGenerated': isCustomHeaderGenerated,
      'generatedHeaderUrl': generatedHeaderUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomWorldConfig.fromMap(Map<String, dynamic> map) {
    return CustomWorldConfig(
      id: map['id'] as String? ?? 'custom_world_default',
      schoolName: map['schoolName'] as String? ?? 'Гимназия',
      mascotName: map['mascotName'] as String? ?? 'Маскот',
      mascotImageUrl: map['mascotImageUrl'] as String?,
      missionTitle: map['missionTitle'] as String? ?? 'Миссия школы',
      teacherSlogans: (map['teacherSlogans'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      primaryColorHex: map['primaryColorHex'] as int? ?? 0xFF4F46E5,
      secondaryColorHex: map['secondaryColorHex'] as int? ?? 0xFF06B6D4,
      yandexArtStylePrompt: map['yandexArtStylePrompt'] as String? ?? 'Советский диафильм 70-х',
      yandexArtNegativePrompt: map['yandexArtNegativePrompt'] as String? ?? '',
      isCustomHeaderGenerated: map['isCustomHeaderGenerated'] as bool? ?? false,
      generatedHeaderUrl: map['generatedHeaderUrl'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CustomWorldConfig.fromJson(String source) =>
      CustomWorldConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
