import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'yandex_gpt_service.dart';
import 'lesson_context_service.dart';
import 'lesson_rubric_service.dart';

class AiServiceException implements Exception {
  final String message;
  final int? statusCode;

  AiServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AiService {
  final StorageService _storageService;
  final YandexGptService _yandexGptService;

  static const String openRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String mistralEndpoint = 'https://api.mistral.ai/v1/chat/completions';
  
  static const Map<String, String> availableOpenRouterModels = {
    'deepseek/deepseek-chat:free': 'DeepSeek V3 [Бесплатно 0\$] (Флагманская логика)',
    'qwen/qwen-2.5-72b-instruct:free': 'Qwen 2.5 72B [Бесплатно 0\$] (Эталон русского языка)',
    'qwen/qwen-2.5-72b-instruct': 'Qwen 2.5 72B Instruct (Открытая, эталон для русского языка)',
    'deepseek/deepseek-chat': 'DeepSeek V3 (Открытая модель 671B, глубокая логика)',
    'deepseek/deepseek-r1': 'DeepSeek R1 (Открытая модель рассуждений / CoT)',
    'meta-llama/llama-3.3-70b-instruct': 'Llama 3.3 70B Instruct (Meta)',
    'google/gemini-2.0-flash-001': 'Gemini 2.0 Flash (Сверхбыстрая и точная)',
  };

  static const Map<String, String> availableMistralModels = {
    'mistral-large-latest': 'Mistral Large 2 (Флагман: максимальная глубина и логика)',
    'open-mistral-nemo': 'Mistral NeMo 12B (Открытая модель NVIDIA + Mistral)',
    'mistral-small-latest': 'Mistral Small (Быстрая и экономичная)',
    'codestral-latest': 'Codestral (Структурированные данные и карточки)',
  };

  AiService({
    required StorageService storageService,
    required YandexGptService yandexGptService,
  })  : _storageService = storageService,
        _yandexGptService = yandexGptService;

  String get activeProvider => _storageService.getAiProvider();

  Future<void> setProvider(String provider) async {
    await _storageService.saveAiProvider(provider);
  }

  String get openRouterModel => _storageService.getOpenRouterModel();

  Future<void> setOpenRouterModel(String model) async {
    await _storageService.saveOpenRouterModel(model);
  }

  String? get openRouterApiKey => _storageService.getOpenRouterApiKey();

  Future<void> setOpenRouterApiKey(String apiKey) async {
    await _storageService.saveOpenRouterApiKey(apiKey);
  }

  String get mistralModel => _storageService.getMistralModel();

  Future<void> setMistralModel(String model) async {
    await _storageService.saveMistralModel(model);
  }

  String? get mistralApiKey => _storageService.getMistralApiKey();

  Future<void> setMistralApiKey(String apiKey) async {
    await _storageService.saveMistralApiKey(apiKey);
  }

  /// Тестирование подключения в зависимости от активного провайдера
  Future<Map<String, dynamic>> testConnection() async {
    final provider = activeProvider;
    if (provider == 'mistral') {
      return _testMistralConnection();
    } else if (provider == 'openrouter') {
      return _testOpenRouterConnection();
    } else {
      return _yandexGptService.testConnection();
    }
  }

  /// Тестирование Mistral AI
  Future<Map<String, dynamic>> _testMistralConnection() async {
    final apiKey = _storageService.getMistralApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return {
        'success': false,
        'message': 'API-ключ Mistral не указан. Введите ключ в настройках (console.mistral.ai).',
      };
    }

    final model = _storageService.getMistralModel();
    final client = http.Client();

    try {
      final response = await client.post(
        Uri.parse(mistralEndpoint),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Ответь одним словом: Готов.'},
          ],
          'max_tokens': 15,
        }),
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final modelName = availableMistralModels[model] ?? model;
        return {
          'success': true,
          'message': 'Успешное подключение к Mistral AI ($modelName)!',
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Неверный API-ключ Mistral AI (401). Проверьте ключ на console.mistral.ai.',
        };
      }

      if (response.statusCode == 429) {
        return {
          'success': false,
          'statusCode': 429,
          'message': 'Превышен лимит запросов Mistral AI (429). Попробуйте позже.',
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Ошибка Mistral AI (${response.statusCode}): ${response.body}',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Превышено время ожидания ответа от Mistral AI (35 секунд).',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения к Mistral AI: $e',
      };
    } finally {
      client.close();
    }
  }

  /// Тестирование OpenRouter
  Future<Map<String, dynamic>> _testOpenRouterConnection() async {
    final apiKey = _storageService.getOpenRouterApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return {
        'success': false,
        'message': 'API-ключ OpenRouter не указан. Введите ключ в настройках.',
      };
    }

    final model = _storageService.getOpenRouterModel();
    final client = http.Client();

    try {
      final response = await client.post(
        Uri.parse(openRouterEndpoint),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'HTTP-Referer': 'https://MrSmokeMaker.github.io/annmetodist/',
          'X-Title': 'Metodist Pedagogical Assistant',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Ответь одним словом: Связь установлена.'},
          ],
          'max_tokens': 20,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final modelName = availableOpenRouterModels[model] ?? model;
        return {
          'success': true,
          'message': 'Успешное соединение с OpenRouter ($modelName)!',
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Неверный API-ключ OpenRouter (401). Проверьте введённый ключ.',
        };
      }

      if (response.statusCode == 402) {
        return {
          'success': false,
          'statusCode': 402,
          'message': 'Недостаточно средств на балансе OpenRouter (402). Пополните баланс на openrouter.ai.',
        };
      }

      if (response.statusCode == 429) {
        return {
          'success': false,
          'statusCode': 429,
          'message': 'Превышен лимит запросов OpenRouter (429). Попробуйте позже.',
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Ошибка OpenRouter (${response.statusCode}): ${response.body}',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Превышено время ожидания ответа от OpenRouter (45 секунд).',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения к OpenRouter: $e',
      };
    } finally {
      client.close();
    }
  }

  /// Генерация глубокого развернутого урока (2000-3000+ слов)
  /// с автоматическим контролем контекста и адаптивной чанк-генерацией при необходимости.
  Future<String> generateDeepLesson({
    required String systemPrompt,
    required String userPrompt,
    String? yandexModel,
  }) async {
    final provider = activeProvider;
    final String activeModel = provider == 'openrouter'
        ? openRouterModel
        : (provider == 'mistral' ? mistralModel : (yandexModel ?? YandexGptService.defaultModel));

    final estimate = LessonContextService.evaluateLessonParams(
      modelName: activeModel,
      isDeepLesson: true,
      variantsCount: 1,
    );

    // Если модель поддерживает объем напрямую (YandexGPT Pro, Gemini Flash, Mistral Large)
    if (!estimate.requiresChunking || estimate.modelContextLimit >= 16000) {
      return generate(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        yandexModel: yandexModel,
      );
    }

    // Иначе выполняем адаптивную 2-фазную чанк-генерацию для гарантированного укладывания в лимит
    final part1Prompt = '$userPrompt\n\n[ЭТАП 1/2: Сгенерируй ТОЛЬКО Цели, Теорию и подробнейший развернутый Ход Занятия с репликами и таймингом. Не генерируй рабочий лист и домашку.]';
    final part1 = await generate(
      systemPrompt: systemPrompt,
      userPrompt: part1Prompt,
      yandexModel: yandexModel,
    );

    final part2Prompt = '$userPrompt\n\n[ЭТАП 2/2: На основе предыдущей части урока сгенерируй РАЗДАТОЧНЫЙ ЛИСТ (Уровни 1, 2, 3), ДОМАШНЮЮ РАБОТУ, а также 5 ТЕСТОВЫХ ВОПРОСОВ и 3 ОТКРЫТЫХ ВОПРОСА с ключами для учителя.]';
    final part2 = await generate(
      systemPrompt: systemPrompt,
      userPrompt: part2Prompt,
      yandexModel: yandexModel,
    );

    return LessonContextService.assembleChunks([part1, part2]);
  }

  /// Проводит методический аудит урока по 5 критериям ФГОС
  LessonRubricEvaluation runRubricCheck(
    String content, {
    required String topic,
    required String ageGroup,
    required String subject,
    String? methodName,
  }) {
    return LessonRubricService.evaluateLesson(
      content: content,
      topic: topic,
      ageGroup: ageGroup,
      subject: subject,
      methodName: methodName,
    );
  }

  /// Генерация конспекта/материалов через выбранный провайдер
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    String? yandexModel,
  }) async {
    final provider = activeProvider;

    if (provider == 'mistral') {
      return _generateMistral(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
    } else if (provider == 'openrouter') {
      return _generateOpenRouter(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
    } else {
      return _yandexGptService.generateConspect(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        model: yandexModel ?? YandexGptService.defaultModel,
      );
    }
  }

  /// Генерация через Mistral AI
  Future<String> _generateMistral({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final apiKey = _storageService.getMistralApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw AiServiceException('API-ключ Mistral AI не указан. Задайте его в Настройках приложения.');
    }

    final model = _storageService.getMistralModel();
    final client = http.Client();

    try {
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 4000,
      });

      final response = await client.post(
        Uri.parse(mistralEndpoint),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        throw AiServiceException('Модель Mistral вернула пустой ответ. Попробуйте еще раз.');
      }

      switch (response.statusCode) {
        case 401:
          throw AiServiceException('Неверный API-ключ Mistral AI (401). Проверьте ключ в настройках.', 401);
        case 429:
          throw AiServiceException('Превышен лимит запросов Mistral AI (429). Подождите минуту.', 429);
        default:
          throw AiServiceException('Ошибка Mistral AI (${response.statusCode}): ${response.body}', response.statusCode);
      }
    } on TimeoutException {
      throw AiServiceException('Превышено время ожидания ответа модели Mistral (120 сек).');
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Ошибка связи с Mistral AI: $e');
    } finally {
      client.close();
    }
  }

  /// Генерация через OpenRouter
  Future<String> _generateOpenRouter({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final apiKey = _storageService.getOpenRouterApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw AiServiceException('API-ключ OpenRouter не указан. Задайте его в Настройках приложения.');
    }

    final model = _storageService.getOpenRouterModel();
    final client = http.Client();

    try {
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.6,
        'max_tokens': 6000,
      });

      final response = await client.post(
        Uri.parse(openRouterEndpoint),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'HTTP-Referer': 'https://MrSmokeMaker.github.io/annmetodist/',
          'X-Title': 'Metodist Pedagogical Assistant',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 150));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        throw AiServiceException('Модель OpenRouter вернула пустой ответ. Попробуйте еще раз.');
      }

      switch (response.statusCode) {
        case 401:
          throw AiServiceException('Неверный API-ключ OpenRouter (401).', 401);
        case 402:
          throw AiServiceException('Недостаточно кредитов на аккаунте OpenRouter (402).', 402);
        case 429:
          throw AiServiceException('Превышен лимит запросов к OpenRouter (429). Подождите минуту.', 429);
        default:
          throw AiServiceException('Ошибка генерации OpenRouter (${response.statusCode}): ${response.body}', response.statusCode);
      }
    } on TimeoutException {
      throw AiServiceException('Превышено время ожидания ответа модели (120 сек). Попробуйте еще раз.');
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Ошибка связи с OpenRouter: $e');
    } finally {
      client.close();
    }
  }
}
