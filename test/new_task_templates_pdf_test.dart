import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Task Templates PDF Export Tests', () {
    test('1. Generate PDF containing all 8 new task templates without errors', () async {
      final sampleContent = '''
# Лист заданий: Все 8 новых дидактических типов

**Задание 1: Засели числовой домик числа 8**
[числовой домик] Домик числа 8. Заполни пустые окошки на каждом этаже:
1 и ___
2 и ___
3 и ___

**Задание 2: Сравни выражения: поставь знаки > < =**
[сравнение] Сравни пары выражений:
7 + 3 ... 12 - 4
15 - 8 ... 9 + 1
6 * 2 ... 10 + 2

**Задание 3: Вставь буквы в орфографические окошки**
[окошки] Вставь пропущенные безударные гласные:
м..локо, к..рова, с..бака, б..рёза

**Задание 4: Разгадай секретный шифр (Детектив Pro)**
[шифр] Таблица дешифратора:
1=А, 2=Б, 3=В, 4=Г, 5=Д, 6=Е
Секретная цепочка: 5 - 1 - 3

**Задание 5: Выполни вычисление по числовому лучу**
[числовой луч] Отметь шаги дугами по числовому лучу:
4 + 3 = ___

**Задание 6: ТРИЗ-анализ противоречия: Хорошо — Плохо**
[хорошо-плохо] Проанализируй объект "Зонтик":
Что в нём хорошо, а что плохо?

**Задание 7: Тестовый выбор правильного ответа**
[выбор] Сколько звуков в слове "ЕЛЬ"?
- 2 звука
- 3 звука
- 4 звука

**Задание 8: Сосчитай предметы YandexART**
[предметный счет] На рисунке изображены спелые яблоки в ряд.
Сколько яблок на рисунке?
''';

      final conspect = Conspect(
        id: 'test_all_8_new_types',
        title: 'Тест 8 новых типов заданий',
        topic: 'Комплексный тест дидактики',
        subject: 'Начальная школа',
        ageGroup: '1-4 класс',
        content: sampleContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thematicWorldId: 'detective',
        methodId: 'classical',
        methodName: 'Классический урок',
        duration: '45 минут',
      );

      final pdfBytes = await PdfExportService.generateCombinedPdfBytes(conspect, isPro: true);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
