import 'dart:io';

/// Конфигурация Google Gemini API и встроенного Edge-прокси для обхода региональных ограничений
class GeminiConfig {
  static String? _cachedKey;

  /// Ключ API Google Gemini (динамически загружается из .env или environment)
  static String get apiKey {
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey!;
    const envVar = String.fromEnvironment('GEMINI_API_KEY');
    if (envVar.isNotEmpty) {
      _cachedKey = envVar;
      return _cachedKey!;
    }
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        for (final line in envFile.readAsLinesSync()) {
          final trimmed = line.trim();
          if (trimmed.startsWith('GEMINI_API_KEY=')) {
            _cachedKey = trimmed.substring('GEMINI_API_KEY='.length).trim();
            return _cachedKey!;
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// URL встроенного Supabase Edge Function прокси (развёрнут в зоне без региональных ограничений)
  static const String defaultProxyUrl = 'https://pqeicvohoegcczvdxtiz.supabase.co/functions/v1/gemini-proxy';

  /// Модель Google Gemini по умолчанию
  static const String defaultModel = 'gemini-3.5-flash';

  /// Проверяет, задан ли ключ API
  static bool get isConfigured => apiKey.isNotEmpty;
}
