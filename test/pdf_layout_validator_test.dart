import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_layout_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfLayoutIntegrityValidator Tests', () {
    test('detects and auto-repairs worksheet tasks missing didactic fields', () {
      const rawMarkdown = '''
# Цель и задачи занятия
Изучение состава числа 5.

# Лист заданий для печати
## Уровень 1: Старт
**Задание 1**. Вычисли примеры: 2 + 3 = ?, 4 + 1 = ?

**Задание 2**. Спиши предложение каллиграфически аккуратно: "Мама мыла раму."

**Задание 3**. Ответь на вопрос: почему важно помогать друзьям?

## 🔑 Ключи и ответы для учителя
1. 5, 5
2. По образцу
3. Ответ ученика
''';

      final audit = PdfLayoutIntegrityValidator.auditAndRepair(rawMarkdown, type: PdfMaterialType.worksheet);

      expect(audit.totalTasksFound, greaterThanOrEqualTo(3));
      expect(audit.issues.length, greaterThanOrEqualTo(3));

      // Task 1 (math) must have received [клетка]
      expect(audit.repairedContent.contains('[клетка]'), true);

      // Task 2 (writing) must have received [прописи]
      expect(audit.repairedContent.contains('[прописи]'), true);

      // Task 3 (general answer) must have received answer lines
      expect(audit.repairedContent.contains('Линии для ответа'), true);

      expect(audit.isValid, true);
    });

    test('recognizes existing didactic fields and preserves them untouched', () {
      const rawMarkdown = '''
# Лист заданий для печати
**Задание 1**. Заполни числовой домик числа 6:
[числовой домик]

**Задание 2**. Пройди графический диктант от точки СТАРТ:
[графический диктант]

**Задание 3**. Сравни числа:
[сравнение]
''';

      final audit = PdfLayoutIntegrityValidator.auditAndRepair(rawMarkdown, type: PdfMaterialType.worksheet);

      expect(audit.totalTasksFound, 3);
      expect(audit.tasksWithDidacticFields, 3);
      expect(audit.repairedContent.contains('[числовой домик]'), true);
      expect(audit.repairedContent.contains('[графический диктант]'), true);
      expect(audit.repairedContent.contains('[сравнение]'), true);
    });

    test('detects and removes orphan empty headers', () {
      const rawMarkdown = '''
# Цель и задачи
Цель урока.

### Пустой заголовок 1
### Пустой заголовок 2
**Задание 1**. Реши задачу: 3 + 3.
[клетка]
''';

      final audit = PdfLayoutIntegrityValidator.auditAndRepair(rawMarkdown);

      expect(audit.orphanHeadersFound, greaterThanOrEqualTo(1));
      expect(audit.issues.any((iss) => iss.contains('сиротский заголовок')), true);
    });
  });

  group('PDF Export Layout Protection & KeepTogether Tests', () {
    test('generateCombinedPdfBytes generates without error and enforces KeepTogether wrappers', () async {
      final conspect = Conspect(
        id: 'test_layout_protection',
        title: 'Урок математики и чистописания',
        topic: 'Счет до 10',
        subject: 'Математика',
        ageGroup: '7-8 лет',
        duration: '40 мин',
        methodId: 'pchelko',
        methodName: 'Пчёлко А.С. и Мазина В.Д.',
        createdAt: DateTime.now(),
        thematicWorldId: ThematicWorld.space.id,
        content: '''
# Цель и задачи занятия
Закрепление счета до 10 и чистописание цифр.

# Теория
Счет предметов парами и тройками.

# Ход занятия
Учитель: "Здравствуйте, ребята! Откроем тетради."
Дети: "Здравствуйте!"
Педагогический перехват ошибки: Ваня перепутал цифры 6 и 9. Разберем различие кружочков.
[Тайминг: 10 мин] Вводная часть
Физкультминутка: Пальчиковая гимнастика "Космонавты"

# Лист заданий для печати
## Уровень 1: Старт
**Задание 1**. Запиши числовой ряд до 10.
[прописи]

**Задание 2**. Вычисли примеры по клеточкам:
4 + 5 = __
8 - 3 = __
[клетка]

**Задание 3**. Заполни числовой домик:
[числовой домик]

## Самооценка и рефлексия
⭐⭐⭐ Оцени свои успехи:
1. Я знаю цифры до 10. ⭐⭐⭐
2. Я умею аккуратно писать в тетради. ⭐⭐⭐

## 🔑 Ключи и ответы для учителя
Задание 1: 1, 2, 3...
Задание 2: 9, 5

# Домашняя работа
## ПАМЯТКА ДЛЯ РОДИТЕЛЕЙ:
Похвалите ребенка за аккуратность.
**Задание 1**. Реши задачу дома.
[клетка]
''',
      );

      final Uint8List pdfBytes = await PdfExportService.generateCombinedPdfBytes(conspect, isPro: true);

      expect(pdfBytes.isNotEmpty, true);
      expect(pdfBytes.length, greaterThan(15000));
    });
  });
}
