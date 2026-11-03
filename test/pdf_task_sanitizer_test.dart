import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_icons_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Task Sanitization and Answer Field Tests', () {
    test('1. Verify task headers with asterisks, hashes, and hyphens are cleaned without **', () {
      final testCases = [
        ('**Задание 1: Соедини стрелками**', 1, 'Соедини стрелками'),
        ('- **Задание 2: Спиши текст каллиграфически.**', 2, 'Спиши текст каллиграфически.'),
        ('### Задание 3. Реши примеры по клеткам', 3, 'Реши примеры по клеткам'),
        ('#### Задание 4: Ловушка Незнайки', 4, 'Ловушка Незнайки'),
        ('1. Распредели слова по группам', 1, 'Распредели слова по группам'),
        ('2. Звуковой анализ слова', 2, 'Звуковой анализ слова'),
      ];

      for (final (raw, expectedNum, expectedTitle) in testCases) {
        final result = PdfExportService.sanitizeTaskHeader(raw);
        expect(result.isTask, isTrue, reason: 'Failed for: $raw');
        expect(result.number, equals(expectedNum), reason: 'Wrong number for: $raw');
        expect(result.title, equals(expectedTitle), reason: 'Wrong title for: $raw');
        expect(result.title.contains('**'), isFalse, reason: 'Asterisks remaining in: ${result.title}');
        expect(result.title.startsWith('#'), isFalse, reason: 'Hash remaining in: ${result.title}');
        expect(result.title.startsWith('-'), isFalse, reason: 'Hyphen remaining in: ${result.title}');
      }
    });

    test('2. Generate PDF with various task types and verify no exceptions', () async {
      final sampleContent = '''
# Лист заданий для урока

**Задание 1: Соедини стрелками**
Соедини пары слов:
Кот - Мяукает
Собака - Лает
Корова - Мычит

- **Задание 2: Спиши аккуратно по образцу**
[прописи] Спиши предложение в узкую косую линейку под углом 65 градусов:
На дворе трава, на траве дрова.

### Задание 3: Реши примеры в клетку
[клетка] Запиши решение столбиком:
15 + 27 = ___
42 - 18 = ___

#### Задание 4: Ловушка Незнайки
Незнайка написал: "жыраф бежыт па паляне".
Исправь ошибки Незнайки!

**Задание 5: Распредели слова по группам**
Слова: дом, река, стол, береза
Группа 1: Одушевленные
Группа 2: Неодушевленные

**Задание 6: Звуковой анализ слова**
Выполни звуковой анализ слова: ШКОЛА
''';

      final conspect = Conspect(
        id: 'test_task_types_id',
        title: 'Урок русского языка и математики',
        topic: 'Комплексный урок',
        subject: 'Начальная школа',
        ageGroup: '1-4 класс',
        content: sampleContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thematicWorldId: 'forest',
        methodId: 'classical',
        methodName: 'Классический урок',
        duration: '45 минут',
      );

      // Verify combined PDF bytes generation with Pro enabled
      final pdfBytes = await PdfExportService.generateCombinedPdfBytes(conspect, isPro: true);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('3. Verify bundled coloring pages, medals, mascots, and banners load successfully', () async {
      final mascot = await PdfIconsHelper.loadWorldMascot('space');
      expect(mascot, isNotNull);

      final banner = await PdfIconsHelper.loadWorldBanner('forest');
      expect(banner, isNotNull);

      final medal = await PdfIconsHelper.loadMedal();
      expect(medal, isNotNull);

      final coloring = await PdfIconsHelper.loadColoring('detective');
      expect(coloring, isNotNull);
    });
  });
}
