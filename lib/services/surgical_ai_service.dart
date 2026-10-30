import 'dart:async';
import '../models/conspect.dart';
import 'yandex_gpt_service.dart';

enum BlockAction {
  regenerate,
  makeHarder,
  makeEasier,
  changeTheme,
}

class SurgicalAiService {
  final YandexGptService _gptService;

  SurgicalAiService({required YandexGptService gptService}) : _gptService = gptService;

  /// Modifies or regenerates an isolated block/task of the conspect
  Future<String> modifyBlock({
    required Conspect conspect,
    required String blockText,
    required BlockAction action,
    String? customTheme,
  }) async {
    final actionInstruction = _getActionInstruction(action, customTheme);

    final systemPrompt = '''
Ты — ведущий советский методист высшей категории и эксперт развивающего обучения (по методике: ${conspect.methodName}).
Предмет: ${conspect.subject}.
Тема урока: "${conspect.topic}".
Возраст учеников: ${conspect.ageGroup}.

ТВОЯ ЗАДАЧА: Точечно переписать, адаптировать или заменить ПРЕДОСТАВЛЕННЫЙ БЛОК/ЗАДАНИЕ.

ТЕКУЩИЙ БЛОК:
"""
$blockText
"""

ДЕЙСТВИЕ:
$actionInstruction

ЖЕСТКИЕ ПРАВИЛА:
1. Выведи ТОЛЬКО обновленный текст блока в Markdown. Без мета-комментариев, без «Вот ваше задание:» или «Конечно!».
2. В заданиях для ученика КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО давать готовые ответы или подсказки в скобках. Должны быть прочерки (_____), пустые ячейки таблиц или линии для записи.
3. Если задание предполагает ответы, помести их строго в самый конец блока под заголовком:
   [Ключ для учителя: ...]
4. Сохраняй дидактический стиль методики (${conspect.methodName}) и глубину объяснения.
''';

    final userPrompt = 'Пожалуйста, выполни действие над блоком и верни строго готовый Markdown:';

    final result = await _gptService.generateConspect(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.5,
      maxTokens: 1500,
    );

    return result.trim();
  }

  String _getActionInstruction(BlockAction action, String? customTheme) {
    switch (action) {
      case BlockAction.regenerate:
        return 'Сгенерируй другое аналогичное задание или фрагмент того же типа, той же дидактической механики и того же уровня сложности, но с другими примерами, словами или сюжетом.';
      case BlockAction.makeHarder:
        return 'Сделай это задание сложнее (уровень «Детектив Pro» / олимпиада / ТРИЗ): убери шаблонные подсказки, добавь нестандартную логику, скрытую ловушку на внимание или многошаговое рассуждение, доступное для данного возраста.';
      case BlockAction.makeEasier:
        return 'Сделай это задание проще (уровень «Опора / ЗПР»): разбей на 2 понятных подшага, добавь наглядный образец решения («Образец: ...») и опорную схему/подсказку, сохранив суть правила.';
      case BlockAction.changeTheme:
        final theme = customTheme?.trim().isNotEmpty == true ? customTheme! : 'космическое путешествие или конструирование роботов';
        return 'Сохрани математическую или языковую суть задания, но полностью перепиши его сюжет и персонажей в тематике: "$theme". Сделай задание увлекательным и современным для ребенка.';
    }
  }
}
