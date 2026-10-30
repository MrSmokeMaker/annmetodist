import 'dart:io';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';

void main() async {
  print('Starting full lesson generation...');
  final storageService = StorageService();
  final gptService = YandexGptService(storageService: storageService);
  await storageService.saveProxyUrl('https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c');

  const systemPrompt = '''
Ты — ведущий методист-практик начального образования и дошкольной педагогики высшей квалификационной категории.
Составь детальный конспект занятия и раздаточный рабочий лист по всем правилам ФГОС.
Обязательно включи:
1. Паспорт урока (предмет, тема, класс, цель, задачи, оборудование).
2. Сквозную игровую сюжетную канву.
3. Пошаговый сценарий с диалогами учителя и детей и таймингом.
4. Разминку / физкультминутку.
5. Раздаточный рабочий лист с упражнениями (Соедини стрелками, Ловушка Незнайки, Шифровка).
6. Домашнее задание с уровнями сложности и напутствием родителям.
''';

  const userPrompt = '''
Предмет: Окружающий мир и основы астрономии
Тема: Путешествие к планетам Солнечной системы: почему Земля особенная?
Класс: 1 класс (начальная школа)
Длительность: 35 минут
Методика: Исследовательско-игровой подход с элементами ТРИЗ
''';

  try {
    final result = await gptService.generateConspect(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    final outputPath = r'e:\My Projects\Metodist\docs\sample_generated_lesson.md';
    final file = File(outputPath);
    await file.writeAsString(result);

    print('GENERATION_SUCCESS: File written to $outputPath');
    print('Length: ${result.length} characters');
  } catch (e, st) {
    print('GENERATION_ERROR: $e\n$st');
    exit(1);
  }
}
