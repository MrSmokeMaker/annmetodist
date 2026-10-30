import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_icons_helper.dart';
import 'package:metodist/services/prompt_builder.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';
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

  test('Real YandexGPT Live Generation for Russian Worksheet Only with Premium PDF Export', () async {
    final storageService = StorageService();
    final gptService = YandexGptService(storageService: storageService);
    await storageService.saveProxyUrl('https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c');

    const topicTitle = 'Гласные и согласные звуки, слог и ударение';
    const ageGroup = '1 класс';
    const duration = '35 мин';
    const methodName = 'Н. А. Костин и В. Д. Мазина';

    // 1. Формируем промпт строго для ТОЛЬКО РАБОЧЕГО ЛИСТА
    final systemPrompt = PromptBuilder.buildSystemPrompt(
      methodBlock: 'Аналитико-синтетический звуковой метод Костина и чистописание Мазиной с образными элементами.',
      topic: topicTitle,
      ageGroup: ageGroup,
      duration: duration,
      materials: {GenerationType.worksheet},
    );

    final userPrompt = PromptBuilder.buildUserPrompt(
      methodName: methodName,
      topic: topicTitle,
      ageGroup: ageGroup,
      duration: duration,
      materials: {GenerationType.worksheet},
    );

    print('Requesting AI worksheet from YandexGPT (worksheet only)...');
    final generatedText = await gptService.generateConspect(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    print('Generated AI text length: ${generatedText.length}');

    // Применяем строгую фильтрацию контента по материалам (Пункт 1)
    final filteredContent = PromptBuilder.filterContentByMaterials(generatedText, ['worksheet']);

    // Проверяем, что нет плана урока и нет домашки
    expect(filteredContent.toLowerCase().contains('ход занятия'), isFalse,
        reason: 'Конспект хода урока не должен присутствовать при выборе только рабочего листа');
    expect(filteredContent.toLowerCase().contains('домашняя работа'), isFalse,
        reason: 'Домашняя работа не должна присутствовать при выборе только рабочего листа');

    // Сохраняем Markdown
    final mdFile = File(r'e:\My Projects\Metodist\docs\russian_worksheet.md');
    await mdFile.writeAsString(filteredContent);

    // 2. Создаем Conspect
    final conspect = Conspect(
      id: 'russian_live_worksheet',
      title: topicTitle,
      topic: topicTitle,
      methodId: 'kostin_russian',
      methodName: methodName,
      subject: 'Русский язык',
      ageGroup: ageGroup,
      duration: duration,
      content: filteredContent,
      generatedMaterials: ['worksheet'],
      createdAt: DateTime.now(),
    );

    // 3. Формируем премиум PDF
    final nunitoRegularBytes = File('Nunito-Regular.ttf').readAsBytesSync();
    final nunitoBoldBytes = File('Nunito-Bold.ttf').readAsBytesSync();
    final fontRegular = pw.Font.ttf(nunitoRegularBytes.buffer.asByteData());
    final fontBold = pw.Font.ttf(nunitoBoldBytes.buffer.asByteData());

    final materialIcon = await PdfIconsHelper.loadIcon('icon_worksheet');
    final mascotImage = await PdfIconsHelper.loadMascot();
    final starGold = await PdfIconsHelper.loadStarGold();
    final starGray = await PdfIconsHelper.loadStarGray();

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

    print('GENERATION_COMPLETED_SUCCESSFULLY: ${outputFile.path} (${pdfBytes.length} bytes)');
    expect(pdfBytes.length, greaterThan(15000));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
