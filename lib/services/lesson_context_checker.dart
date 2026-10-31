// Данный файл предоставляет утилиты для оценки количества токенов в тексте
// и проверки, помещается ли генерируемый урок в контекст модели.

/// Простейший эвристический подсчёт количества токенов.
/// Для большинства языковых моделей один токен примерно соответствует 0.75 слова.
int estimateTokenCount(String text) {
  // Разбиваем по пробелам и переносам строк, фильтруем пустые токены.
  final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  // Приблизительно 1 токен на 0.75 слова -> tokens = words / 0.75 = words * 4/3.
  return ((wordCount * 4) / 3).ceil();
}

/// Карта предельных размеров контекста (в токенах) для поддерживаемых моделей.
const Map<String, int> modelContextLimits = {
  // Gemini Flash 2.0 – ~8 000 токенов
  'google/gemini-2.0-flash-001': 8000,
  // Gemini Flash Lite – ~4 000 токенов (пример для небольших моделей)
  'google/gemini-2.0-flash-lite-001': 4000,
  // Пример модели Mistral Small – 4 000 токенов
  'mistral-small-latest': 4000,
  // Другие модели могут быть добавлены по мере необходимости.
};

/// Проверяет, помещается ли данный текст в контекст указанной модели.
/// Возвращает `true`, если количество токенов не превышает лимит модели.
bool canFitInModelContext(String text, String modelName) {
  final limit = modelContextLimits[modelName];
  if (limit == null) {
    // Если лимит неизвестен, считаем, что текст помещается.
    return true;
  }
  final tokens = estimateTokenCount(text);
  return tokens <= limit;
}

// Пример использования в коде приложения:
//
// final lessonText = await generateLesson(...);
// final model = AiService().activeProvider == 'openrouter'
//     ? AiService().openRouterModel
//     : 'google/gemini-2.0-flash-001';
// if (!canFitInModelContext(lessonText, model)) {
//   // Показать пользователю предупреждение и/или разбить урок на части.
// }
