import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class YandexGptException implements Exception {
  final String message;
  final int? statusCode;

  YandexGptException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class YandexGptService {
  final StorageService _storageService;

  static const String _completionUrl =
      'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';
  static const String defaultModel = 'yandexgpt'; // or yandexgpt-lite

  YandexGptService({required StorageService storageService})
      : _storageService = storageService;

  HttpClient _createHttpClient() {
    return HttpClient();
  }

  /// Sends test request to verify API credentials and IAM permissions
  Future<Map<String, dynamic>> testConnection({
    String? apiKey,
    String? folderId,
  }) async {
    final effectiveKey = apiKey?.trim() ?? await _storageService.getApiKey();
    final effectiveFolder =
        folderId?.trim() ?? await _storageService.getFolderId();

    if (effectiveKey == null || effectiveKey.isEmpty) {
      return {
        'success': false,
        'message': 'API-ключ не указан.',
      };
    }
    if (effectiveFolder == null || effectiveFolder.isEmpty) {
      return {
        'success': false,
        'message': 'Идентификатор каталога (Folder ID) не указан.',
      };
    }

    final client = _createHttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_completionUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Api-Key $effectiveKey');

      final payload = {
        'modelUri': 'gpt://$effectiveFolder/$defaultModel/latest',
        'completionOptions': {
          'stream': false,
          'temperature': 0.6,
          'maxTokens': '20',
        },
        'messages': [
          {
            'role': 'user',
            'text': 'Тест',
          }
        ],
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Соединение с YandexGPT успешно установлено!',
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'statusCode': 403,
          'message':
              'Ошибка 403: Сервисному аккаунту в каталоге ($effectiveFolder) не назначена роль ai.languageModels.user.',
        };
      }

      if (response.statusCode == 400 && responseBody.contains('Specified folder ID')) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Ошибка 400: Указанный Folder ID не совпадает с каталогом сервисного аккаунта.',
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Ошибка авторизации (${response.statusCode}): $responseBody',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Сетевая ошибка: $e',
      };
    } finally {
      client.close();
    }
  }

  /// Generates lesson plan conspect with system and user prompts
  Future<String> generateConspect({
    required String systemPrompt,
    required String userPrompt,
    String model = defaultModel,
  }) async {
    final apiKey = await _storageService.getApiKey();
    final folderId = await _storageService.getFolderId();

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw YandexGptException(
        'API-ключ YandexGPT не задан. Пожалуйста, укажите его в настройках.',
      );
    }
    if (folderId == null || folderId.trim().isEmpty) {
      throw YandexGptException(
        'Идентификатор каталога (Folder ID) не задан. Пожалуйста, укажите его в настройках.',
      );
    }

    final client = _createHttpClient();

    try {
      final request = await client.postUrl(Uri.parse(_completionUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Api-Key ${apiKey.trim()}');

      final payload = {
        'modelUri': 'gpt://${folderId.trim()}/$model/latest',
        'completionOptions': {
          'stream': false,
          'temperature': 0.6,
          'maxTokens': '3000',
        },
        'messages': [
          {
            'role': 'system',
            'text': systemPrompt,
          },
          {
            'role': 'user',
            'text': userPrompt,
          }
        ],
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        if (response.statusCode == 403) {
          throw YandexGptException(
            'Ошибка 403 (Доступ запрещен). Сервисному аккаунту в Яндекс Облаке необходимо назначить роль "ai.languageModels.user".',
            403,
          );
        } else if (response.statusCode == 401) {
          throw YandexGptException(
            'Неверный API-ключ Yandex Cloud. Проверьте ключ в настройках.',
            401,
          );
        } else if (response.statusCode == 429) {
          throw YandexGptException(
            'Превышен лимит запросов YandexGPT. Попробуйте через минуту.',
            429,
          );
        }
        throw YandexGptException(
          'Ошибка генерации YandexGPT (${response.statusCode}): $responseBody',
          response.statusCode,
        );
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final alternatives = result?['alternatives'] as List<dynamic>?;

      if (alternatives == null || alternatives.isEmpty) {
        throw YandexGptException('Модель YandexGPT вернула пустой ответ. Попробуйте снова.');
      }

      final message = alternatives.first['message'] as Map<String, dynamic>?;
      final text = message?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw YandexGptException('Ответ модели пуст. Попробуйте снова.');
      }

      return text.trim();
    } on SocketException {
      throw YandexGptException('Ошибка соединения с сетью. Проверьте интернет.');
    } finally {
      client.close();
    }
  }
}
