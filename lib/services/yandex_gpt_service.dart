import 'dart:async';
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

  static const String defaultModel = 'yandexgpt-lite';

  YandexGptService({required StorageService storageService})
      : _storageService = storageService;

  Future<Map<String, dynamic>> testConnection({
    String? apiKey,
    String? folderId,
  }) async {
    // Proxy URL is mandatory now
    final proxyUrl = await _storageService.getProxyUrl();
    if (proxyUrl == null || proxyUrl.trim().isEmpty) {
      return {
        'success': false,
        'message': 'URL прокси не указан. Укажите его в настройках.',
      };
    }

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(proxyUrl.trim()),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': [
                {'role': 'user', 'content': 'Тест связи'},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      // Detailed console diagnostics
      print('YandexGptService testConnection -> URL: $proxyUrl, status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Соединение с YandexGPT через прокси успешно установлено!',
        };
      }
      if (response.statusCode == 401) {
        print('Диагностика: Неверный API-ключ (401). Переменная YANDEX_API_KEY не задана или некорректна на сервере прокси.');
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Неверный API-ключ (или ключ не задан на сервере прокси).',
        };
      }
      if (response.statusCode == 403) {
        print('Диагностика: Нет доступа к модели (403).');
        return {
          'success': false,
          'statusCode': 403,
          'message': 'Нет доступа к модели или не включён Foundation Models в каталоге (403). Проверьте роль ai.languageModels.user.',
        };
      }
      if (response.statusCode == 429) {
        print('Диагностика: Превышен лимит запросов (429).');
        return {
          'success': false,
          'statusCode': 429,
          'message': 'Превышен лимит запросов (429). Попробуйте позже.',
        };
      }
      // Other status codes (e.g., 404, 500, 502) -> proxy is unavailable or server error
      print('Диагностика: Ответ API с ошибкой (${response.statusCode}): ${response.body}');
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Прокси недоступен или ошибка сервера (${response.statusCode}): ${response.body}',
      };
    } on TimeoutException {
      print('YandexGptService testConnection -> Таймаут запроса (30 секунд). URL: $proxyUrl');
      return {
        'success': false,
        'message': 'Превышено время ожидания ответа (30 секунд). Проверьте интернет-соединение и повторите.',
      };
    } catch (e) {
      print('YandexGptService testConnection -> URL: $proxyUrl');
      print('Ошибка: $e');
      print('Подсказка: Похоже, запрос заблокирован браузером (CORS) или сервер недоступен.');
      return {
        'success': false,
        'message': 'Запрос не дошёл до сервера. Проверьте интернет-соединение и повторите.',
      };
    } finally {
      client.close();
    }
  }

  /// Generates lesson plan conspect via the proxy server.
  Future<String> generateConspect({
    required String systemPrompt,
    required String userPrompt,
    String model = defaultModel,
  }) async {
    // Retrieve proxy URL from storage.
    final proxyUrl = await _storageService.getProxyUrl();
    if (proxyUrl == null || proxyUrl.trim().isEmpty) {
      throw YandexGptException('URL прокси не указан. Укажите его в настройках.');
    }

    final client = http.Client();
    try {
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.6,
        'max_tokens': 3000,
      });

      final response = await client
          .post(
            Uri.parse(proxyUrl.trim()),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      // Diagnostic logging.
      print('generateConspect -> URL: $proxyUrl, status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Try OpenAI‑compatible shape first.
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        // Fallback to native Foundation Models shape.
        final result = data['result'] as Map<String, dynamic>?;
        final alternatives = result?['alternatives'] as List<dynamic>?;
        if (alternatives != null && alternatives.isNotEmpty) {
          final text = alternatives.first['message']?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
        throw YandexGptException('Модель YandexGPT вернула пустой ответ. Попробуйте снова.');
      }

      print('generateConspect ошибка -> URL: $proxyUrl, status: ${response.statusCode}, body: ${response.body}');
      // Map known error codes to user‑friendly messages.
      switch (response.statusCode) {
        case 401:
          throw YandexGptException('Неверный API-ключ (401). Проверьте переменную окружения YANDEX_API_KEY на сервере прокси.', 401);
        case 403:
          throw YandexGptException('Нет доступа к модели или не включён Foundation Models в каталоге (403). Проверьте роль сервисного аккаунта.', 403);
        case 429:
          throw YandexGptException('Превышен лимит запросов (429). Попробуйте через минуту.', 429);
        default:
          throw YandexGptException('Ошибка генерации (${response.statusCode}): ${response.body}', response.statusCode);
      }
    } on TimeoutException {
      print('generateConspect -> Таймаут 30 секунд. URL: $proxyUrl');
      throw YandexGptException('Превышено время ожидания ответа (30 секунд). Проверьте интернет-соединение и повторите.');
    } catch (e) {
      if (e is YandexGptException) rethrow;
      print('generateConspect -> URL: $proxyUrl, ошибка: $e');
      print('Подсказка: Похоже, запрос заблокирован браузером (CORS) или сервер недоступен.');
      throw YandexGptException('Запрос не дошёл до сервера. Проверьте интернет-соединение и повторите.');
    } finally {
      client.close();
    }
  }
}
