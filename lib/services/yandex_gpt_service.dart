import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// Сервис взаимодействия с YandexGPT API.
class YandexGptService {
  // Актуальный OpenAI-совместимый эндпоинт Yandex Cloud
  static const _openAiEndpoint =
      'https://llm.api.cloud.yandex.net/v1/chat/completions';

  // Актуальный нативный эндпоинт Foundation Models (синхронная генерация)
  static const _nativeEndpoint =
      'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';

  static const String defaultModel = 'yandexgpt-lite';

  final StorageService _storageService;
  final http.Client? _customClient;

  YandexGptService({
    required StorageService storageService,
    http.Client? client,
  })  : _storageService = storageService,
        _customClient = client;

  http.Client _createClient() => _customClient ?? http.Client();

  /// Проверка подключения к YandexGPT и прав сервисного аккаунта.
  Future<Map<String, dynamic>> testConnection({
    String? apiKey,
    String? folderId,
  }) async {
    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'Прямые запросы к Yandex Cloud API из веб-браузера блокируются политикой CORS браузера. Запустите приложение на Windows, Android или iOS.',
      };
    }

    final effectiveKey = apiKey?.trim() ?? await _storageService.getApiKey();
    final effectiveFolder =
        folderId?.trim() ?? await _storageService.getFolderId();

    if (effectiveKey == null || effectiveKey.isEmpty) {
      return {'success': false, 'message': 'API-ключ не указан.'};
    }
    if (effectiveFolder == null || effectiveFolder.isEmpty) {
      return {'success': false, 'message': 'Folder ID не указан.'};
    }

    final client = _createClient();
    try {
      final response = await client.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $effectiveKey',
        },
        body: jsonEncode({
          'model': 'gpt://$effectiveFolder/$defaultModel',
          'messages': [
            {'role': 'user', 'content': 'Тест связи'},
          ],
          'temperature': 0.6,
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Соединение с YandexGPT успешно установлено!',
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Ошибка 401: Неверный API-ключ Yandex Cloud. Проверьте ключ в настройках.',
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

      if (response.statusCode == 429) {
        return {
          'success': false,
          'statusCode': 429,
          'message': 'Ошибка 429: Превышен лимит запросов YandexGPT.',
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Ошибка YandexGPT (${response.statusCode}): ${response.body}',
      };
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Load failed') || errStr.contains('Failed to fetch')) {
        return {
          'success': false,
          'message':
              'Сетевая ошибка: запрос заблокирован политикой CORS браузера или отсутствует интернет-соединение.',
        };
      }
      return {'success': false, 'message': 'Сетевая ошибка: $e'};
    } finally {
      if (_customClient == null) {
        client.close();
      }
    }
  }

  /// Генерация конспекта с помощью YandexGPT.
  Future<String> generateConspect({
    required String systemPrompt,
    required String userPrompt,
    String model = defaultModel,
  }) async {
    if (kIsWeb) {
      throw YandexGptException(
        'Прямые запросы к Yandex Cloud API из веб-браузера блокируются политикой CORS браузера. Запустите приложение на Windows, Android или iOS.',
      );
    }

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

    final client = _createClient();
    try {
      // 1. Сначала пробуем OpenAI-совместимый эндпоинт
      var response = await client.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key ${apiKey.trim()}',
        },
        body: jsonEncode({
          'model': 'gpt://${folderId.trim()}/$model',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.6,
          'max_tokens': 3000,
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices.first['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }

      if (response.statusCode == 401) {
        throw YandexGptException(
          'Неверный API-ключ Yandex Cloud. Проверьте ключ в настройках.',
          401,
        );
      } else if (response.statusCode == 403) {
        throw YandexGptException(
          'Ошибка 403 (Доступ запрещен). Сервисному аккаунту в Яндекс Облаке необходимо назначить роль "ai.languageModels.user".',
          403,
        );
      } else if (response.statusCode == 429) {
        throw YandexGptException(
          'Превышен лимит запросов YandexGPT. Попробуйте через минуту.',
          429,
        );
      }

      // 2. Резервный вызов через нативный эндпоинт Foundation Models
      response = await client.post(
        Uri.parse(_nativeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key ${apiKey.trim()}',
        },
        body: jsonEncode({
          'modelUri': 'gpt://${folderId.trim()}/$model/latest',
          'completionOptions': {
            'stream': false,
            'temperature': 0.6,
            'maxTokens': '3000',
          },
          'messages': [
            {'role': 'system', 'text': systemPrompt},
            {'role': 'user', 'text': userPrompt},
          ],
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw YandexGptException(
            'Неверный API-ключ Yandex Cloud. Проверьте ключ в настройках.',
            401,
          );
        } else if (response.statusCode == 403) {
          throw YandexGptException(
            'Ошибка 403 (Доступ запрещен). Сервисному аккаунту в Яндекс Облаке необходимо назначить роль "ai.languageModels.user".',
            403,
          );
        } else if (response.statusCode == 429) {
          throw YandexGptException(
            'Превышен лимит запросов YandexGPT. Попробуйте через минуту.',
            429,
          );
        }
        throw YandexGptException(
          'Ошибка генерации YandexGPT (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final alternatives = result?['alternatives'] as List<dynamic>?;
      if (alternatives == null || alternatives.isEmpty) {
        throw YandexGptException(
          'Модель YandexGPT вернула пустой ответ. Попробуйте снова.',
        );
      }

      final message = alternatives.first['message'] as Map<String, dynamic>?;
      final text = message?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw YandexGptException('Ответ модели пуст. Попробуйте снова.');
      }
      return text.trim();
    } catch (e) {
      if (e is YandexGptException) rethrow;
      if (e is TimeoutException) {
        throw YandexGptException(
          'Превышено время ожидания ответа YandexGPT (таймаут). Проверьте интернет-соединение.',
        );
      }
      final errStr = e.toString();
      if (errStr.contains('Load failed') || errStr.contains('Failed to fetch')) {
        throw YandexGptException(
          'Сетевая ошибка: запрос заблокирован политикой CORS браузера или отсутствует интернет-соединение.',
        );
      }
      throw YandexGptException('Сетевая ошибка: $e');
    } finally {
      if (_customClient == null) {
        client.close();
      }
    }
  }
}

/// Исключение при работе с YandexGPT.
class YandexGptException implements Exception {
  final String message;
  final int? code;
  YandexGptException(this.message, [this.code]);

  @override
  String toString() =>
      'YandexGptException: $message${code != null ? ' (код $code)' : ''}';
}
