import 'dart:convert';

/// Конфигурация Google Gemini API и встроенного Edge-прокси для обхода региональных ограничений
class GeminiConfig {
  static const String _defaultEncodedKey = 'QVEuQWI4Uk42TDNzU0tEa2FydndKbHFPdTdTODVsVmx5dG1PbkZWRjlXRHprWGh3c3NyaWc=';

  /// Ключ API Google Gemini (встроен по умолчанию, переопределяется через .env или Настройки)
  static String get apiKey {
    const envVar = String.fromEnvironment('GEMINI_API_KEY');
    if (envVar.isNotEmpty) return envVar;
    try {
      return utf8.decode(base64.decode(_defaultEncodedKey));
    } catch (_) {
      return '';
    }
  }

  /// URL встроенного Supabase Edge Function прокси (развёрнут в зоне без региональных ограничений)
  static const String defaultProxyUrl = 'https://pqeicvohoegcczvdxtiz.supabase.co/functions/v1/gemini-proxy';

  /// Модель Google Gemini по умолчанию
  static const String defaultModel = 'gemini-3.5-flash';

  /// Проверяет, задан ли ключ API
  static bool get isConfigured => apiKey.isNotEmpty;
}
