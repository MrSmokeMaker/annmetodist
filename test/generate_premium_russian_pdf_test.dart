import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_icons_helper.dart';
import 'package:metodist/services/prompt_builder.dart';
import 'package:metodist/constants.dart';

class _AllowRealNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealNetworkHttpOverrides();

  test('Premium Russian Worksheet PDF Generation with Mascot and Star Rating', () async {
    // 1. Проверяем строгую фильтрацию материалов (Пункт 1)
    const rawMultiContent = '''
# Цель и задачи занятия
Формирование представлений о звуках и буквах.

# Ход занятия
Учитель: "Здравствуйте, ребята!"
Дети: "Здравствуйте!"

# Дифференциация и индивидуальный маршрут
Индивидуальные карточки.

# Лист заданий для печати
## 1. Каллиграфическая минутка [ПРОПИСИ]
Пропиши элементы букв: качалочка и крючок.

## 2. Ловушка Незнайки
Найди ошибки в ударении:
1. пЕчка
2. заЯц

## 3. Раздели на слоги и поставь знак ударения
1. ли-са
2. ба-ра-бан
3. кни-га
4. яб-ло-ко
5. мо-роз

## ⭐⭐⭐ Оцени свои успехи
Аккуратность, правильность, самостоятельность.

# Домашняя работа
## Памятка для родителей
Помогите ребенку без давления.
''';

    // Тест 1: выбор только конспекта
    final onlyConspect = PromptBuilder.filterContentByMaterials(rawMultiContent, ['conspect']);
    expect(onlyConspect.contains('# Лист заданий'), isFalse);
    expect(onlyConspect.contains('# Домашняя работа'), isFalse);
    expect(onlyConspect.contains('# Цель и задачи'), isTrue);

    // Тест 2: выбор только рабочего листа
    final onlyWorksheet = PromptBuilder.filterContentByMaterials(rawMultiContent, ['worksheet']);
    expect(onlyWorksheet.contains('# Цель и задачи'), isFalse);
    expect(onlyWorksheet.contains('# Домашняя работа'), isFalse);
    expect(onlyWorksheet.contains('# Лист заданий для печати'), isTrue);

    // 2. Создаем Conspect для рендеринга PDF с русским языком
    final conspect = Conspect(
      id: 'russian_test_01',
      title: 'Гласные и согласные звуки, слог и ударение',
      topic: 'Гласные и согласные звуки, слог и ударение',
      methodId: 'kostin_russian',
      methodName: 'Н. А. Костин и В. Д. Мазина',
      subject: 'Русский язык',
      ageGroup: '1 класс',
      duration: '35 мин',
      content: '''
# Лист заданий для печати: Русский язык (1 класс)

## 1. Каллиграфическая минутка [ПРОПИСИ]
Напиши аккуратно по образцу элементы букв (качалочка, крючок до середины строки).
Образец перед строкой: продолжить непрерывным движением с правильным наклоном 65 градусов.

## 2. Раздели слова на слоги и поставь знак ударения
Раздели слова на слоги черточкой и выдели ударный гласный звук:
1. ли-са
2. ба-ра-бан
3. кни-га
4. яб-ло-ко
5. мо-роз

## 3. Соедини стрелками слова и звуковые схемы [СОЕДИНИ СТРЕЛКАМИ]
Соедини линиями слово с его верной звуковой моделью:
1. мак — [согласный твердый, гласный, согласный твердый]
2. роза — [согласный твердый, гласный, согласный твердый, гласный]
3. аист — [гласный, гласный, согласный твердый, согласный твердый]

## 4. Ловушка Незнайки: найди ошибки!
Незнайка неправильно поставил ударение в словах. Исправь его ошибки:
1. пЕчка — ударение падает на первый слог.
2. заЯц — ударение падает на второй слог.
3. Аист — ударение падает на первый слог.

## 5. Творческая мастерская юного грамотея
Составь и запиши красивое предложение со словом «Родина»:
Линии для ответа: __________________________________________________________________

## ⭐⭐⭐ Оцени свои успехи (Самооценка)
Оцени свою работу на уроке по шкале успеха.
''',
      generatedMaterials: ['worksheet'],
      createdAt: DateTime.now(),
    );

    // 3. Загружаем Cyrillic шрифты Nunito
    final nunitoRegularBytes = File('Nunito-Regular.ttf').readAsBytesSync();
    final nunitoBoldBytes = File('Nunito-Bold.ttf').readAsBytesSync();
    final fontRegular = pw.Font.ttf(nunitoRegularBytes.buffer.asByteData());
    final fontBold = pw.Font.ttf(nunitoBoldBytes.buffer.asByteData());

    final materialIcon = await PdfIconsHelper.loadIcon('icon_worksheet');
    final mascotImage = await PdfIconsHelper.loadMascot();
    final starGold = await PdfIconsHelper.loadStarGold();
    final starGray = await PdfIconsHelper.loadStarGray();

    expect(mascotImage, isNotNull, reason: 'Маскот Сова-Методист должен успешно загрузиться из assets');
    expect(starGold, isNotNull, reason: 'Золотая звездочка должна успешно загрузиться из assets');

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontRegular,
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.indigo200, width: 0.8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.indigo300, width: 0.5),
                ),
                child: pw.Text(
                  'МЕТОДИСТ PRO • ФГОС',
                  style: pw.TextStyle(font: fontBold, color: PdfColors.indigo900, fontSize: 7.5),
                ),
              ),
              pw.Text(
                'Русский язык (1 класс) • Методика: Н. А. Костин и В. Д. Мазина',
                style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700, fontSize: 8.5),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Методист Pro • Премиум материалы для печати', style: pw.TextStyle(font: fontBold, color: PdfColors.indigo700, fontSize: 8)),
              pw.Text(
                'Страница ${context.pageNumber} из ${context.pagesCount}',
                style: pw.TextStyle(font: fontRegular, color: PdfColors.grey600, fontSize: 8.5),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Премиум шапка с маскотом
          PdfExportService.buildPdfTitleForTest(conspect, PdfMaterialType.worksheet, materialIcon, mascotImage: mascotImage),
          pw.SizedBox(height: 8),

          // Поля данных ученика
          PdfExportService.buildMaterialInfoForTest(conspect, PdfMaterialType.worksheet),
          pw.SizedBox(height: 10),

          // Основной контент: неделимые карточки заданий
          ...PdfExportService.buildContentWidgetsForTest(
            conspect.content,
            fontRegular,
            fontBold,
            {},
            starGold: starGold,
            starGray: starGray,
            isWorksheetOrHomework: true,
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final outputFile = File(r'e:\My Projects\Metodist\docs\russian_worksheet_premium.pdf');
    await outputFile.writeAsBytes(pdfBytes);

    print('SUCCESS: Premium Russian Worksheet PDF saved to ${outputFile.path} (${pdfBytes.length} bytes)');
    expect(pdfBytes.length, greaterThan(10000));
  });
}
