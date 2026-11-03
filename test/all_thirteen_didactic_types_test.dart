import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete 13+ Didactic Field Types PDF Export Suite', () {
    test('Generate PDF containing all 5 newest didactic fields without error', () async {
      const sampleText = '''
# Лист заданий: Новейшие дидактические механики

**Задание 1: Составь предложение по схеме и укажи части слова**
[схема предложения] Составь красивое предложение про осенний лес.
Выдели в слове "перелесок" приставку, корень и суффикс.

**Задание 2: Пройди вычислительную цепочку и заполни пирамиду**
[цепочка] Реши цепочку примеров и разгадай числовую пирамиду сложения.

**Задание 3: Графический диктант по клеточкам**
[графический диктант] Следуй за стрелочками от точки СТАРТ и узнай, кто спрятался на рисунке.

**Задание 4: Распредели свойства в диаграмму Венна**
[диаграмма венна] Сравни домашних и диких животных.
Слова для распределения: собака, волк, корова, медведь, лиса, кошка.

**Задание 5: Составь кластер понятий: Времена года**
[кластер] Заполни древо понятий: запиши признаки и месяцы для каждого времени года.
''';

      final conspect = Conspect(
        id: 'test_five_newest_didactic_types',
        title: 'Тест 5 новейших типов дидактических полей',
        topic: 'Глубокая дидактика Pro',
        subject: 'Начальная школа',
        ageGroup: '1-4 класс',
        content: sampleText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        methodId: 'classical',
        methodName: 'Классическая методика',
        duration: '45 минут',
      );

      final pdfBytes = await PdfExportService.generateCombinedPdfBytes(conspect, isPro: true);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));

      final testOutDir = Directory('docs');
      if (!testOutDir.existsSync()) {
        testOutDir.createSync(recursive: true);
      }
      final outFile = File('docs/test_five_newest_didactic_types.pdf');
      await outFile.writeAsBytes(pdfBytes);
      expect(outFile.existsSync(), isTrue);
      print('SUCCESS: Generated PDF with 5 newest didactic fields (${pdfBytes.length} bytes)');
    });
  });
}
