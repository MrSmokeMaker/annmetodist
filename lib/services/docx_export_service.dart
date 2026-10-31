import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/conspect.dart';

class DocxExportService {
  /// Exports a conspect into a Microsoft Word (.docx) file
  static Future<void> exportConspectToDocx(Conspect conspect) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, utf8.encode(docRelsXml)));

    // 4. word/styles.xml
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="24"/>
        <w:lang w:val="ru-RU"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
    archive.addFile(ArchiveFile('word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    final docxBytes = generateDocxBytes(conspect);
    final safeTitle = conspect.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final fileName = '$safeTitle.docx';

    await Share.shareXFiles(
      [
        XFile.fromData(
          docxBytes,
          name: fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      ],
      subject: conspect.title,
    );
  }

  /// Generates the raw bytes of a DOCX file for the given conspect
  static Uint8List generateDocxBytes(Conspect conspect) {
    final archive = Archive();

    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));

    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, utf8.encode(docRelsXml)));

    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="24"/>
        <w:lang w:val="ru-RU"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
    archive.addFile(ArchiveFile('word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    final docBody = _buildDocumentXml(conspect);
    archive.addFile(ArchiveFile('word/document.xml', docBody.length, utf8.encode(docBody)));

    final encoder = ZipEncoder();
    final encodedData = encoder.encode(archive);
    return Uint8List.fromList(encodedData ?? []);
  }

  static String _buildDocumentXml(Conspect conspect) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buffer.write('<w:body>');

    // Header info table / card
    buffer.write(_p(conspect.title, isTitle: true));
    buffer.write(_p('Предмет: ${conspect.subject} | Методика: ${conspect.methodName}', isSubtitle: true));
    buffer.write(_p('Возраст: ${conspect.ageGroup} | Длительность: ${conspect.duration}', isSubtitle: true));
    buffer.write(_emptyP());

    // Content lines
    final lines = conspect.content.split('\n');
    bool inTable = false;
    final List<List<String>> tableRows = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('|') && line.endsWith('|')) {
        // Table line
        if (line.contains('---') || line.contains(':---')) {
          continue; // separator
        }
        final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        tableRows.add(cells);
        inTable = true;
        continue;
      } else if (inTable) {
        // End of table
        buffer.write(_renderTableXml(tableRows));
        tableRows.clear();
        inTable = false;
      }

      if (line.isEmpty) {
        buffer.write(_emptyP());
      } else if (line.startsWith('# ')) {
        buffer.write(_p(line.substring(2).trim(), isH1: true));
      } else if (line.startsWith('## ')) {
        buffer.write(_p(line.substring(3).trim(), isH2: true));
      } else if (line.startsWith('### ')) {
        buffer.write(_p(line.substring(4).trim(), isH3: true));
      } else if (line.startsWith('#### ')) {
        buffer.write(_p(line.substring(5).trim(), isH4: true));
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        buffer.write(_p('• ${line.substring(2).trim()}', isBullet: true));
      } else {
        buffer.write(_p(line));
      }
    }

    if (inTable && tableRows.isNotEmpty) {
      buffer.write(_renderTableXml(tableRows));
    }

    buffer.write('</w:body></w:document>');
    return buffer.toString();
  }

  static String _p(String text, {
    bool isTitle = false,
    bool isSubtitle = false,
    bool isH1 = false,
    bool isH2 = false,
    bool isH3 = false,
    bool isH4 = false,
    bool isBullet = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('<w:p><w:pPr>');

    if (isTitle) {
      buffer.write('<w:jc w:val="center"/>');
      buffer.write('<w:spacing w:before="240" w:after="120"/>');
    } else if (isSubtitle) {
      buffer.write('<w:jc w:val="center"/>');
      buffer.write('<w:spacing w:after="60"/>');
    } else if (isH1) {
      buffer.write('<w:spacing w:before="360" w:after="160"/>');
    } else if (isH2) {
      buffer.write('<w:spacing w:before="280" w:after="120"/>');
    } else if (isH3 || isH4) {
      buffer.write('<w:spacing w:before="200" w:after="80"/>');
    } else {
      buffer.write('<w:spacing w:after="120" w:line="276" w:lineRule="auto"/>');
    }

    if (isBullet) {
      buffer.write('<w:ind w:left="400"/>');
    }

    buffer.write('</w:pPr>');

    // Formatting runs
    final runs = _parseFormattedRuns(text);
    for (final run in runs) {
      buffer.write('<w:r><w:rPr>');
      if (isTitle) {
        buffer.write('<w:b/><w:sz w:val="36"/><w:color w:val="1E3A8A"/>');
      } else if (isSubtitle) {
        buffer.write('<w:i/><w:sz w:val="20"/><w:color w:val="64748B"/>');
      } else if (isH1) {
        buffer.write('<w:b/><w:sz w:val="30"/><w:color w:val="1E40AF"/>');
      } else if (isH2) {
        buffer.write('<w:b/><w:sz w:val="26"/><w:color w:val="334155"/>');
      } else if (isH3 || isH4) {
        buffer.write('<w:b/><w:sz w:val="24"/><w:color w:val="475569"/>');
      } else {
        buffer.write('<w:sz w:val="24"/>');
        if (run.isBold) buffer.write('<w:b/>');
        if (run.isItalic) buffer.write('<w:i/>');
      }
      buffer.write('</w:rPr>');
      buffer.write('<w:t xml:space="preserve">${_xmlEscape(run.text)}</w:t></w:r>');
    }

    buffer.write('</w:p>');
    return buffer.toString();
  }

  static String _emptyP() => '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr></w:p>';

  static String _renderTableXml(List<List<String>> rows) {
    final buffer = StringBuffer();
    buffer.write('<w:tbl>');
    buffer.write('<w:tblPr>');
    buffer.write('<w:tblW w:w="5000" w:type="pct"/>');
    buffer.write('<w:tblBorders>');
    buffer.write('<w:top w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>');
    buffer.write('<w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>');
    buffer.write('<w:left w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>');
    buffer.write('<w:right w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>');
    buffer.write('<w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>');
    buffer.write('<w:insideV w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>');
    buffer.write('</w:tblBorders>');
    buffer.write('</w:tblPr>');

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final isHeader = r == 0;
      buffer.write('<w:tr>');
      for (final cell in row) {
        buffer.write('<w:tc>');
        buffer.write('<w:tcPr>');
        if (isHeader) {
          buffer.write('<w:shd w:val="clear" w:color="auto" w:fill="F1F5F9"/>');
        }
        buffer.write('</w:tcPr>');
        buffer.write(_p(cell, isH4: isHeader));
        buffer.write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static List<_TextRun> _parseFormattedRuns(String text) {
    final runs = <_TextRun>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      runs.add(_TextRun(text: parts[i], isBold: isBold));
    }
    if (runs.isEmpty) {
      runs.add(_TextRun(text: text));
    }
    return runs;
  }
}

class _TextRun {
  final String text;
  final bool isBold;
  final bool isItalic;

  _TextRun({required this.text, this.isBold = false, this.isItalic = false});
}
