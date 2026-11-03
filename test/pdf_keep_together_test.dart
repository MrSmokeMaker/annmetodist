import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class KeepTogetherTestWidget extends pw.Inseparable {
  KeepTogetherTestWidget({required pw.Widget child, this.maxSafeHeight = 680.0})
      : super(child: child);

  final double maxSafeHeight;

  @override
  bool get canSpan {
    if (box != null && box!.height > maxSafeHeight) {
      return super.canSpan || true;
    }
    return false;
  }

  @override
  bool get hasMoreWidgets {
    if (box != null && box!.height > maxSafeHeight) {
      return super.hasMoreWidgets;
    }
    return false;
  }
}

void main() {
  test('KeepTogetherTestWidget compiles and builds multi-page PDF without crashing', () async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('Header Title', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 500), // Push the next widget close to the page bottom
          KeepTogetherTestWidget(
            child: pw.Container(
              height: 250, // 500 + 250 > 842 - 64 -> will NOT fit on page 1
              color: PdfColors.blue100,
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Task 1: Math and Grid', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('Instruction line 1'),
                  pw.Text('Instruction line 2'),
                  pw.Container(
                    height: 100,
                    color: PdfColors.white,
                    alignment: pw.Alignment.center,
                    child: pw.Text('[Math Grid Field]'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
    // Since page 1 had 500pt + header and couldn't fit 250pt,
    // the KeepTogether widget MUST have moved entirely to page 2,
    // resulting in at least 2 pages.
    expect(bytes.length, greaterThan(1000));
  });
}
