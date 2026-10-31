import 'dart:math';

/// Результат оценки объема и токенов для генерации урока
class TokenEstimate {
  final int estimatedWords;
  final int estimatedTokens;
  final int modelContextLimit;
  final String modelName;
  final bool fitsInContext;
  final double contextUsagePercent;
  final bool requiresChunking;
  final String statusDescription;

  const TokenEstimate({
    required this.estimatedWords,
    required this.estimatedTokens,
    required this.modelContextLimit,
    required this.modelName,
    required this.fitsInContext,
    required this.contextUsagePercent,
    required this.requiresChunking,
    required this.statusDescription,
  });
}

/// Сервис токен-менеджмента, мониторинга контекста и адаптивного чанкинга
class LessonContextService {
  /// Лимиты контекста для поддерживаемых моделей (в токенах)
  static const Map<String, int> modelContextLimits = {
    // YandexGPT Pro (Foundation Models): стандартное окно генерации 8 000 токенов
    'yandexgpt': 8000,
    'yandexgpt-pro': 8000,
    'yandexgpt-lite': 4000,

    // OpenRouter модели
    'deepseek/deepseek-chat:free': 16000,
    'deepseek/deepseek-chat': 64000,
    'deepseek/deepseek-r1': 64000,
    'qwen/qwen-2.5-72b-instruct:free': 16000,
    'qwen/qwen-2.5-72b-instruct': 32000,
    'meta-llama/llama-3.3-70b-instruct': 32000,
    'google/gemini-2.0-flash-001': 1000000, // 1M контекст

    // Mistral модели
    'mistral-large-latest': 128000,
    'open-mistral-nemo': 32000,
    'mistral-small-latest': 32000,
    'codestral-latest': 32000,
  };

  /// Максимальный размер одного чанка вывода (в токенах) для безопасной генерации
  static const int safeChunkTokenSize = 3500;

  /// Оценка количества токенов для русскоязычного текста.
  /// В русском языке из-за кириллицы и морфологии токенизаторы (BPE, SentencePiece)
  /// в среднем разбивают 1 слово на 1.3 - 1.45 токена + знаки препинания.
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;
    
    // Подсчет слов
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    // Подсчет символов пунктуации и спецсимволов
    final punctuationCount = RegExp(r'[.,!?:;\-—"()«»\[\]{}1-90#*_\n]').allMatches(text).length;

    // Эвристическая формула: 1 русское слово ≈ 1.35 токена + 0.5 за знаки препинания
    final tokens = (words * 1.35 + punctuationCount * 0.45).ceil();
    return max(tokens, (text.length / 3.2).ceil());
  }

  /// Получение лимита контекста для модели
  static int getModelLimit(String modelName) {
    final cleanName = modelName.trim().toLowerCase();
    if (modelContextLimits.containsKey(cleanName)) {
      return modelContextLimits[cleanName]!;
    }
    // Проверка более специфичных ключей в первую очередь (по убыванию длины)
    final sortedKeys = modelContextLimits.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (cleanName.contains(key.toLowerCase())) {
        return modelContextLimits[key]!;
      }
    }
    // Лимит по умолчанию для неизвестных моделей
    return 8000;
  }

  /// Оценка параметров перед запуском генерации
  static TokenEstimate evaluateLessonParams({
    required String modelName,
    bool isDeepLesson = true,
    int variantsCount = 1,
    int customTargetWords = 0,
  }) {
    final int targetWords;
    if (customTargetWords > 0) {
      targetWords = customTargetWords;
    } else if (isDeepLesson) {
      targetWords = 2600; // Целевой объем глубокого развернутого урока: 2000-3000+ слов
    } else {
      targetWords = 950; // Стандартный компактный конспект
    }

    // Расчет токенов для одного варианта
    final int singleVariantTokens = (targetWords * 1.38).ceil();
    // Общий объем вывода с учетом количества вариантов
    final int totalTokens = singleVariantTokens * variantsCount;

    final int modelLimit = getModelLimit(modelName);
    final double usagePercent = (totalTokens / modelLimit) * 100.0;
    final bool fitsInContext = totalTokens <= modelLimit;
    final bool requiresChunking = totalTokens > safeChunkTokenSize && modelLimit <= 8000;

    String status;
    if (usagePercent <= 65) {
      status = 'Контекст в полной безопасности (${usagePercent.toStringAsFixed(0)}% лимита). Ответ помещается целиком.';
    } else if (fitsInContext) {
      status = 'Контекст загружен на ${usagePercent.toStringAsFixed(0)}%. Рекомендуется стандартный режим.';
    } else {
      status = 'Превышение контекста (${usagePercent.toStringAsFixed(0)}%). Будет задействована бесшовная чанк-генерация.';
    }

    return TokenEstimate(
      estimatedWords: targetWords * variantsCount,
      estimatedTokens: totalTokens,
      modelContextLimit: modelLimit,
      modelName: modelName,
      fitsInContext: fitsInContext,
      contextUsagePercent: usagePercent,
      requiresChunking: requiresChunking,
      statusDescription: status,
    );
  }

  /// Проверяет, укладывается ли текст в лимит модели
  static bool canFitInModelContext(String text, String modelName) {
    final tokens = estimateTokenCount(text);
    final limit = getModelLimit(modelName);
    return tokens <= limit;
  }

  /// Разбивает длинный методический комплекс на смысловые логические чанки,
  /// готовые для пошаговой генерации или раздельного экспорта.
  static List<String> splitIntoLogicalChunks(String fullContent) {
    if (fullContent.trim().isEmpty) return [];

    final List<String> chunks = [];
    final sections = fullContent.split(RegExp(r'\n(?=# )'));

    if (sections.length <= 1) {
      return [fullContent];
    }

    // Группировка 1: Сценарий урока (Цели, Теория, Ход занятия, Дифференциация)
    final scenarioBuffer = StringBuffer();
    // Группировка 2: Раздаточный рабочий лист
    final worksheetBuffer = StringBuffer();
    // Группировка 3: Домашнее задание и тесты/контроль
    final homeAndTestsBuffer = StringBuffer();

    for (final section in sections) {
      final trimmed = section.trim();
      if (trimmed.startsWith('# Лист заданий для печати') || trimmed.contains('Рабочий лист')) {
        worksheetBuffer.writeln(section);
      } else if (trimmed.startsWith('# Домашняя работа') ||
                 trimmed.startsWith('# Подсказка для родителя') ||
                 trimmed.contains('Контрольный срез') ||
                 trimmed.contains('Вопросы для проверки')) {
        homeAndTestsBuffer.writeln(section);
      } else {
        scenarioBuffer.writeln(section);
      }
    }

    if (scenarioBuffer.isNotEmpty) {
      chunks.add(scenarioBuffer.toString().trim());
    }
    if (worksheetBuffer.isNotEmpty) {
      chunks.add(worksheetBuffer.toString().trim());
    }
    if (homeAndTestsBuffer.isNotEmpty) {
      chunks.add(homeAndTestsBuffer.toString().trim());
    }

    return chunks.isNotEmpty ? chunks : [fullContent];
  }

  /// Сшивает чанки в единый чистый структурированный документ
  static String assembleChunks(List<String> chunks) {
    if (chunks.isEmpty) return '';
    if (chunks.length == 1) return chunks.first;

    final buffer = StringBuffer();
    for (int i = 0; i < chunks.length; i++) {
      final part = chunks[i].trim();
      if (part.isEmpty) continue;
      
      buffer.writeln(part);
      if (i < chunks.length - 1) {
        buffer.writeln('\n\n---\n\n');
      }
    }
    return buffer.toString().trim();
  }
}
