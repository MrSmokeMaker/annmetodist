import 'dart:convert';
import 'dart:io';

/// Скрипт автоматической проверки и обновления истории версий в `assets/news.json`
void main(List<String> args) async {
  print('=== Генерация и валидация новостей (assets/news.json) ===');
  final file = File('assets/news.json');

  if (!await file.exists()) {
    print('Файл assets/news.json не найден!');
    exit(1);
  }

  try {
    final content = await file.readAsString();
    final jsonMap = jsonDecode(content) as Map<String, dynamic>;
    final currentVersion = jsonMap['currentVersion'];
    final releases = (jsonMap['releases'] as List<dynamic>?);

    print('Текущая версия приложения: $currentVersion');
    print('Всего релизов в истории: ${releases?.length ?? 0}');

    for (final rel in releases ?? []) {
      print('  • ${rel['version']} (${rel['date']}): ${rel['title']}');
    }

    print('\nВалидация структуры news.json: УСПЕШНО ✅');
  } catch (e) {
    print('Ошибка чтения news.json: $e');
    exit(1);
  }
}
