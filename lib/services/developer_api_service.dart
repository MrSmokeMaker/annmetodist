import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/conspect.dart';
import 'storage_service.dart';

class DeveloperApiService {
  final StorageService _storageService;
  static const String _apiTokenKey = 'developer_api_live_token';

  DeveloperApiService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Получение или генерация уникального API-токена разработчика
  Future<String> getOrCreateApiToken() async {
    final existing = await _storageService.getCustomString(_apiTokenKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newToken = 'mdev_live_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    await _storageService.saveCustomString(_apiTokenKey, newToken);
    return newToken;
  }

  /// Регенерация API-токена
  Future<String> regenerateToken() async {
    final newToken = 'mdev_live_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    await _storageService.saveCustomString(_apiTokenKey, newToken);
    return newToken;
  }

  /// Статический генератор токена для мгновенного использования
  static String generateDevToken() {
    return 'mdev_live_${DateTime.now().millisecondsSinceEpoch}_1001';
  }

  static String generateCurlExample(String token) => getCurlSnippet(token);
  static String exportConspectToJson(Conspect c) => exportToJson(c);
  static String exportConspectToMarkdown(Conspect c) => exportToMarkdown(c);
  static String exportConspectToHtml(Conspect c) => exportToHtml(c);

  /// Экспорт урока в чистый JSON для внешних интеграций
  static String exportToJson(Conspect conspect) {
    final data = {
      'meta': {
        'id': conspect.id,
        'title': conspect.title,
        'topic': conspect.topic,
        'subject': conspect.subject,
        'ageGroup': conspect.ageGroup,
        'duration': conspect.duration,
        'methodology': conspect.methodName,
        'thematicWorld': conspect.thematicWorld.title,
        'mascot': conspect.thematicWorld.mascotName,
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': '2.1.0',
      },
      'materials': conspect.generatedMaterials,
      'content': conspect.content,
      'hasCards': (conspect.cards?.length ?? 0) > 0,
      'cardsCount': conspect.cards?.length ?? 0,
      'cards': conspect.cards?.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Экспорт урока в чистый Markdown для Notion / Obsidian / Сферум
  static String exportToMarkdown(Conspect conspect) {
    final buffer = StringBuffer();
    buffer.writeln('# ${conspect.title}');
    buffer.writeln('**Предмет:** ${conspect.subject} | **Класс/Группа:** ${conspect.ageGroup} | **Длительность:** ${conspect.duration}');
    buffer.writeln('**Методика:** ${conspect.methodName} | **Мир:** ${conspect.thematicWorld.title} (${conspect.thematicWorld.mascotName})');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(conspect.content);
    return buffer.toString();
  }

  /// Экспорт урока в структурированный HTML для МЭШ, ЭЖД и Moodle
  static String exportToHtml(Conspect conspect) {
    final title = conspect.title.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final subject = conspect.subject.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final ageGroup = conspect.ageGroup.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final methodName = conspect.methodName.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final world = conspect.thematicWorld;

    // Конвертация Markdown заголовков и списков в базовые HTML теги
    String htmlBody = conspect.content
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    // Заголовки
    htmlBody = htmlBody.replaceAllMapped(RegExp(r'^# (.*)$', multiLine: true), (m) => '<h1 class="lesson-h1">${m[1]}</h1>');
    htmlBody = htmlBody.replaceAllMapped(RegExp(r'^## (.*)$', multiLine: true), (m) => '<h2 class="lesson-h2">${m[1]}</h2>');
    htmlBody = htmlBody.replaceAllMapped(RegExp(r'^### (.*)$', multiLine: true), (m) => '<h3 class="lesson-h3">${m[1]}</h3>');

    // Списки
    htmlBody = htmlBody.replaceAllMapped(RegExp(r'^- (.*)$', multiLine: true), (m) => '<li>${m[1]}</li>');
    // Жирный текст
    htmlBody = htmlBody.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>');
    // Переводы строк
    htmlBody = htmlBody.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br/>');

    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1e293b; max-width: 860px; margin: 0 auto; padding: 24px; }
    .header-banner { background: linear-gradient(135deg, #${world.primaryColorHex.toRadixString(16).padLeft(6, '0')}, #${world.secondaryColorHex.toRadixString(16).padLeft(6, '0')}); color: white; padding: 20px; border-radius: 12px; margin-bottom: 24px; }
    .badge { display: inline-block; background: rgba(255,255,255,0.2); padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: bold; margin-bottom: 8px; text-transform: uppercase; }
    .lesson-h1 { font-size: 24px; margin: 0 0 8px 0; }
    .lesson-h2 { font-size: 19px; color: #1e3a8a; border-bottom: 2px solid #e2e8f0; padding-bottom: 6px; margin-top: 24px; }
    .lesson-h3 { font-size: 16px; color: #475569; margin-top: 16px; }
    .meta-row { font-size: 14px; opacity: 0.95; }
    p { margin: 10px 0; }
    li { margin: 4px 0; }
  </style>
</head>
<body>
  <div class="header-banner">
    <div class="badge">${world.missionBadge} • ${world.title}</div>
    <div class="lesson-h1">$title</div>
    <div class="meta-row"><strong>Предмет:</strong> $subject ($ageGroup) | <strong>Методика:</strong> $methodName | <strong>Маскот:</strong> ${world.mascotName}</div>
  </div>
  <div class="content">
    <p>$htmlBody</p>
  </div>
</body>
</html>''';
  }

  /// Генерация сниппета cURL
  static String getCurlSnippet(String token) {
    return '''curl -X POST https://api.metodist.ai/v1/lessons/generate \\
  -H "Authorization: Bearer $token" \\
  -H "Content-Type: application/json" \\
  -d '{
    "topic": "Сложение и вычитание в пределах 20",
    "subject": "Математика",
    "ageGroup": "1 класс",
    "methodId": "pchelko_math",
    "thematicWorld": "space",
    "materials": ["conspect", "worksheet", "homework"]
  }' ''';
  }

  /// Генерация сниппета Python
  static String getPythonSnippet(String token) {
    return '''import requests

url = "https://api.metodist.ai/v1/lessons/generate"
headers = {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json"
}
payload = {
    "topic": "Гласные и согласные звуки",
    "subject": "Русский язык",
    "ageGroup": "1 класс",
    "methodId": "kostin_russian",
    "thematicWorld": "forest",
    "format": "json"
}

response = requests.post(url, json=payload, headers=headers)
lesson_data = response.json()
print("Сгенерирован урок:", lesson_data["meta"]["title"])''';
  }
}
