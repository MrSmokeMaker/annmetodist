import 'dart:convert';

/// Конфигурация Zveno AI API (российский агрегатор OpenAI-совместимых моделей)
class ZvenoConfig {
  static const String _defaultEncodedKey = 'c2stVUxsdmQ4YkY1LVgtdGs1ZkhleG5MTUV1akVpRjd0NXVwakxjODZhYTdzMA==';

  /// Ключ API Zveno AI (встроен по умолчанию, переопределяется через .env или Настройки)
  static String get apiKey {
    const envVar = String.fromEnvironment('ZVENO_API_KEY');
    if (envVar.isNotEmpty) return envVar;
    try {
      return utf8.decode(base64.decode(_defaultEncodedKey));
    } catch (_) {
      return '';
    }
  }

  /// Базовый адрес API Zveno AI
  static const String baseUrl = 'https://api.zveno.ai/v1';

  /// Текстовая модель по умолчанию (DeepSeek v3 — ультрадешевая, 1M контекст)
  static const String defaultModel = 'deepseek/deepseek-chat';

  /// Модель для генерации дидактических иллюстраций и раскрасок (Gemini Flash Image)
  static const String defaultImageModel = 'google/gemini-3.1-flash-image';

  /// Проверяет, задан ли ключ API
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Рекомендуемые дешевые текстовые модели для конспектов и рабочих листов
  static const Map<String, String> recommendedTextModels = {
    'deepseek/deepseek-chat': '🥇 DeepSeek V3 (ультрадешево, эталонный русский язык, 1M токенов)',
    'google/gemini-3.5-flash': '⚡ Gemini 3.5 Flash (быстрая, высокое качество, 1M токенов)',
    'google/gemini-2.5-flash': '✨ Gemini 2.5 Flash (проверенная, 1M токенов)',
    'qwen/qwen3.7-flash': '🧠 Qwen 3.7 Flash (топовая логика, педагогика и математика)',
    'qwen/qwen-2.5-72b-instruct': '📚 Qwen 2.5 72B Instruct (мощная открытая модель для сложных уроков)',
    'openai/gpt-4o-mini': '⭐ GPT-4o Mini (стабильное форматирование от OpenAI)',
  };

  /// Модели для генерации иллюстраций и раскрасок
  static const Map<String, String> recommendedImageModels = {
    'google/gemini-3.1-flash-image': '🖼️ Gemini Flash Image 3.1 (флагман для книжных иллюстраций и раскрасок)',
    'google/gemini-2.5-flash-image': '🎨 Gemini Flash Image 2.5 (быстрая генерация книжной графики)',
    'openai/gpt-5-image-mini': '✨ GPT-5 Image Mini (детальная векторная графика)',
  };
}
