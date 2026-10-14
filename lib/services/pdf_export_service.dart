import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/conspect.dart';

class PdfExportService {
  /// Exports conspect to formatted PDF document and opens print/share dialog
  static Future<void> exportAndSharePdf(Conspect conspect) async {
    final pdf = pw.Document();

    // Load Cyrillic-compatible Google Font (Roboto)
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
            ),
          ),
          child: pw.Text(
            'Методист: ${conspect.methodName} — ${conspect.subject}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Страница ${context.pageNumber} из ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
          ),
        ),
        build: (context) => [
          // Title
          pw.Text(
            conspect.title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 8),

          // Meta Information Chips / Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Методика: ${conspect.methodName}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('Предмет: ${conspect.subject}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Возраст: ${conspect.ageGroup}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('Длительность: ${conspect.duration}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Main Markdown Content converted into clean paragraphs
          ..._buildContentWidgets(conspect.content, fontRegular, fontBold),
        ],
      ),
    );

    // Share/print the generated PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Конспект_${conspect.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static List<pw.Widget> _buildContentWidgets(
    String content,
    pw.Font regular,
    pw.Font bold,
  ) {
    final lines = content.split('\n');
    final List<pw.Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('# ')) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.indigo400, width: 1.5),
              ),
            ),
            child: pw.Text(
              trimmed.substring(2).trim(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              trimmed.substring(3).trim(),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(
                  child: pw.Text(
                    trimmed.substring(2).trim(),
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.3),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              trimmed,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
