import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class YandexGptService {
  static const _endpoint =
      'https://foundation-models.api.cloud.yandex.net/v1/openai/chat/completions';

  final StorageService _storage = StorageService();

  Future<String> generate(String prompt) async {
    if (kIsWeb) {
      // Web version cannot access flutter_secure_storage; inform the user.
      throw Exception('Генерация работает только в нативных приложениях (Windows/Android/iOS).');
    }
    final apiKey = await _storage.getApiKey();
    final folderId = await _storage.getFolderId();
    if (apiKey == null || folderId == null) {
      throw Exception('API‑key или folder_id не найдены в безопасном хранилище.');
    }
    final headers = {
      'Authorization': 'Api-Key $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'yandexgpt',
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': prompt},
      ],
      'folderId': folderId,
    });
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    // The exact path depends on YandexGPT's response format.
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      return 'Пустой ответ от сервиса.';
    }
    return choices.first['message']['content'] as String? ?? 'Нет содержимого.';
  }
}
