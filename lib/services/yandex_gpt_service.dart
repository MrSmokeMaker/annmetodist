import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Primary OpenAI-compatible endpoint for Yandex Cloud AI Studio
  static const String _openAiEndpoint =
      'https://ai.api.cloud.yandex.net/v1/chat/completions';
  // Native Foundation Models fallback endpoint
  static const String _nativeEndpoint =
      'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';

  static const String defaultModel = 'yandexgpt-lite';

  YandexGptService({required StorageService storageService})
      : _storageService = storageService;

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

    final client = http.Client();
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
      );

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

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Ошибка авторизации (${response.statusCode}): ${response.body}',
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

    final client = http.Client();
    try {
      // 1. Try OpenAI-compatible endpoint first
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
      );

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

      // 2. Fallback to native Foundation Models endpoint
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
      );

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
          'Ошибка генерации YandexGPT (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
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
    } catch (e) {
      if (e is YandexGptException) rethrow;
      throw YandexGptException('Сетевая ошибка: $e');
    } finally {
      client.close();
    }
  }
}
