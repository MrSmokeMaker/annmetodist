import 'dart:convert';
import 'package:flutter/material.dart';

/// Данные пользователя Telegram из Telegram.WebApp.initDataUnsafe.user
class TelegramUser {
  final int id;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? languageCode;
  final String? photoUrl;
  final bool isPremium;

  const TelegramUser({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.languageCode,
    this.photoUrl,
    this.isPremium = false,
  });

  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }

  String get displayName => username != null ? '@$username' : fullName;

  factory TelegramUser.fromMap(Map<String, dynamic> map) {
    return TelegramUser(
      id: (map['id'] as num?)?.toInt() ?? 0,
      firstName: map['first_name'] as String? ?? 'Педагог',
      lastName: map['last_name'] as String?,
      username: map['username'] as String?,
      languageCode: map['language_code'] as String?,
      photoUrl: map['photo_url'] as String?,
      isPremium: map['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'language_code': languageCode,
      'photo_url': photoUrl,
      'is_premium': isPremium,
    };
  }

  String toJson() => jsonEncode(toMap());
}

/// Параметры оформления Telegram клиента (Telegram.WebApp.themeParams)
class TelegramThemeParams {
  final Color? bgColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? linkColor;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final Color? secondaryBgColor;
  final Color? headerBgColor;
  final Color? accentTextColor;
  final Color? sectionBgColor;

  const TelegramThemeParams({
    this.bgColor,
    this.textColor,
    this.hintColor,
    this.linkColor,
    this.buttonColor,
    this.buttonTextColor,
    this.secondaryBgColor,
    this.headerBgColor,
    this.accentTextColor,
    this.sectionBgColor,
  });

  static Color? _parseHex(dynamic val) {
    if (val == null || val is! String || val.isEmpty) return null;
    final clean = val.replaceAll('#', '');
    if (clean.length == 6) {
      final intVal = int.tryParse('FF$clean', radix: 16);
      if (intVal != null) return Color(intVal);
    }
    return null;
  }

  factory TelegramThemeParams.fromMap(Map<String, dynamic> map) {
    return TelegramThemeParams(
      bgColor: _parseHex(map['bg_color']),
      textColor: _parseHex(map['text_color']),
      hintColor: _parseHex(map['hint_color']),
      linkColor: _parseHex(map['link_color']),
      buttonColor: _parseHex(map['button_color']),
      buttonTextColor: _parseHex(map['button_text_color']),
      secondaryBgColor: _parseHex(map['secondary_bg_color']),
      headerBgColor: _parseHex(map['header_bg_color']),
      accentTextColor: _parseHex(map['accent_text_color']),
      sectionBgColor: _parseHex(map['section_bg_color']),
    );
  }
}
