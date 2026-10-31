import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'thematic_world.dart';

class CustomWorldConfig {
  final String id;
  final String title;
  final String schoolName;
  final String subtitle;
  final String mascotName;
  final String mascotRole;
  final String missionBadge;
  final int primaryColorHex;
  final int secondaryColorHex;
  final int accentColorHex;
  final String artStylePrompt;
  final String supportPhrase;
  final String? mascotBase64;
  final String? bannerBase64;
  final bool isCustom;

  CustomWorldConfig({
    required this.id,
    required this.title,
    this.schoolName = '',
    this.subtitle = '',
    required this.mascotName,
    required this.mascotRole,
    String? missionBadge,
    required this.primaryColorHex,
    int? secondaryColorHex,
    required this.accentColorHex,
    String? yandexArtStylePrompt,
    String artStylePrompt = 'советская книжная иллюстрация, чистый фон, без текста',
    this.supportPhrase = 'Полный вперед к новым открытиям!',
    this.mascotBase64,
    this.bannerBase64,
    this.isCustom = true,
  })  : missionBadge = missionBadge ?? (schoolName.isNotEmpty ? schoolName : 'МИССИЯ'),
        secondaryColorHex = secondaryColorHex ?? primaryColorHex,
        artStylePrompt = yandexArtStylePrompt ?? artStylePrompt;

  Color get primaryColor => Color(primaryColorHex);
  Color get secondaryColor => Color(secondaryColorHex);
  Color get accentColor => Color(accentColorHex);

  PdfColor get pdfPrimary => PdfColor.fromInt(primaryColorHex);
  PdfColor get pdfSecondary => PdfColor.fromInt(secondaryColorHex);
  PdfColor get pdfAccent => PdfColor.fromInt(accentColorHex);

  ThematicWorld toThematicWorld() {
    return ThematicWorld(
      type: ThematicWorldType.space,
      id: id,
      title: title,
      mascotName: mascotName,
      mascotRole: mascotRole,
      missionBadge: missionBadge,
      primaryColorHex: primaryColorHex,
      secondaryColorHex: secondaryColorHex,
      accentColorHex: accentColorHex,
      bannerPrompt: 'панорамный фон для шапки листа, стиль: $artStylePrompt, чистый фон, без текста',
      mascotPrompt: 'маскот $mascotName, $mascotRole, стиль: $artStylePrompt, изолированно на белом фоне',
      customGreetingPhrase: supportPhrase,
    );
  }

  CustomWorldConfig copyWith({
    String? id,
    String? title,
    String? mascotName,
    String? mascotRole,
    String? missionBadge,
    int? primaryColorHex,
    int? secondaryColorHex,
    int? accentColorHex,
    String? artStylePrompt,
    String? supportPhrase,
    String? mascotBase64,
    String? bannerBase64,
    bool? isCustom,
  }) {
    return CustomWorldConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      mascotName: mascotName ?? this.mascotName,
      mascotRole: mascotRole ?? this.mascotRole,
      missionBadge: missionBadge ?? this.missionBadge,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      artStylePrompt: artStylePrompt ?? this.artStylePrompt,
      supportPhrase: supportPhrase ?? this.supportPhrase,
      mascotBase64: mascotBase64 ?? this.mascotBase64,
      bannerBase64: bannerBase64 ?? this.bannerBase64,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'mascotName': mascotName,
    'mascotRole': mascotRole,
    'missionBadge': missionBadge,
    'primaryColorHex': primaryColorHex,
    'secondaryColorHex': secondaryColorHex,
    'accentColorHex': accentColorHex,
    'artStylePrompt': artStylePrompt,
    'supportPhrase': supportPhrase,
    'mascotBase64': mascotBase64,
    'bannerBase64': bannerBase64,
    'isCustom': isCustom,
  };

  factory CustomWorldConfig.fromMap(Map<String, dynamic> map) => CustomWorldConfig(
    id: map['id'] as String? ?? 'custom_world_01',
    title: map['title'] as String? ?? 'Академия Знаний',
    mascotName: map['mascotName'] as String? ?? 'Учёный Кот',
    mascotRole: map['mascotRole'] as String? ?? 'Хранитель традиций',
    missionBadge: map['missionBadge'] as String? ?? 'МИССИЯ ЛИЦЕЯ №1',
    primaryColorHex: (map['primaryColorHex'] as num?)?.toInt() ?? 0xFF1E1B4B,
    secondaryColorHex: (map['secondaryColorHex'] as num?)?.toInt() ?? 0xFF312E81,
    accentColorHex: (map['accentColorHex'] as num?)?.toInt() ?? 0xFFF59E0B,
    artStylePrompt: map['artStylePrompt'] as String? ?? 'советская книжная иллюстрация, чистый фон',
    supportPhrase: map['supportPhrase'] as String? ?? 'Вперед к новым открытиям!',
    mascotBase64: map['mascotBase64'] as String?,
    bannerBase64: map['bannerBase64'] as String?,
    isCustom: map['isCustom'] as bool? ?? true,
  );

  String toJson() => jsonEncode(toMap());
  factory CustomWorldConfig.fromJson(String source) =>
      CustomWorldConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
