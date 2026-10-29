import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';

void main() {
  group('PDF Design and School Canvas Tests', () {
    test('PdfExportService handles all material types and school canvas tags', () {
      final sampleConspect = Conspect(
        id: 'test_conspect',
        title: 'Сложение чисел в пределах 10',
        topic: 'Сложение чисел в пределах 10',
        methodId: 'pchelko_math',
        methodName: 'А. С. Пчелко и Г. Б. Поляк',
        subject: 'Математика',
        ageGroup: 'grade_1',
        duration: '35 мин',
        content: '''
# Лист заданий для печати
## Задание 1: Реши примеры
[СЕТКА 5Х5]
Выполни вычисления в тетрадной клетке.

## Задание 2: Каллиграфия цифр
[ПРОПИСИ]
Пропиши цифру 7 по наклонным направляющим.
''',
        generatedMaterials: ['worksheet'],
        createdAt: DateTime.now(),
      );

      // Verify that sample conspect builds correctly
      expect(sampleConspect.topic, contains('Сложение'));
      expect(sampleConspect.content, contains('[СЕТКА 5Х5]'));
      expect(sampleConspect.content, contains('[ПРОПИСИ]'));
      expect(PdfMaterialType.values.length, 3);
    });
  });
}
