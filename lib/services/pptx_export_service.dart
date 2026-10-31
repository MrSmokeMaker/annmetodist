import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import '../models/lesson_presentation.dart';

class PptxExportService {
  /// Generates the raw bytes of a valid Microsoft PowerPoint (.pptx) file
  static Uint8List generatePptxBytes(LessonPresentation presentation) {
    final archive = Archive();
    final slideCount = presentation.slides.isNotEmpty ? presentation.slides.length : 1;

    // 1. [Content_Types].xml
    final contentTypesXml = _buildContentTypesXml(slideCount);
    archive.addFile(
      ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)),
    );

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsXml.length, utf8.encode(rootRelsXml)));

    // 3. docProps/core.xml & app.xml
    final coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_xmlEscape(presentation.title)}</dc:title>
  <dc:creator>Методист Pro (Тариф Разработчик)</dc:creator>
  <cp:lastModifiedBy>Методист AI</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">${DateTime.now().toIso8601String()}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${DateTime.now().toIso8601String()}</dcterms:modified>
</cp:coreProperties>''';
    archive.addFile(ArchiveFile('docProps/core.xml', coreXml.length, utf8.encode(coreXml)));

    final appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <TotalTime>0</TotalTime>
  <Words>350</Words>
  <Application>Microsoft PowerPoint</Application>
  <PresentationFormat>On-screen Show (16:9)</PresentationFormat>
  <Slides>$slideCount</Slides>
</Properties>''';
    archive.addFile(ArchiveFile('docProps/app.xml', appXml.length, utf8.encode(appXml)));

    // 4. ppt/presentation.xml
    final presentationXml = _buildPresentationXml(slideCount);
    archive.addFile(
      ArchiveFile('ppt/presentation.xml', presentationXml.length, utf8.encode(presentationXml)),
    );

    // 5. ppt/_rels/presentation.xml.rels
    final presentationRelsXml = _buildPresentationRelsXml(slideCount);
    archive.addFile(
      ArchiveFile(
        'ppt/_rels/presentation.xml.rels',
        presentationRelsXml.length,
        utf8.encode(presentationRelsXml),
      ),
    );

    // 6. Slides
    for (int i = 0; i < slideCount; i++) {
      final slideNum = i + 1;
      final slide = presentation.slides.length > i
          ? presentation.slides[i]
          : PresentationSlide(
              slideNumber: slideNum,
              layoutType: SlideLayoutType.conceptBreakdown,
              title: presentation.title,
            );

      final slideXml = _buildSlideXml(slide, presentation);
      archive.addFile(
        ArchiveFile(
          'ppt/slides/slide$slideNum.xml',
          slideXml.length,
          utf8.encode(slideXml),
        ),
      );

      final slideRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
      archive.addFile(
        ArchiveFile(
          'ppt/slides/_rels/slide$slideNum.xml.rels',
          slideRelsXml.length,
          utf8.encode(slideRelsXml),
        ),
      );
    }

    final encoder = ZipEncoder();
    final encodedData = encoder.encode(archive);
    return Uint8List.fromList(encodedData ?? []);
  }

  /// Exports presentation into a .pptx file and opens share sheet
  static Future<void> exportPresentation(LessonPresentation presentation) async {
    final bytes = generatePptxBytes(presentation);
    final safeTitle = presentation.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final fileName = '$safeTitle.pptx';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        ),
      ],
      subject: 'Презентация урока: ${presentation.title}',
    );
  }

  static String _buildContentTypesXml(int slideCount) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
    buffer.writeln('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
    buffer.writeln('  <Default Extension="xml" ContentType="application/xml"/>');
    buffer.writeln('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>');
    buffer.writeln('  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>');
    buffer.writeln('  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>');

    for (int i = 1; i <= slideCount; i++) {
      buffer.writeln('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }

    buffer.writeln('</Types>');
    return buffer.toString();
  }

  static String _buildPresentationXml(int slideCount) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');
    buffer.writeln('  <p:sldMasterIdLst/>');
    buffer.writeln('  <p:sldIdLst>');
    for (int i = 1; i <= slideCount; i++) {
      buffer.writeln('    <p:sldId id="${255 + i}" r:id="rId${10 + i}"/>');
    }
    buffer.writeln('  </p:sldIdLst>');
    buffer.writeln('  <p:sldSz cx="12192000" cy="6858000" type="screen16x9"/>');
    buffer.writeln('  <p:notesSz cx="6858000" cy="9144000"/>');
    buffer.writeln('</p:presentation>');
    return buffer.toString();
  }

  static String _buildPresentationRelsXml(int slideCount) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    for (int i = 1; i <= slideCount; i++) {
      buffer.writeln('  <Relationship Id="rId${10 + i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>');
    }
    buffer.writeln('</Relationships>');
    return buffer.toString();
  }

  static String _buildSlideXml(PresentationSlide slide, LessonPresentation presentation) {
    final cleanTitle = _xmlEscape(slide.title);
    final cleanSubtitle = _xmlEscape(slide.subtitle);
    final cleanBadge = _xmlEscape(slide.badgeText.isNotEmpty ? slide.badgeText : 'УРОК');
    final notes = _xmlEscape(slide.speakerNotes);

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');
    buffer.writeln('  <p:cSld>');
    buffer.writeln('    <p:spTree>');
    buffer.writeln('      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
    buffer.writeln('      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');

    // Background Card (Mobbin Design)
    buffer.writeln('''      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="CardBg"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="609600" y="500000"/><a:ext cx="10972800" cy="5858000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="F8FAFC"/></a:solidFill>
          <a:ln w="25400"><a:solidFill><a:srgbClr val="CBD5E1"/></a:solidFill></a:ln>
        </p:spPr>
      </p:sp>''');

    // Slide Badge & Header Text
    buffer.writeln('''      <p:sp>
        <p:nvSpPr><p:cNvPr id="3" name="HeaderBox"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="1000000" y="800000"/><a:ext cx="10000000" cy="1800000"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr rtlCol="0" anchor="t"/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="ru-RU" sz="1300" b="1"><a:solidFill><a:srgbClr val="4F46E5"/></a:solidFill></a:rPr>
              <a:t>[ $cleanBadge ]</a:t>
            </a:r>
          </a:p>
          <a:p>
            <a:r>
              <a:rPr lang="ru-RU" sz="2800" b="1"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
              <a:t>$cleanTitle</a:t>
            </a:r>
          </a:p>
          <a:p>
            <a:r>
              <a:rPr lang="ru-RU" sz="1600" i="1"><a:solidFill><a:srgbClr val="64748B"/></a:solidFill></a:rPr>
              <a:t>$cleanSubtitle</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>''');

    // Bullet points / Content Box (Mobbin Card Style)
    buffer.writeln('''      <p:sp>
        <p:nvSpPr><p:cNvPr id="4" name="ContentBox"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="1000000" y="2700000"/><a:ext cx="10000000" cy="3200000"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr rtlCol="0" anchor="t"/>
          <a:lstStyle/>''');

    for (final point in slide.bulletPoints) {
      final cleanPoint = _xmlEscape(point);
      buffer.writeln('''          <a:p>
            <a:pPr marL="288000" indent="-288000"><a:buChar char="•"/></a:pPr>
            <a:r>
              <a:rPr lang="ru-RU" sz="1800"><a:solidFill><a:srgbClr val="1E293B"/></a:solidFill></a:rPr>
              <a:t>$cleanPoint</a:t>
            </a:r>
          </a:p>''');
    }

    if (notes.isNotEmpty) {
      buffer.writeln('''          <a:p><a:pPr/><a:r><a:rPr lang="ru-RU" sz="1200"/><a:t> </a:t></a:r></a:p>
          <a:p>
            <a:r>
              <a:rPr lang="ru-RU" sz="1300" i="1"><a:solidFill><a:srgbClr val="4338CA"/></a:solidFill></a:rPr>
              <a:t>Указания учителю (Скрипт): $notes</a:t>
            </a:r>
          </a:p>''');
    }

    buffer.writeln('        </p:txBody>');
    buffer.writeln('      </p:sp>');

    buffer.writeln('    </p:spTree>');
    buffer.writeln('  </p:cSld>');
    buffer.writeln('  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>');
    buffer.writeln('</p:sld>');

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
}
