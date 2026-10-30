import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_icons_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate Premium Math Worksheet PDF', () async {
    final mdContent = await File('docs/math_lesson_and_worksheet.md').readAsString();

    final conspect = Conspect(
      id: 'math_demo_01',
      title: 'Сложение и вычитание в пределах 10 на основе знания состава чисел',
      methodId: 'pchelko_math',
      methodName: 'А. С. Пчелко и Г. Б. Поляк',
      subject: 'Математика',
      ageGroup: '1 класс',
      topic: 'Сложение и вычитание в пределах 10 на основе знания состава чисел',
      duration: '45 мин',
      content: mdContent,
      createdAt: DateTime.now(),
    );

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
          fontFallback: [fontRegular, fontBold],
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
                'Математика (1 класс) • Методика: А. С. Пчелко и Г. Б. Поляк',
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
          PdfExportService.buildPdfTitleForTest(conspect, PdfMaterialType.worksheet, materialIcon, mascotImage: mascotImage),
          pw.SizedBox(height: 8),
          PdfExportService.buildMaterialInfoForTest(conspect, PdfMaterialType.worksheet),
          pw.SizedBox(height: 10),
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
    final outFile = File('docs/math_worksheet_premium.pdf');
    await outFile.writeAsBytes(pdfBytes);

    print('SUCCESS: Premium Math Worksheet PDF saved to ${outFile.path} (${pdfBytes.length} bytes)');
    expect(pdfBytes.length, greaterThan(10000));
  });
}
