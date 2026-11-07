import 'package:flutter/services.dart';
import 'web_file_helper.dart';
import 'package:intl/intl.dart';
import 'package:metodist/models/lesson_summary_card.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/pdf_style_config.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/services/yandex_art_service.dart';
import 'package:metodist/models/printable_card.dart';
import 'package:metodist/services/pdf_icons_helper.dart';
import 'prompt_builder.dart';
import 'pdf_layout_validator.dart';

/// Типы материалов для генерации
enum PdfMaterialType {
  conspect,    // Основной конспект занятия
  worksheet,   // Лист заданий для печати
  homework     // Домашняя работа
}

/// Интеллектуальный контейнер неразрывности:
/// гарантирует, что блок задания и его дидактическое поле
/// (сетка клеток, косые линейки, схемы, домики) ВСЕГДА
/// остаются на одной странице и не разрываются на стыке страниц.
class KeepTogether extends pw.Inseparable {
  KeepTogether({required pw.Widget child, this.maxSafeHeight = 680.0})
      : super(child: child);

  final double maxSafeHeight;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    if (child == null) {
      box = PdfRect.fromPoints(PdfPoint.zero, constraints.smallest);
      return;
    }

    // Измеряем полную неделимую высоту содержимого без искусственной обрезки по текущему листу
    final unconstrained = constraints.copyWith(maxHeight: double.infinity);
    child!.layout(context, unconstrained, parentUsesSize: parentUsesSize);
    final fullHeight = child!.box?.height ?? 0.0;

    // Если блок целиком помещается в свободное место листа или превышает стандартный лист:
    if (fullHeight <= constraints.maxHeight || fullHeight > maxSafeHeight) {
      child!.layout(context, constraints, parentUsesSize: parentUsesSize);
      box = child!.box;
    } else {
      // Блок не влезает целиком -> заявляем полную высоту, заставляя MultiPage перенести весь блок на новый лист
      box = PdfRect(0, 0, constraints.maxWidth, fullHeight);
    }
  }

  @override
  bool get canSpan => false;

  @override
  bool get hasMoreWidgets => false;
}

class PdfExportService {
  static pw.Font? _cachedFontRegular;
  static pw.Font? _cachedFontBold;
  static pw.Font? _cachedFontItalic;

  static Future<pw.Font> _loadRobotoRegular() async {
    if (_cachedFontRegular != null) return _cachedFontRegular!;
    try {
      final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
      _cachedFontRegular = pw.Font.ttf(fontData);
      return _cachedFontRegular!;
    } catch (_) {
      try {
        _cachedFontRegular = await PdfGoogleFonts.robotoRegular().timeout(const Duration(seconds: 4));
        return _cachedFontRegular!;
      } catch (_) {
        return pw.Font.helvetica();
      }
    }
  }

  static Future<pw.Font> _loadRobotoBold() async {
    if (_cachedFontBold != null) return _cachedFontBold!;
    try {
      final fontData = await rootBundle.load('assets/fonts/Nunito-Bold.ttf');
      _cachedFontBold = pw.Font.ttf(fontData);
      return _cachedFontBold!;
    } catch (_) {
      try {
        _cachedFontBold = await PdfGoogleFonts.robotoBold().timeout(const Duration(seconds: 4));
        return _cachedFontBold!;
      } catch (_) {
        return pw.Font.helveticaBold();
      }
    }
  }

  static Future<pw.Font> _loadRobotoItalic() async {
    if (_cachedFontItalic != null) return _cachedFontItalic!;
    try {
      final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
      _cachedFontItalic = pw.Font.ttf(fontData);
      return _cachedFontItalic!;
    } catch (_) {
      try {
        _cachedFontItalic = await PdfGoogleFonts.robotoItalic().timeout(const Duration(seconds: 4));
        return _cachedFontItalic!;
      } catch (_) {
        return pw.Font.helveticaOblique();
      }
    }
  }

  static Future<void> _shareOrDownloadPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      WebFileHelper.downloadPdf(bytes, filename);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  static PdfColor _withOpacity(PdfColor baseColor, double opacity) =>
      PdfColor(baseColor.red, baseColor.green, baseColor.blue, opacity);

  /// Полное удаление всех эмодзи и специальных символов
  static String _replaceEmojisWithSymbols(String text) {
    if (text.isEmpty) return text;
    
    // Удаляем все эмодзи
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{2B00}-\u{2BFF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{200D}]|[\u{FE0E}-\u{FE0F}]',
      unicode: true,
    );
    
    String result = text.replaceAll(emojiRegex, '');
    
    // Также удаляем все декоративные символы (•, →, ⚡, ✱, ≡, ☑, ✓, ✗, ★, ⌕, ☁, ■, ▰, ◊, №, ‼ и т.д.)
    final decorativeSymbolsRegex = RegExp(r'[•→⚡✱≡☑✓✗★⭐⌕☁■▰◊№‼\uFFFD]');
    result = result.replaceAll(decorativeSymbolsRegex, '');
    
    // Очистка лишних пробелов
    result = result.replaceAll(RegExp(r' {2,}'), ' ').trim();
    
    return result;
  }

  /// Очистка текста от любых эмодзи и спецсимволов, не поддерживаемых шрифтом Roboto
  /// (старый метод для обратной совместимости)
  static String _stripEmojis(String text) {
    if (text.isEmpty) return text;
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{2B00}-\u{2BFF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{200D}]|[\u{FE0E}-\u{FE0F}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r' {2,}'), ' ').trim();
  }



  static pw.EdgeInsets _getPageMargin(PdfStyleConfig config) {
    switch (config.marginSize) {
      case PdfMarginSize.compact:
        return const pw.EdgeInsets.fromLTRB(28, 16, 16, 16);
      case PdfMarginSize.wide:
        return const pw.EdgeInsets.fromLTRB(56, 32, 32, 32);
      case PdfMarginSize.standard:
      default:
        return const pw.EdgeInsets.fromLTRB(44, 24, 24, 24);
    }
  }

  /// Экспорт отдельного материала (конспект, лист заданий или домашняя работа)
  static Future<void> exportMaterialPdf(Conspect conspect, PdfMaterialType type, {bool isPro = false, PdfStyleConfig? styleConfig}) async {
    await _exportSinglePdf(conspect, type, isPro: isPro, styleConfig: styleConfig);
  }

  /// Экспорт полного комплекта материалов (где каждый материал гарантированно с нового листа)
  /// Generates the raw PDF bytes for a complete combined kit
  static Future<Uint8List> generateCombinedPdfBytes(Conspect conspect, {bool isPro = false, PdfStyleConfig? styleConfig}) async {
    final config = styleConfig ?? const PdfStyleConfig();
    final pdf = pw.Document();

    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();
    final fontItalic = await _loadRobotoItalic();

    final world = conspect.thematicWorld;
    final isEco = config.preset == PdfPreset.ecoPrint;
    final mascotImage = isEco ? null : await _loadWorldMascot(world, conspect.illustrationMascot);
    final bannerImage = isEco ? null : await _loadWorldBanner(world);
    final coloringFallback = await PdfIconsHelper.loadColoring(world.id);
    final medalFallback = await PdfIconsHelper.loadMedal();
    final starGold = await PdfIconsHelper.loadStarGold();
    final starGray = await PdfIconsHelper.loadStarGray();

    final sectionIcons = <String, pw.MemoryImage?>{};
    final lines = conspect.content.split('\n');
    for (final line in lines) {
      final trimmed = _replaceEmojisWithSymbols(line);
      if (trimmed.startsWith('# ')) {
        final sectionTitle = trimmed.substring(2).trim();
        final iconName = PdfIconsHelper.getSectionIconName(sectionTitle);
        if (!sectionIcons.containsKey(iconName)) {
          final icon = await PdfIconsHelper.loadIcon(iconName);
          sectionIcons[iconName] = icon;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _getPageMargin(config),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
        ),
        header: (context) => _buildPdfHeader(conspect, PdfMaterialType.conspect, isPro: isPro, styleConfig: config),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (isEco)
                pw.Text(
                  'Методист • Эко-печать (Zero-Toner)',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                )
              else if (config.schoolName.isNotEmpty)
                pw.Text(
                  '${config.schoolName}${config.teacherName.isNotEmpty ? " • ${config.teacherName}" : ""}',
                  style: pw.TextStyle(color: PdfColor.fromInt(config.brandColorHex), fontSize: 8, fontWeight: pw.FontWeight.bold),
                )
              else if (isPro)
                pw.Text(
                  'Методист Pro • Комплект материалов',
                  style: const pw.TextStyle(color: PdfColors.indigo700, fontSize: 8),
                )
              else
                pw.SizedBox(),
              pw.Text(
                'Страница ${context.pageNumber} из ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
              ),
            ],
          ),
        ),
        build: (context) => [
          _buildPdfTitle(conspect, PdfMaterialType.conspect, null, isPro: isPro, mascotImage: mascotImage, bannerImage: bannerImage, styleConfig: config),
          pw.SizedBox(height: 10),
          _buildMaterialInfo(conspect, PdfMaterialType.conspect, styleConfig: config),
          pw.SizedBox(height: 12),
          ..._buildContentWidgets(
            conspect.content,
            fontRegular,
            fontBold,
            sectionIcons,
            starGold: starGold,
            starGray: starGray,
            isWorksheetOrHomework: false,
            subject: conspect.subject,
            topic: conspect.topic,
            ageGroup: conspect.ageGroup,
          ),
          if (isPro && conspect.illustrationColoring != null && !isEco) ...[
            KeepTogether(child: _buildProColoringSection(conspect.illustrationColoring)),
            if (conspect.illustrationReward != null)
              KeepTogether(child: _buildProRewardSection(conspect.illustrationReward)),
          ],
        ],
      ),
    );

    return await pdf.save();
  }

  /// Экспорт полного комплекта материалов (где каждый материал гарантированно с нового листа)
  static Future<void> exportAllMaterialsCombinedPdf(Conspect conspect, {bool isPro = false, PdfStyleConfig? styleConfig}) async {
    final bytes = await generateCombinedPdfBytes(conspect, isPro: isPro, styleConfig: styleConfig);
    await _shareOrDownloadPdf(
      bytes: bytes,
      filename: 'Комплект_${conspect.title.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Exports conspect to formatted PDF document and opens print/share dialog
  static Future<void> exportAndSharePdf(Conspect conspect, {bool isPro = false, PdfStyleConfig? styleConfig}) async {
    if (conspect.generatedMaterials.length <= 1) {
      await _exportSinglePdf(conspect, PdfMaterialType.conspect, isPro: isPro, styleConfig: styleConfig);
    } else {
      await exportAllMaterialsCombinedPdf(conspect, isPro: isPro, styleConfig: styleConfig);
    }
  }

  /// Экспорт отдельного PDF по типу материала
  static Future<void> _exportSinglePdf(Conspect conspect, PdfMaterialType type, {bool isPro = false, PdfStyleConfig? styleConfig}) async {
    final pdf = pw.Document();

    // Load Cyrillic-compatible Google Font (Roboto)
    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();
    final fontItalic = await _loadRobotoItalic();

    // Извлекаем только нужную часть контента строго в зависимости от типа материала
    final filteredContent = _extractMaterialContent(conspect.content, type);
    if (filteredContent.isEmpty) {
      final label = _getMaterialLabel(type);
      throw Exception('Материал «$label» не был сформирован в этом конспекте.');
    }

    // Загружаем иконку для типа материала, маскота и звезд
    final config = styleConfig ?? const PdfStyleConfig();
    final isEco = config.preset == PdfPreset.ecoPrint;
    final materialTypeName = type.toString().split('.').last;
    final materialIconName = PdfIconsHelper.getMaterialIconName(materialTypeName);
    final materialIcon = await PdfIconsHelper.loadIcon(materialIconName);
    final world = conspect.thematicWorld;
    final mascotImage = isEco ? null : await _loadWorldMascot(world, conspect.illustrationMascot);
    final bannerImage = isEco ? null : await _loadWorldBanner(world);
    final coloringFallback = await PdfIconsHelper.loadColoring(world.id);
    final medalFallback = await PdfIconsHelper.loadMedal();
    final starGold = await PdfIconsHelper.loadStarGold();
    final starGray = await PdfIconsHelper.loadStarGray();

    // Определяем все заголовки разделов и заранее загружаем их иконки
    final sectionIcons = <String, pw.MemoryImage?>{};
    final lines = filteredContent.split('\n');
    for (final line in lines) {
      final trimmed = _replaceEmojisWithSymbols(line);
      if (trimmed.startsWith('# ')) {
        final sectionTitle = trimmed.substring(2).trim();
        final iconName = PdfIconsHelper.getSectionIconName(sectionTitle);
        if (!sectionIcons.containsKey(iconName)) {
          final icon = await PdfIconsHelper.loadIcon(iconName);
          sectionIcons[iconName] = icon;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _getPageMargin(config),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
        ),
        header: (context) => _buildPdfHeader(conspect, type, isPro: isPro, styleConfig: config),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (isEco)
                pw.Text(
                  'Методист • Эко-печать (Zero-Toner)',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                )
              else if (config.schoolName.isNotEmpty)
                pw.Text(
                  '${config.schoolName}${config.teacherName.isNotEmpty ? " • ${config.teacherName}" : ""}',
                  style: pw.TextStyle(color: PdfColor.fromInt(config.brandColorHex), fontSize: 8, fontWeight: pw.FontWeight.bold),
                )
              else if (isPro)
                pw.Text(
                  'Методист Pro • Премиум материалы',
                  style: const pw.TextStyle(color: PdfColors.indigo700, fontSize: 8),
                )
              else
                pw.SizedBox(),
              pw.Text(
                'Страница ${context.pageNumber} из ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
              ),
            ],
          ),
        ),
        build: (context) => [
          _buildPdfTitle(
            conspect,
            type,
            materialIcon,
            isPro: isPro,
            mascotImage: mascotImage,
            bannerImage: bannerImage,
            styleConfig: config,
          ),
          pw.SizedBox(height: 10),

          _buildMaterialInfo(conspect, type, styleConfig: config),
          pw.SizedBox(height: 12),

          ..._buildContentWidgets(
            filteredContent,
            fontRegular,
            fontBold,
            sectionIcons,
            starGold: starGold,
            starGray: starGray,
            isWorksheetOrHomework: type != PdfMaterialType.conspect,
            subject: conspect.subject,
            topic: conspect.topic,
            ageGroup: conspect.ageGroup,
          ),

          if (isPro && conspect.illustrationColoring != null && !isEco)
            KeepTogether(child: _buildProColoringSection(conspect.illustrationColoring)),

          if (isPro && conspect.illustrationReward != null && !isEco)
            KeepTogether(child: _buildProRewardSection(conspect.illustrationReward)),
        ],
      ),
    );

    // Share/print the generated PDF
    await _shareOrDownloadPdf(
      bytes: await pdf.save(),
      filename: _getPdfFilename(conspect.title, type),
    );
  }

  /// Старый метод для обратной совместимости
  static Future<void> _exportLegacyPdf(Conspect conspect) async {
    final pdf = pw.Document();

    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();
    final fontItalic = await _loadRobotoItalic();

    // Определяем все заголовки разделов и заранее загружаем их иконки
    final sectionIcons = <String, pw.MemoryImage?>{};
    final lines = conspect.content.split('\n');
    for (final line in lines) {
      final trimmed = _replaceEmojisWithSymbols(line);
      if (trimmed.startsWith('# ')) {
        final sectionTitle = trimmed.substring(2).trim();
        final iconName = PdfIconsHelper.getSectionIconName(sectionTitle);
        if (!sectionIcons.containsKey(iconName)) {
          final icon = await PdfIconsHelper.loadIcon(iconName);
          sectionIcons[iconName] = icon;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
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
                    pw.Text('Длительность: ${conspect.duration}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Main Markdown Content converted into clean paragraphs
          ..._buildContentWidgets(conspect.content, fontRegular, fontBold, sectionIcons),
        ],
      ),
    );

    // Share/print the generated PDF
    await _shareOrDownloadPdf(
      bytes: await pdf.save(),
      filename: 'Конспект_${conspect.title.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Преобразует строковый идентификатор материала в PdfMaterialType
  static PdfMaterialType? _mapMaterialToType(String material) {
    switch (material) {
      case 'conspect':
        return PdfMaterialType.conspect;
      case 'worksheet':
        return PdfMaterialType.worksheet;
      case 'homework':
        return PdfMaterialType.homework;
      default:
        return null;
    }
  }

  static final List<String> _worksheetKeywords = [
    'практические задания',
    'практическая часть',
    'лист заданий',
    'рабочий лист',
    'раздаточный лист',
    'раздаточный материал',
    'задания к уроку',
    'самостоятельная работа',
    'упражнения к уроку',
    'упражнения',
    'уровень 1',
    'задания',
  ];

  static final List<String> _homeworkKeywords = [
    'домашнее задание',
    'домашняя работа',
    'блок дополнительных заданий',
    'задания на дом',
    'домашний практикум',
    'домашка',
  ];

  static final List<String> _cardsKeywords = [
    'карточки для занятия',
    'раздаточные карточки',
    '`json',
  ];

  static int _findSectionStartIndex(String text, List<String> keywords, [int startFrom = 0]) {
    final lower = text.toLowerCase();
    int minIndex = -1;

    for (final kw in keywords) {
      final escapedKw = RegExp.escape(kw);
      final regex = RegExp(
        r'(?:^|\n)#{1,4}\s*[^a-zA-Zа-яА-ЯёЁ\n0-9]*' + escapedKw,
        caseSensitive: false,
      );
      final searchArea = lower.substring(startFrom);
      final match = regex.allMatches(searchArea).firstOrNull;
      if (match != null) {
        var matchIdx = startFrom + match.start;
        if (searchArea.substring(match.start).startsWith('\n')) {
          matchIdx += 1;
        }
        if (minIndex == -1 || matchIdx < minIndex) {
          minIndex = matchIdx;
        }
      }

      final prefixes = ['\n# ', '\n## ', '\n### ', '# ', '## ', '### ', '\n'];
      for (final prefix in prefixes) {
        final pattern = '$prefix$kw';
        final idx = lower.indexOf(pattern, startFrom);
        if (idx != -1) {
          final actualIdx = (prefix.startsWith('\n') && idx > 0) ? idx + 1 : idx;
          if (minIndex == -1 || actualIdx < minIndex) {
            minIndex = actualIdx;
          }
        }
      }
    }
    return minIndex;
  }

  static bool hasMaterialContent(String content, PdfMaterialType type) {
    final extracted = _extractMaterialContent(content, type);
    return extracted.trim().isNotEmpty;
  }

  static String _getMaterialLabel(PdfMaterialType type) {
    switch (type) {
      case PdfMaterialType.conspect: return 'Конспект';
      case PdfMaterialType.worksheet: return 'Лист заданий';
      case PdfMaterialType.homework: return 'Домашняя работа';
    }
  }

  /// Извлекает контент строго для определенного типа материала
  static String _extractMaterialContent(String content, PdfMaterialType type) {
    final cleanedContent = _removeCardsAndJson(content);

    final wsIndex = _findSectionStartIndex(cleanedContent, _worksheetKeywords);
    final hwIndex = _findSectionStartIndex(cleanedContent, _homeworkKeywords);
    final cardsIndex = _findSectionStartIndex(cleanedContent, _cardsKeywords);

    switch (type) {
      case PdfMaterialType.conspect:
        final cutPoints = <int>[];
        if (wsIndex != -1) cutPoints.add(wsIndex);
        if (hwIndex != -1) cutPoints.add(hwIndex);
        if (cardsIndex != -1) cutPoints.add(cardsIndex);

        if (cutPoints.isNotEmpty) {
          cutPoints.sort();
          return cleanedContent.substring(0, cutPoints.first).trim();
        }
        return cleanedContent.trim();

      case PdfMaterialType.worksheet:
        if (wsIndex == -1) return '';
        int end = cleanedContent.length;
        if (hwIndex != -1 && hwIndex > wsIndex) {
          end = hwIndex;
        } else if (cardsIndex != -1 && cardsIndex > wsIndex) {
          end = cardsIndex;
        }
        return cleanedContent.substring(wsIndex, end).trim();

      case PdfMaterialType.homework:
        if (hwIndex == -1) return '';
        int end = cleanedContent.length;
        if (cardsIndex != -1 && cardsIndex > hwIndex) {
          end = cardsIndex;
        }
        return cleanedContent.substring(hwIndex, end).trim();

      default:
        return cleanedContent;
    }
  }

  /// Удаляет карточки и JSON блоки из контента
  static String _removeCardsAndJson(String content) {
    final jsonRegex = RegExp(r'```(?:json)?\s*(\[\s*\{[\s\S]*?\}\s*\])\s*```');
    var cleaned = content.replaceAllMapped(jsonRegex, (match) => '');

    final rawJsonRegex = RegExp(r'(\[\s*\{[\s\S]*?\}\s*\])');
    cleaned = cleaned.replaceAllMapped(rawJsonRegex, (match) => '');

    cleaned = cleaned.replaceAll('Карточки для занятия', '');
    cleaned = cleaned.replaceAll('раздаточные карточки', '');

    return cleaned.trim();
  }

  /// Разделяет контент на секции по заголовкам Markdown
  static Map<String, String> _splitContentBySections(String content) {
    final sections = <String, String>{};
    final lines = content.split('\n');
    String? currentSection;
    final sectionContent = StringBuffer();
    final headerRegex = RegExp(r'^(?:\d+[\.\)]\s*)?#{1,2}\s+(.+)$');

    for (final line in lines) {
      final trimmed = line.trim();
      final match = headerRegex.firstMatch(trimmed);

      if (match != null) {
        if (currentSection != null && sectionContent.isNotEmpty) {
          sections[currentSection] = sectionContent.toString().trim();
          sectionContent.clear();
        }
        currentSection = match.group(1)!.trim();
      } else if (currentSection != null) {
        sectionContent.writeln(line);
      } else {
        sectionContent.writeln(line);
      }
    }

    if (currentSection != null && sectionContent.isNotEmpty) {
      sections[currentSection] = sectionContent.toString().trim();
    }

    return sections;
  }
  /// Создает заголовок PDF файла
  static pw.Widget _buildPdfHeader(
    Conspect conspect,
    PdfMaterialType type, {
    bool isPro = false,
    PdfStyleConfig? styleConfig,
  }) {
    final config = styleConfig ?? const PdfStyleConfig();
    final headerText = _getMaterialHeaderText(type);
    final isEco = config.preset == PdfPreset.ecoPrint;
    final schoolLabel = config.schoolName.isNotEmpty ? ' • ${config.schoolName}' : '';
    final teacherLabel = config.teacherName.isNotEmpty ? ' (${config.teacherName})' : '';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (config.schoolName.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(config.brandColorHex),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                config.schoolName.toUpperCase(),
                style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
            )
          else if (isEco)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                'ЭКО-ПЕЧАТЬ',
                style: pw.TextStyle(color: PdfColors.grey800, fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
            )
          else if (isPro)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: PdfColors.indigo300, width: 0.5),
              ),
              child: pw.Text(
                'МЕТОДИСТ PRO',
                style: pw.TextStyle(color: PdfColors.indigo900, fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
            )
          else
            pw.SizedBox(),
          pw.Text(
            '$headerText: ${conspect.methodName} — ${conspect.subject}$schoolLabel$teacherLabel',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static Future<pw.MemoryImage?> _loadWorldMascot(ThematicWorld world, String? customMascot) async {
    if (customMascot != null && customMascot.isNotEmpty) {
      try {
        final clean = customMascot.contains(',') ? customMascot.split(',').last : customMascot;
        return pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    final worldMascot = await PdfIconsHelper.loadWorldMascot(world.id);
    if (worldMascot != null) return worldMascot;

    return await PdfIconsHelper.loadMascot();
  }

  static Future<pw.MemoryImage?> _loadWorldBanner(ThematicWorld world) async {
    final assetBanner = await PdfIconsHelper.loadWorldBanner(world.id);
    if (assetBanner != null) return assetBanner;

    return null;
  }

  static pw.Widget _buildPdfTitle(
    Conspect conspect,
    PdfMaterialType type,
    pw.MemoryImage? materialIcon, {
    bool isPro = false,
    pw.MemoryImage? mascotImage,
    ThematicWorld? world,
    pw.MemoryImage? bannerImage,
    PdfStyleConfig? styleConfig,
  }) {
    final config = styleConfig ?? const PdfStyleConfig();
    final isEco = config.preset == PdfPreset.ecoPrint;
    final effectiveWorld = world ?? conspect.thematicWorld;
    final topic = _replaceEmojisWithSymbols(conspect.topic.isNotEmpty ? conspect.topic : conspect.title);

    if (!isEco && mascotImage == null && conspect.illustrationMascot != null && conspect.illustrationMascot!.isNotEmpty) {
      try {
        final clean = conspect.illustrationMascot!.contains(',')
            ? conspect.illustrationMascot!.split(',').last
            : conspect.illustrationMascot!;
        mascotImage = pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    final worldPrimary = isEco ? PdfColors.grey800 : (config.schoolName.isNotEmpty ? PdfColor.fromInt(config.brandColorHex) : effectiveWorld.pdfPrimary);
    final worldSecondary = isEco ? PdfColors.grey200 : effectiveWorld.pdfSecondary;
    final worldAccent = isEco ? PdfColors.grey600 : effectiveWorld.pdfAccent;
    final bgLight = isEco ? PdfColors.white : _withOpacity(worldSecondary, 0.08);
    final borderCol = isEco ? PdfColors.grey400 : _withOpacity(worldPrimary, 0.35);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: bgLight,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: borderCol, width: 1.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Панорамный цветной баннер YandexART в шапке (если доступен)
              if (bannerImage != null)
                pw.ClipRRect(
                  horizontalRadius: 9,
                  verticalRadius: 9,
                  child: pw.Container(
                    height: 48,
                    width: double.infinity,
                    child: pw.Image(bannerImage, fit: pw.BoxFit.cover),
                  ),
                ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Иконка типа материала
                    if (materialIcon != null)
                      pw.Container(
                        width: 36,
                        height: 36,
                        margin: const pw.EdgeInsets.only(right: 10),
                        child: pw.Image(materialIcon),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (config.schoolName.isNotEmpty) ...[
                            pw.Row(
                              children: [
                                pw.Text(
                                  config.schoolName,
                                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: worldPrimary),
                                ),
                                if (config.teacherName.isNotEmpty) ...[
                                  pw.Text(' • Учитель: ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                  pw.Text(config.teacherName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: worldPrimary)),
                                ],
                              ],
                            ),
                            pw.SizedBox(height: 3),
                          ],
                          pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: worldPrimary,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  effectiveWorld.missionBadge,
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                effectiveWorld.title,
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: worldPrimary,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            topic,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Маскот мира с диалоговым облачком поддержки
                    if (mascotImage != null)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            constraints: const pw.BoxConstraints(maxWidth: 130),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            margin: const pw.EdgeInsets.only(right: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: borderCol, width: 0.8),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '${effectiveWorld.mascotName}:',
                                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: worldPrimary),
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  effectiveWorld.mascotEncouragement(type.toString().split('.').last),
                                  style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                          pw.Container(
                            width: 48,
                            height: 48,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: worldAccent, width: 2),
                            ),
                            padding: const pw.EdgeInsets.all(2.5),
                            child: pw.ClipOval(
                              child: pw.Image(mascotImage, fit: pw.BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Создает информационный блок материала с легким градиентом
  static pw.Widget _buildMaterialInfo(Conspect conspect, PdfMaterialType type, {PdfStyleConfig? styleConfig}) {
    final config = styleConfig ?? const PdfStyleConfig();
    final bool isEco = config.preset == PdfPreset.ecoPrint;
    final bool isStudentSheet = type == PdfMaterialType.worksheet || type == PdfMaterialType.homework;
    final bool showStudentHeader = config.showStudentHeader;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: isEco ? PdfColors.white : null,
        gradient: isEco
            ? null
            : const pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  PdfColors.blue50,
                  PdfColors.indigo50,
                ],
              ),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: isEco ? PdfColors.grey400 : PdfColors.blue200, width: isEco ? 0.7 : 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Предмет: ${_replaceEmojisWithSymbols(conspect.subject)} • ${_replaceEmojisWithSymbols(conspect.ageGroup)}',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: isEco ? PdfColors.grey800 : PdfColors.indigo900),
              ),
              pw.Text(
                'Методика: ${_replaceEmojisWithSymbols(conspect.methodName)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          if (isStudentSheet && showStudentHeader) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: isEco ? PdfColors.grey400 : PdfColors.indigo200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Фамилия, Имя ученика: _________________________________', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      conspect.ageGroup.toLowerCase().contains('дошкол') || conspect.ageGroup.toLowerCase().contains('preschool') || conspect.ageGroup.toLowerCase().contains('4-5') || conspect.ageGroup.toLowerCase().contains('5-6')
                          ? 'Группа: «____»'
                          : (conspect.ageGroup.contains('2') ? 'Класс: 2 «____»' : 'Класс: 1 «____»'),
                      style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Дата: ____________', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }



  /// Получает заголовок для шапки PDF
  static String _getMaterialHeaderText(PdfMaterialType type) {
    switch (type) {
      case PdfMaterialType.conspect:
        return 'Методист • Конспект занятия';
      case PdfMaterialType.worksheet:
        return 'Методист • Лист заданий';
      case PdfMaterialType.homework:
        return 'Методист • Домашняя работа';
    }
  }

  /// Получает заголовок PDF
  static String _getMaterialTitle(String baseTitle, PdfMaterialType type) {
    switch (type) {
      case PdfMaterialType.conspect:
        return 'Конспект занятия: $baseTitle';
      case PdfMaterialType.worksheet:
        return 'Лист заданий: $baseTitle';
      case PdfMaterialType.homework:
        return 'Домашняя работа: $baseTitle';
    }
  }

  /// Получает описание материала
  static String _getMaterialDescription(PdfMaterialType type) {
    switch (type) {
      case PdfMaterialType.conspect:
        return 'Подробный конспект занятия с пошаговым сценарием, целями и задачами';
      case PdfMaterialType.worksheet:
        return 'Раздаточный материал для печати с упражнениями и заданиями';
      case PdfMaterialType.homework:
        return 'Задания для домашней работы с творческими и практическими упражнениями';
    }
  }

  /// Получает цвет для типа материала
  static PdfColor _getMaterialColor(PdfMaterialType type) {
    switch (type) {
      case PdfMaterialType.conspect:
        return PdfColors.indigo500;
      case PdfMaterialType.worksheet:
        return PdfColors.blue500;
      case PdfMaterialType.homework:
        return PdfColors.green500;
    }
  }

  /// Получает имя файла для PDF
  static String _getPdfFilename(String title, PdfMaterialType type) {
    final cleanTitle = title.replaceAll(' ', '_');
    switch (type) {
      case PdfMaterialType.conspect:
        return 'Конспект_$cleanTitle.pdf';
      case PdfMaterialType.worksheet:
        return 'Лист_заданий_$cleanTitle.pdf';
      case PdfMaterialType.homework:
        return 'Домашняя_работа_$cleanTitle.pdf';
    }
  }



  /// Удаление HTML-тегов из текста
  static String _cleanHtmlTags(String text) {
    if (text.isEmpty) return text;
    
    // Удаляем основные HTML-теги
    var cleaned = text
        .replaceAll(RegExp(r'<h1[^>]*>', caseSensitive: false), '# ')
        .replaceAll(RegExp(r'</h1>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<h2[^>]*>', caseSensitive: false), '## ')
        .replaceAll(RegExp(r'</h2>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<h3[^>]*>', caseSensitive: false), '### ')
        .replaceAll(RegExp(r'</h3>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<h4[^>]*>', caseSensitive: false), '#### ')
        .replaceAll(RegExp(r'</h4>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<strong[^>]*>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'</strong>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<b[^>]*>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'</b>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<em[^>]*>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'</em>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'<i[^>]*>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'</i>', caseSensitive: false), '*');
    
    // Удаляем оставшиеся теги
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Очищаем лишние пробелы и пустые строки
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    
    return cleaned;
  }

  /// Памятка для родителей (спокойный совет, норма СанПиН и QR-код аудио-гида)
  static pw.Widget _buildParentBriefingCard(String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green600,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'СОВЕТ РОДИТЕЛЮ',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFDCFCE7),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      '⏱ СанПиН: 10-15 мин • Без перегрузки',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('60-сек аудио-гид', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('для родителей ->', style: const pw.TextStyle(fontSize: 7, color: PdfColors.green800)),
                    ],
                  ),
                  pw.SizedBox(width: 4),
                  pw.Container(
                    width: 32,
                    height: 32,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://mrsmokemaker.github.io/annmetodist/#/parent-briefing',
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            content,
            style: const pw.TextStyle(
              fontSize: 9.5,
              lineSpacing: 1.35,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  /// Талон обратной связи родителя учителю
  static pw.Widget _buildParentFeedbackSlip() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ТАЛОН ОБРАТНОЙ СВЯЗИ РОДИТЕЛЯ УЧИТЕЛЮ',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              pw.Text(
                'Дата: ____________',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text('Время работы: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('[ ] 10-15 мин   [ ] 20 мин   [ ] более 30 мин', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('Сложность: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('[ ] Справился сам   [ ] С небольшой подсказкой   [ ] Было трудно', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Вопрос учителю: ________________________________________________________________',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Подпись родителя: ___________________________',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Блок самооценки и настроения
  static pw.Widget _buildSelfAssessmentBlock() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'КАК Я СПРАВИЛСЯ С ЗАДАНИЯМИ:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.Text(
                'Отметка / подпись учителя: ____________',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Row(children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.green600, width: 1.2),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text('🙂 Отлично (всё сам)', style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.Row(children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.amber600, width: 1.2),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text('😐 Нормально (были вопросы)', style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.Row(children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.red600, width: 1.2),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text('🙁 Трудно (нужна помощь)', style: const pw.TextStyle(fontSize: 9)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  /// Линии для аккуратного письма от руки
  static pw.Widget _buildAnswerLines({int count = 3, String? label}) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (label != null && label.isNotEmpty) ...[
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
          ],
          for (int i = 0; i < count; i++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              height: 1,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Корзинка слов для справок
  static pw.Widget _buildWordBank(String wordsText) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.amber300, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Слова для справок: ',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              wordsText,
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Очищает и структурирует заголовок задания: удаляет Markdown (*, **, #, -),
  /// извлекает порядковый номер задания и чистую формулировку задания.
  static ({int? number, String title, bool isTask}) sanitizeTaskHeader(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'^\s*[-*•]+\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*'), '');
    cleaned = cleaned.replaceAll('**', '').replaceAll('*', '').replaceAll('`', '').trim();
    cleaned = _replaceEmojisWithSymbols(cleaned).trim();

    // Паттерн 1: "Задание 1: ..." или "Задание 1. ..." или "1. Задание: ..."
    final explicitTask = RegExp(
      r'^(?:задание\s*№?\s*(\d+)[:\.\-\s]*(.*)|(\d+)\.\s*задание[:\.\-\s]*(.*))',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (explicitTask != null) {
      final numStr = explicitTask.group(1) ?? explicitTask.group(3);
      final rest = explicitTask.group(2) ?? explicitTask.group(4) ?? '';
      final num = int.tryParse(numStr ?? '');
      return (
        number: num,
        title: rest.replaceAll(RegExp(r'^[:\.\-\s]+'), '').trim(),
        isTask: true,
      );
    }

    // Паттерн 2: Просто "Задание: ..." без номера
    if (RegExp(r'^задание[:\.\-\s]+', caseSensitive: false).hasMatch(cleaned)) {
      final rest = cleaned.replaceFirst(RegExp(r'^задание[:\.\-\s]+', caseSensitive: false), '').trim();
      return (number: null, title: rest, isTask: true);
    }

    // Паттерн 3: Нумерованный заголовок верхнего уровня "1. Соедини стрелками..."
    final numberedMatch = RegExp(r'^(\d+)[\.\)]\s+(.*)$').firstMatch(cleaned);
    if (numberedMatch != null) {
      final num = int.tryParse(numberedMatch.group(1)!);
      final rest = numberedMatch.group(2)!.trim();
      return (number: num, title: rest, isTask: true);
    }

    return (number: null, title: cleaned, isTask: false);
  }

  /// Рендерит форматированный текст без Markdown-артефактов (**жирный**, *курсив*)
  static pw.Widget _buildFormattedText(
    String rawText, {
    pw.TextStyle? defaultStyle,
    pw.TextStyle? boldStyle,
    pw.TextStyle? italicStyle,
    int? maxLines,
    pw.TextAlign? textAlign,
  }) {
    final clean = _replaceEmojisWithSymbols(rawText).trim();
    final baseStyle = defaultStyle ?? const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800);
    final bStyle = boldStyle ?? baseStyle.copyWith(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900);
    final iStyle = italicStyle ?? baseStyle.copyWith(fontStyle: pw.FontStyle.italic);

    if (!clean.contains('*') && !clean.contains('`')) {
      return pw.Text(clean, style: baseStyle, maxLines: maxLines, textAlign: textAlign);
    }

    final List<pw.InlineSpan> spans = [];
    final regex = RegExp(r'\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`');
    int lastEnd = 0;

    for (final match in regex.allMatches(clean)) {
      if (match.start > lastEnd) {
        spans.add(pw.TextSpan(text: clean.substring(lastEnd, match.start), style: baseStyle));
      }
      if (match.group(1) != null) {
        spans.add(pw.TextSpan(text: match.group(1)!, style: bStyle));
      } else if (match.group(2) != null) {
        spans.add(pw.TextSpan(text: match.group(2)!, style: iStyle));
      } else if (match.group(3) != null) {
        spans.add(pw.TextSpan(text: match.group(3)!, style: bStyle));
      }
      lastEnd = match.end;
    }

    if (lastEnd < clean.length) {
      spans.add(pw.TextSpan(text: clean.substring(lastEnd), style: baseStyle));
    }

    return pw.RichText(
      textAlign: textAlign ?? pw.TextAlign.left,
      text: pw.TextSpan(children: spans),
    );
  }

  /// Частая узкая косая линейка под углом 65° (по В. Д. Мазиной)
  /// Единый цельный каллиграфический блок с наклоном линий ВПРАВО (// 65°).
  /// Обязательна для начальной школы для чистописания и письменных заданий.
  static pw.Widget _buildNarrowObliqueRuling({
    int rows = 3,
    double rowHeight = 22.0,
  }) {
    final totalHeight = rows * rowHeight;
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      height: totalHeight,
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAFCFF),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.7),
      ),
      child: pw.CustomPaint(
        size: PdfPoint(500, totalHeight),
        painter: (canvas, size) {
          // 1. Горизонтальные рабочие линии строк и вспомогательные пунктиры
          for (int r = 0; r <= rows; r++) {
            final y = r * rowHeight;
            canvas.setColor(const PdfColor.fromInt(0xFF94A3B8));
            canvas.setLineWidth(0.65);
            canvas.drawLine(0, y, size.x, y);
            canvas.strokePath();

            if (r < rows) {
              // Средняя вспомогательная линия строки (45% высоты строки)
              canvas.setColor(const PdfColor.fromInt(0xFFCBD5E1));
              canvas.setLineWidth(0.4);
              final midY = y + rowHeight * 0.45;
              canvas.drawLine(0, midY, size.x, midY);
              canvas.strokePath();
            }
          }

          // 2. Частые косые наклонные линии под углом 65 градусов ВПРАВО (методика Воскресенской / Илюхиной / Мазиной)
          // В системе координат: y=0 — верхний край блока, y=size.y — нижний край.
          // Каллиграфический наклон вправо (/): нижняя точка левее (x), верхняя правее (x + dx).
          canvas.setColor(const PdfColor.fromInt(0xFFE2E8F0));
          canvas.setLineWidth(0.4);
          final dx = size.y / 2.1445;
          const step = 14.0;
          for (double x = -dx; x < size.x + dx; x += step) {
            canvas.drawLine(x, 0, x + dx, size.y);
          }
          canvas.strokePath();
        },
      ),
    );
  }

  /// Математическая векторная сетка клеток 5х5 мм (по методике А. С. Пчёлко)
  static pw.Widget _buildMathGridArea({
    double height = 56.0,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
      height: height,
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAFCFF),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.6),
      ),
      child: pw.CustomPaint(
        size: PdfPoint(500, height),
        painter: (canvas, size) {
          const cellSize = 14.17; // 5 мм в пунктах (72 pt / 25.4 * 5)
          // Горизонтальные линии клеток
          canvas.setColor(const PdfColor.fromInt(0xFFCBD5E1));
          canvas.setLineWidth(0.45);
          for (double y = 0; y <= size.y; y += cellSize) {
            canvas.drawLine(0, y, size.x, y);
          }
          // Вертикальные линии клеток
          for (double x = 0; x <= size.x; x += cellSize) {
            canvas.drawLine(x, 0, x, size.y);
          }
          canvas.strokePath();

          // Опорные точки в узлах клеток
          canvas.setColor(const PdfColor.fromInt(0xFF94A3B8));
          for (double y = cellSize; y < size.y; y += cellSize) {
            for (double x = cellSize; x < size.x; x += cellSize) {
              canvas.drawRect(x - 0.5, y - 0.5, 1, 1);
            }
          }
          canvas.fillPath();
        },
      ),
    );
  }

  /// Карточка «Корзинка слов и сортировка по группам»
  static pw.Widget _buildSortingTaskCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Распредели слова по группам';
    final hasTable = lines.any((l) => l.trim().startsWith('|') && l.trim().endsWith('|'));

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF0D9488), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF0D9488),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ  • СОРТИРОВКА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF134E4A)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          if (!hasTable) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Запиши распределение слов аккуратно в косую строку (угол наклона 65°):',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F766E)),
            ),
            pw.SizedBox(height: 4),
            _buildNarrowObliqueRuling(rows: 3, rowHeight: 22.0),
          ],
        ],
      ),
    );
  }

  /// Карточка звукового анализа и схем (по Букварю Редозубова)
  static pw.Widget _buildPhoneticTaskCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Звуковой анализ слова';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE11D48), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE11D48),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ЗВУКОВОЙ АНАЛИЗ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF881337)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Заполни звуковую схему слова (красный - гласный, синий - твердый согласный, зеленый - мягкий согласный):',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              for (int c = 0; c < 5; c++)
                pw.Container(
                  width: 22,
                  height: 22,
                  margin: const pw.EdgeInsets.only(right: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF94A3B8), width: 1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildContentWidgets(
    String content,
    pw.Font regular,
    pw.Font bold,
    Map<String, pw.MemoryImage?> sectionIcons, {
    pw.MemoryImage? starGold,
    pw.MemoryImage? starGray,
    bool isWorksheetOrHomework = false,
    String? subject,
    String? topic,
    String? ageGroup,
  }) {
    // Аудит и нормализация вёрстки: гарантируем привязку дидактических полей и эталонов методик
    final bool isMathSubject = (subject != null && subject.toLowerCase().contains('\u043c\u0430\u0442\u0435\u043c')) ||
        (topic != null && (topic.toLowerCase().contains('\u0441\u0447\u0435\u0442') || topic.toLowerCase().contains('\u0447\u0438\u0441\u043b\u0430') || topic.toLowerCase().contains('\u0441\u043b\u043e\u0436\u0435\u043d\u0438\u0435') || topic.toLowerCase().contains('\u0432\u044b\u0447\u0438\u0442\u0430\u043d\u0438\u0435')));

    final audit = PdfLayoutIntegrityValidator.auditAndRepair(
      content,
      type: isWorksheetOrHomework ? PdfMaterialType.worksheet : PdfMaterialType.conspect,
      subject: subject,
      topic: topic,
      ageGroup: ageGroup,
    );
    final cleanedContent = _cleanHtmlTags(audit.repairedContent);
    final rawLines = cleanedContent.split('\n');
    final List<pw.Widget> widgets = [];

    String? currentHeader;
    String currentType = 'standard';
    int currentLevel = 0;
    List<String> currentBlockLines = [];
    int taskNumber = 0;
    pw.Widget? pendingSectionHeader;
    String? pendingLevelHeader;

    void addCardWidget(pw.Widget card) {
      final children = <pw.Widget>[];
      if (pendingSectionHeader != null) {
        children.add(pendingSectionHeader!);
        children.add(pw.SizedBox(height: 4));
        pendingSectionHeader = null;
      }
      if (pendingLevelHeader != null) {
        children.add(_buildLevelHeader(pendingLevelHeader!));
        children.add(pw.SizedBox(height: 4));
        pendingLevelHeader = null;
      }
      children.add(card);

      if (children.length == 1) {
        widgets.add(KeepTogether(child: card));
      } else {
        widgets.add(KeepTogether(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ));
      }
    }

    void flushCurrentBlock() {
      if (currentHeader == null && currentBlockLines.isEmpty) return;

      final header = currentHeader ?? '';
      final lines = List<String>.from(currentBlockLines);
      final type = currentType;
      final level = currentLevel;

      currentHeader = null;
      currentType = 'standard';
      currentLevel = 0;
      currentBlockLines.clear();

      final lowerHeader = header.toLowerCase();
      final fullText = (header + ' ' + lines.join(' ')).toLowerCase();

      // 1. Главный заголовок раздела #
      if (type == 'section' || level == 1) {
        final isMajorMaterialHeader = lowerHeader.contains('лист заданий') ||
            lowerHeader.contains('рабочий лист') ||
            lowerHeader.contains('раздаточн') ||
            lowerHeader.contains('домашн') ||
            lowerHeader.contains('блок дополнительных');

        // Гарантируем, что Лист заданий и Домашка всегда начинаются с нового листа!
        if (isMajorMaterialHeader && widgets.isNotEmpty) {
          widgets.add(pw.NewPage());
        } else if (widgets.isNotEmpty) {
          // Исключаем сиротские заголовки разделов внизу листа!
          widgets.add(pw.NewPage(freeSpace: 110));
        }

        final iconName = PdfIconsHelper.getSectionIconName(header);
        final iconImage = sectionIcons[iconName];
        final sectionWidget = _buildSectionHeader(header, iconImage);
        if (lines.isNotEmpty) {
          widgets.add(KeepTogether(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                sectionWidget,
                pw.SizedBox(height: 4),
                _buildLinesContent(lines, isMath: isMathSubject),
              ],
            ),
          ));
        } else {
          pendingSectionHeader = sectionWidget;
        }
        return;
      }

      // 2. Баннер разделителя уровней (Уровень 1: Старт...)
      // Неразрывно связывается со следующим за ним первым заданием уровня, чтобы исключить сиротские заголовки!
      if (type == 'level_header') {
        pendingLevelHeader = header;
        return;
      }

      // 3. Блок самооценки и рефлексии
      if (type == 'assessment' ||
          lowerHeader.contains('самооценка') ||
          lowerHeader.contains('рефлексия') ||
          fullText.contains('⭐⭐⭐') ||
          fullText.contains('оцени свои успехи')) {
        addCardWidget(_buildSelfAssessmentCard(header, lines, starGold, starGray));
        return;
      }

      // 4. Памятка для родителей
      if (lowerHeader.contains('памятка для родителей') || fullText.contains('памятка для родителей')) {
        addCardWidget(_buildParentBriefingCard(lines.isNotEmpty ? lines.join('\n') : header));
        return;
      }

      // 5. Талон обратной связи учителю
      if (lowerHeader.contains('обратная связь') || lowerHeader.contains('талон') || fullText.contains('отрезной корешок')) {
        addCardWidget(_buildParentFeedbackSlip());
        return;
      }

      // 6. Карточка «Правило урока / Теория / Памятка»
      if (type == 'rule' || lowerHeader.contains('правило') || lowerHeader.contains('теория')) {
        addCardWidget(_buildRuleCard(header, lines));
        return;
      }

      // 7. Карточка «Ключи и ответы для учителя»
      if (type == 'keys' || lowerHeader.contains('ключи') || lowerHeader.contains('ответы для учителя')) {
        addCardWidget(_buildTeacherKeysCard(header, lines));
        return;
      }

      int currentTaskNum = taskNumber;
      final taskHeaderInfo = sanitizeTaskHeader(header);
      if (taskHeaderInfo.number != null) {
        currentTaskNum = taskHeaderInfo.number!;
        taskNumber = currentTaskNum;
      } else {
        taskNumber++;
        currentTaskNum = taskNumber;
      }

      // 7b. Отрезная карточка-помощница (Ступенька вниз ✂)
      if (lowerHeader.contains('карточка-помощница') || lowerHeader.contains('карточка помощница') || fullText.contains('карточка-помощница') || fullText.contains('ступенька вниз')) {
        addCardWidget(_buildScaffoldingHelperCard(header, lines));
        return;
      }

      // 7c. Недельный трекер привычек на холодильник («Паспорт исследователя»)
      if (lowerHeader.contains('паспорт исследователя') || lowerHeader.contains('трекер привычек') || lowerHeader.contains('трекер на холодильник') || fullText.contains('паспорт исследователя')) {
        addCardWidget(_buildFridgeTrackerCard(header, lines, starGold, starGray));
        return;
      }

      // 8. Ловушка Незнайки / Ловушка для внимательных
      if (type == 'trap' || lowerHeader.contains('ловушка') || fullText.contains('ловушка незнайки') || fullText.contains('найди ошибки')) {
        addCardWidget(_buildTrapCard(header, lines, currentTaskNum, isMath: isMathSubject));
        return;
      }

      // 9. Прописи / каллиграфия / узкая косая линейка (для всей начальной школы)
      if (type == 'handwriting' || fullText.contains('[прописи]') || lowerHeader.contains('каллиграфическ') || lowerHeader.contains('чистописан') || lowerHeader.contains('спиши') || lowerHeader.contains('прописи')) {
        addCardWidget(_buildHandwritingCard(header, lines, currentTaskNum));
        return;
      }

      // 9b. Математическая векторная сетка клеток 5х5 мм (по методике Пчёлко)
      if (type == 'math_grid' || fullText.contains('[клетка]') || fullText.contains('[математическая сетка]') || fullText.contains('в клетку') || (lowerHeader.contains('матем') && (lowerHeader.contains('сетка') || lowerHeader.contains('клетк') || lowerHeader.contains('арифмет') || lowerHeader.contains('пример')))) {
        addCardWidget(_buildMathGridCard(header, lines, currentTaskNum));
        return;
      }

      // 10. Соедини стрелками / найди пару
      if (type == 'matching' || fullText.contains('[соедини стрелками]') || lowerHeader.contains('соедини') || lowerHeader.contains('найди пару')) {
        addCardWidget(_buildMatchingTaskCard(header, lines, currentTaskNum));
        return;
      }

      // 10b. Корзинка слов и сортировка по группам
      if (type == 'sorting' || lowerHeader.contains('распредели') || lowerHeader.contains('раздели на группы') || fullText.contains('корзинк') || lowerHeader.contains('по группам')) {
        addCardWidget(_buildSortingTaskCard(header, lines, currentTaskNum));
        return;
      }

      // 10c. Звуковой анализ и фонетическая схема
      if (type == 'phonetic' || lowerHeader.contains('звуков') || lowerHeader.contains('фонетическ') || fullText.contains('звуковая схем')) {
        addCardWidget(_buildPhoneticTaskCard(header, lines, currentTaskNum));
        return;
      }

      // 10d. Числовой домик / Состав числа
      if (type == 'number_house' || lowerHeader.contains('домик') || lowerHeader.contains('состав числа') || fullText.contains('[числовой домик]') || fullText.contains('[домик числа]')) {
        addCardWidget(_buildNumberHouseCard(header, lines, currentTaskNum));
        return;
      }

      // 10e. Сравнение чисел и выражений (> < =)
      if (type == 'comparison' || lowerHeader.contains('сравн') || lowerHeader.contains('> <') || fullText.contains('[сравнение]') || fullText.contains('[знаки сравнения]')) {
        addCardWidget(_buildComparisonCard(header, lines, currentTaskNum));
        return;
      }

      // 10f. Орфографические окошки / Вставка букв
      if (type == 'letter_boxes' || lowerHeader.contains('окошк') || (lowerHeader.contains('вставь') && lowerHeader.contains('букв')) || fullText.contains('[окошки]')) {
        addCardWidget(_buildLetterBoxesCard(header, lines, currentTaskNum));
        return;
      }

      // 10g. Шифровка / Секретный код (Детектив Pro)
      if (type == 'cipher_code' || lowerHeader.contains('шифр') || lowerHeader.contains('секретный код') || lowerHeader.contains('дешифратор') || fullText.contains('[шифр]')) {
        addCardWidget(_buildCipherCodeCard(header, lines, currentTaskNum));
        return;
      }

      // 10h. Числовой луч / Числовая прямая
      if (type == 'number_line' || lowerHeader.contains('числовой луч') || lowerHeader.contains('числовая прямая') || fullText.contains('[числовой луч]')) {
        addCardWidget(_buildNumberLineCard(header, lines, currentTaskNum));
        return;
      }

      // 10i. ТРИЗ-противоречие (Хорошо — Плохо)
      if (type == 'triz_contradiction' || lowerHeader.contains('хорошо-плохо') || lowerHeader.contains('противоречие') || fullText.contains('[хорошо-плохо]')) {
        addCardWidget(_buildTrizContradictionCard(header, lines, currentTaskNum));
        return;
      }

      // 10j. Тестовый выбор с чекбоксами
      if (type == 'multiple_choice' || lowerHeader.contains('тест') || lowerHeader.contains('выбери правильный') || fullText.contains('[выбор]')) {
        addCardWidget(_buildMultipleChoiceCard(header, lines, currentTaskNum));
        return;
      }

      // 10k. Предметный счёт YandexART
      if (type == 'math_counting_art' || lowerHeader.contains('предметный счет') || lowerHeader.contains('сосчитай предметы') || fullText.contains('[предметный счет]')) {
        addCardWidget(_buildMathCountingArtCard(header, lines, currentTaskNum));
        return;
      }

      // 10l. Схема предложения и морфемный разбор (состав слова)
      if (type == 'sentence_morpheme' || lowerHeader.contains('схема предложени') || lowerHeader.contains('состав слова') || lowerHeader.contains('морфемн') || fullText.contains('[схема предложения]') || fullText.contains('[состав слова]')) {
        addCardWidget(_buildSentenceAndMorphemeCard(header, lines, currentTaskNum));
        return;
      }

      // 10m. Вычислительная цепочка и числовая пирамида
      if (type == 'math_chain_pyramid' || lowerHeader.contains('цепочка') || lowerHeader.contains('числовая цепочка') || lowerHeader.contains('пирамида') || lowerHeader.contains('числовая пирамида') || fullText.contains('[цепочка]') || fullText.contains('[пирамида]')) {
        addCardWidget(_buildMathChainAndPyramidCard(header, lines, currentTaskNum));
        return;
      }

      // 10n. Графический диктант по клеточкам
      if (type == 'graphic_dictation' || lowerHeader.contains('графический диктант') || lowerHeader.contains('диктант по клеткам') || fullText.contains('[графический диктант]')) {
        addCardWidget(_buildGraphicDictationCard(header, lines, currentTaskNum));
        return;
      }

      // 10o. Диаграмма Венна / Круги Эйлера
      if (type == 'venn_diagram' || lowerHeader.contains('диаграмма венна') || lowerHeader.contains('круги эйлера') || fullText.contains('[диаграмма венна]') || fullText.contains('[круги эйлера]')) {
        addCardWidget(_buildVennDiagramCard(header, lines, currentTaskNum));
        return;
      }

      // 10p. Кластер / Древо понятий (Mind Map)
      if (type == 'concept_cluster' || lowerHeader.contains('кластер') || lowerHeader.contains('древо понятий') || lowerHeader.contains('схема понятий') || fullText.contains('[кластер]') || fullText.contains('[древо понятий]')) {
        addCardWidget(_buildConceptClusterCard(header, lines, currentTaskNum));
        return;
      }

      // 11. Стандартная неделимая карточка задания
      addCardWidget(_buildStandardTaskCard(header, lines, currentTaskNum, isWorksheetOrHomework, isMath: isMathSubject));
    }

    for (final rawLine in rawLines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      // 1. Заголовок первого уровня #
      if (trimmed.startsWith('# ') && !trimmed.startsWith('##')) {
        flushCurrentBlock();
        currentHeader = trimmed.substring(2).trim();
        currentType = 'section';
        currentLevel = 1;
        flushCurrentBlock();
        continue;
      }

      // 2. Подзаголовки всех уровней (##, ###, ####, #####, ######)
      final hnMatch = RegExp(r'^#{2,6}\s+(.+)$').firstMatch(trimmed);
      if (hnMatch != null) {
        final hText = hnMatch.group(1)!.trim();
        final lower = hText.toLowerCase();

        // Проверяем, не является ли это заголовком-дублем инструкции ловушки
        final isFollowupTrap = currentType == 'trap' &&
            (lower.contains('найди ошибк') ||
                lower.contains('исправь ошибк') ||
                lower.contains('незнайк') ||
                lower.contains('запиши правильн'));

        if (isFollowupTrap) {
          final cleanInstruction = hText.replaceAll(
            RegExp(r'^(?:задание|упражнение)?[:\.\-\s]*', caseSensitive: false),
            '',
          ).trim();
          if (cleanInstruction.isNotEmpty) {
            currentBlockLines.add('**Инструкция**: $cleanInstruction');
          }
          continue;
        }

        // Проверяем, не является ли это строкой решения/примера после образца
        final isFollowupSample = (currentHeader?.toLowerCase().contains('образец') == true ||
                currentBlockLines.any((b) => b.toLowerCase().contains('образец'))) &&
            hText.contains('—') &&
            !lower.contains('задание 2') &&
            !lower.contains('задание 3');

        if (isFollowupSample) {
          final cleanItem = hText.replaceAll(
            RegExp(r'^(?:задание|упражнение)?[:\.\-\s]*', caseSensitive: false),
            '',
          ).trim();
          final parts = cleanItem.split('—');
          if (parts.length >= 2) {
            currentBlockLines.add('1) ${parts[0].trim()} — _______________________');
          } else {
            currentBlockLines.add('1) $cleanItem');
          }
          continue;
        }

        flushCurrentBlock();
        currentHeader = hText;

        if (lower.contains('уровень')) {
          currentType = 'level_header';
          flushCurrentBlock();
        } else if (lower.contains('правило') || lower.contains('теория') || lower.contains('памятка')) {
          currentType = 'rule';
        } else if (lower.contains('ловушка')) {
          currentType = 'trap';
        } else if (lower.contains('самооценка') || lower.contains('рефлексия')) {
          currentType = 'assessment';
        } else if (lower.contains('ключи') || lower.contains('ответы')) {
          currentType = 'keys';
        } else {
          currentType = 'standard';
        }
        continue;
      }

      // 3. Задания (Задание 1: ..., **Задание 1**, - **Задание 1**, 1. ...)
      final taskDetect = sanitizeTaskHeader(trimmed);
      final isExplicitTask = taskDetect.isTask && (
        trimmed.toLowerCase().contains('задание') ||
        (!rawLine.startsWith(' ') && !rawLine.startsWith('\t') && RegExp(r'^\d+[\.\)]\s+').hasMatch(trimmed))
      );

      if (isExplicitTask && currentType != 'assessment' && currentType != 'keys') {
        flushCurrentBlock();
        currentHeader = trimmed;
        final lower = trimmed.toLowerCase();
        if (lower.contains('ловушка')) {
          currentType = 'trap';
        } else if (lower.contains('соедини') || lower.contains('найди пару')) {
          currentType = 'matching';
        } else if (lower.contains('чистописан') || lower.contains('каллиграф') || lower.contains('прописи') || lower.contains('спиши')) {
          currentType = 'handwriting';
        } else if (lower.contains('распредели') || lower.contains('раздели на группы') || lower.contains('корзинк')) {
          currentType = 'sorting';
        } else if (lower.contains('звуков') || lower.contains('фонетическ') || lower.contains('звуковая схем')) {
          currentType = 'phonetic';
        } else if (lower.contains('домик') || lower.contains('состав числа') || lower.contains('[числовой домик]')) {
          currentType = 'number_house';
        } else if (lower.contains('сравн') || lower.contains('> <') || lower.contains('[сравнение]')) {
          currentType = 'comparison';
        } else if (lower.contains('окошк') || (lower.contains('вставь') && lower.contains('букв')) || lower.contains('[окошки]')) {
          currentType = 'letter_boxes';
        } else if (lower.contains('шифр') || lower.contains('секретный код') || lower.contains('дешифратор') || lower.contains('[шифр]')) {
          currentType = 'cipher_code';
        } else if (lower.contains('числовой луч') || lower.contains('числовая прямая') || lower.contains('[числовой луч]')) {
          currentType = 'number_line';
        } else if (lower.contains('хорошо-плохо') || lower.contains('противоречие') || lower.contains('[хорошо-плохо]')) {
          currentType = 'triz_contradiction';
        } else if (lower.contains('тест') || lower.contains('выбери правильный') || lower.contains('[выбор]')) {
          currentType = 'multiple_choice';
        } else if (lower.contains('предметный счет') || lower.contains('сосчитай предметы') || lower.contains('[предметный счет]')) {
          currentType = 'math_counting_art';
        } else if (lower.contains('клетк') || lower.contains('сетк') || lower.contains('арифмет') || lower.contains('вычисли')) {
          currentType = 'math_grid';
        } else {
          currentType = 'standard';
        }
        continue;
      }

      // 4. Обычная строка содержимого текущего блока
      currentBlockLines.add(trimmed);
    }
    flushCurrentBlock();
    if (pendingSectionHeader != null) {
      widgets.add(KeepTogether(child: pendingSectionHeader!));
      pendingSectionHeader = null;
    }
    if (pendingLevelHeader != null) {
      widgets.add(_buildLevelHeader(pendingLevelHeader!));
      pendingLevelHeader = null;
    }

    return widgets;
  }

  /// Заголовок раздела документа
  static pw.Widget _buildSectionHeader(String title, pw.MemoryImage? iconImage) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.indigo50, PdfColors.blue50],
        ),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.indigo300, width: 0.8),
      ),
      child: pw.Row(
        children: [
          if (iconImage != null)
            pw.Container(
              width: 20,
              height: 20,
              margin: const pw.EdgeInsets.only(right: 8),
              child: pw.Image(iconImage),
            ),
          pw.Expanded(
            child: pw.Text(
              _replaceEmojisWithSymbols(title),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Разделительный баннер уровня сложности (Уровень 1: Старт...)
  static pw.Widget _buildLevelHeader(String title) {
    final cleanTitle = _replaceEmojisWithSymbols(title);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.indigo200, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 6,
            height: 6,
            margin: const pw.EdgeInsets.only(right: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.indigo600,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Text(
            cleanTitle.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка «Главное правило урока / Теория / Памятка»
  static pw.Widget _buildRuleCard(String header, List<String> lines) {
    final cleanHeader = _replaceEmojisWithSymbols(header);
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4), // Emerald-50
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF16A34A),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'ПРАВИЛО УРОКА',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  cleanHeader,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF14532D)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
        ],
      ),
    );
  }

  /// Карточка «Ключи и ответы для учителя»
  static pw.Widget _buildTeacherKeysCard(String header, List<String> lines) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC), // Slate-50
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF475569),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'ОТВЕТЫ И РЕШЕНИЯ (ДЛЯ УЧИТЕЛЯ И РОДИТЕЛЕЙ)',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
        ],
      ),
    );
  }

  /// Карточка самооценки с золотыми векторными звездами
  static pw.Widget _buildSelfAssessmentCard(
    String header,
    List<String> lines,
    pw.MemoryImage? starGold,
    pw.MemoryImage? starGray,
  ) {
    String subtitle = 'Оцени свои успехи на занятии:';
    final List<String> criteria = [];

    for (final l in lines) {
      final trimmed = l.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.contains('⭐⭐⭐') || trimmed.toLowerCase().contains('оцени свои успехи')) {
        final clean = _replaceEmojisWithSymbols(trimmed);
        if (clean.isNotEmpty) subtitle = clean;
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*') || RegExp(r'^\d+[\.\)]').hasMatch(trimmed)) {
        final clean = _replaceEmojisWithSymbols(trimmed.replaceFirst(RegExp(r'^[-*•\d\.\)]+\s*'), ''));
        if (clean.isNotEmpty) criteria.add(clean);
      }
    }

    if (criteria.isEmpty) {
      criteria.addAll([
        'Аккуратность чистописания и оформления:',
        'Понимание правил и выполнение заданий:',
        'Самостоятельность и внимательность:',
      ]);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB), // soft amber
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF59E0B),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('САМООЦЕНКА И РЕФЛЕКСИЯ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  subtitle,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF92400E)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          for (final crit in criteria)
            _buildAssessmentCriterion(crit, starGold, starGray),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFFCD34D), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Отметка учителя: [       ]', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.Text('Подпись педагога: ____________________', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentCriterion(String label, pw.MemoryImage? starGold, pw.MemoryImage? starGray) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
          ),
          pw.Row(
            children: [
              for (int i = 0; i < 3; i++)
                pw.Container(
                  width: 13,
                  height: 13,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: starGold != null ? pw.Image(starGold) : pw.Text('[*]', style: const pw.TextStyle(fontSize: 9, color: PdfColors.amber)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Карточка чистописания с разлиновкой в косую линейку под 65 градусов
  static pw.Widget _buildHandwritingCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Спиши каллиграфически аккуратно';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo600,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ЧИСТОПИСАНИЕ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('[прописи]') && !l.toLowerCase().contains('линии для ответа') && !l.contains('____')).toList()),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Письмо элементов и слов в частую узкую косую линейку (угол наклона 65°):',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan900)),
          pw.SizedBox(height: 4),
          _buildNarrowObliqueRuling(rows: 3),
        ],
      ),
    );
  }

  /// Карточка математической сетки клеток 5х5 мм (по методике Пчёлко)
  static pw.Widget _buildMathGridCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Вычисли и запиши решение по клеткам';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • СЧЕТ ПО КЛЕТКАМ',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('[клетка]') && !l.toLowerCase().contains('линии для ответа') && !l.contains('____')).toList(), isMath: true),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Запиши решение и ответ по клеткам 5х5 мм (1 цифра в 1 клетке):',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          _buildMathGridArea(height: 60),
        ],
      ),
    );
  }

  /// Отрезная карточка-помощница (Ступенька вниз ✂)
  static pw.Widget _buildScaffoldingHelperCard(String header, List<String> lines) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4), // soft green
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Text('✂ ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF16A34A),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('ОТРЕЗНАЯ КАРТОЧКА-ПОМОЩНИЦА (СТУПЕНЬКА ВНИЗ)',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Text('Линия отреза для ученика - - - - - - - - - - - - - -',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Если возникла трудность — открой эту подсказку и следуй наглядному алгоритму:',
              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: const PdfColor.fromInt(0xFF166534))),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _buildLinesContent(lines),
          ],
        ],
      ),
    );
  }

  /// Недельный трекер привычек на холодильник («Паспорт исследователя»)
  static pw.Widget _buildFridgeTrackerCard(String header, List<String> lines, pw.MemoryImage? starGold, pw.MemoryImage? starGray) {
    final days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница'];

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAF5FF), // soft purple
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD8B4FE), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF9333EA),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ПАСПОРТ ИССЛЕДОВАТЕЛЯ • ТРЕКЕР НА ХОЛОДИЛЬНИК',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text('Прикрепи на холодильник и отмечай успехи каждый день!',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6B21A8))),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          for (final day in days)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 9,
                        height: 9,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(day, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text('Успех: ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      for (int s = 0; s < 3; s++)
                        pw.Container(
                          width: 10,
                          height: 10,
                          margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                          child: starGold != null ? pw.Image(starGold) : pw.Text('*', style: const pw.TextStyle(fontSize: 8, color: PdfColors.amber)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text('Подпись родителя в конце недели: ____________________',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  /// Карточка «Ловушка Незнайки»
  static pw.Widget _buildTrapCard(String header, List<String> lines, int num, {bool isMath = false}) {
    final sanitized = sanitizeTaskHeader(header);
    var displayHeader = sanitized.title;
    if (displayHeader.toLowerCase().startsWith('ловушка незнайки:')) {
      displayHeader = displayHeader.substring('ловушка незнайки:'.length).trim();
    } else if (displayHeader.toLowerCase().startsWith('ловушка для внимательных:')) {
      displayHeader = displayHeader.substring('ловушка для внимательных:'.length).trim();
    }
    if (displayHeader.isEmpty) {
      displayHeader = 'Найди и исправь хитрые ошибки';
    }

    final fullText = (header + ' ' + lines.join(' ')).toLowerCase();
    final bool isMathTrap = isMath ||
        (!fullText.contains('слово') &&
            !fullText.contains('букв') &&
            !fullText.contains('предложен') &&
            !fullText.contains('звук') &&
            (fullText.contains('вычисл') || fullText.contains('пример') || fullText.contains('чисел') || fullText.contains('число') || RegExp(r'\d+\s*[\+\-\*\/]\s*\d+').hasMatch(fullText)));

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB), // amber-50
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFD97706),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ  • ЛОВУШКА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF78350F)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(
              lines.where((l) => !l.toLowerCase().contains('линии для ответа') && !l.contains('____') && !l.toLowerCase().contains('[прописи]') && !l.toLowerCase().contains('[клетка]')).toList(),
              isMath: isMathTrap,
            ),
          ],
          pw.SizedBox(height: 6),
          if (isMathTrap) ...[
            pw.Text('Исправленное решение запиши аккуратно по клеткам:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF92400E))),
            pw.SizedBox(height: 3),
            _buildMathGridArea(height: 56),
          ] else ...[
            pw.Text('Исправленный вариант запиши каллиграфически правильно:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF92400E))),
            pw.SizedBox(height: 3),
            _buildNarrowObliqueRuling(rows: 3),
          ],
        ],
      ),
    );
  }

  /// Карточка задания «Соедини стрелками»
  static pw.Widget _buildMatchingTaskCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Соедини подходящие пары стрелками';

    final List<String> leftItems = [];
    final List<String> rightItems = [];
    for (final line in lines) {
      final clean = line.replaceAll('*', '').replaceAll(RegExp(r'^\s*[-•]\s*'), '').trim();
      if (clean.contains(' - ') || clean.contains(' — ') || clean.contains(':')) {
        final separator = clean.contains(' — ') ? ' — ' : (clean.contains(' - ') ? ' - ' : ':');
        final parts = clean.split(separator);
        if (parts.length >= 2) {
          leftItems.add(parts[0].trim());
          rightItems.add(parts.sublist(1).join(' ').trim());
        }
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo600,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • СОЕДИНИ ПАРЫ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          if (leftItems.isNotEmpty && rightItems.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      for (final left in leftItems)
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(vertical: 3),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF8FAFC),
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(left, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900))),
                              pw.Text('  •', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      for (final right in rightItems)
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(vertical: 3),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF8FAFC),
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('•  ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo600)),
                              pw.Expanded(child: pw.Text(right, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Соедини подходящие точки аккуратными прямыми линиями по линейке.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// Стандартная неразрывная карточка задания
    /// 1. Карточка «Числовой домик / Состав числа» (по методике Пчёлко и Сингапур CPA)
  static pw.Widget _buildNumberHouseCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Засели числовой домик: состав числа';

    // Извлекаем целевое число домика (из заголовка или строк)
    final numMatch = RegExp(r'(?:числа|домик)\s*(\d+)', caseSensitive: false).firstMatch(header + ' ' + lines.join(' '));
    final houseNumber = numMatch != null ? numMatch.group(1)! : '10';

    // Формируем пары этажей (до 4 этажей)
    final List<(String, String)> floorPairs = [];
    final targetInt = int.tryParse(houseNumber) ?? 10;
    for (int i = 1; i <= 4; i++) {
      if (i < targetInt) {
        floorPairs.add((i.toString(), ''));
      }
    }
    if (floorPairs.isEmpty) {
      floorPairs.addAll([('1', ''), ('2', ''), ('3', ''), ('4', '')]);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF3B82F6), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF2563EB),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • СОСТАВ ЧИСЛА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('[домик]')).toList()),
          ],
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Container(
              width: 150,
              child: pw.Column(
                children: [
                  // Крыша домика с целевым числом
                  pw.Container(
                    height: 26,
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF2563EB),
                      borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(houseNumber, style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ),
                  // Этажи с ячейками
                  for (final pair in floorPairs)
                    pw.Container(
                      height: 22,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColor.fromInt(0xFF60A5FA), width: 1),
                          right: pw.BorderSide(color: PdfColor.fromInt(0xFF60A5FA), width: 1),
                          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF93C5FD), width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              alignment: pw.Alignment.center,
                              decoration: const pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFEFF6FF),
                                border: pw.Border(right: pw.BorderSide(color: PdfColor.fromInt(0xFF93C5FD), width: 1)),
                              ),
                              child: pw.Text(pair.$1, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E40AF))),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              alignment: pw.Alignment.center,
                              color: PdfColors.white,
                              child: pw.Text(pair.$2, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Заполни пустые окошки так, чтобы сумма чисел на каждом этаже равнялась числу на крыше.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// 2. Карточка «Сравнение чисел и выражений: >, <, =»
  static pw.Widget _buildComparisonCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Сравни числа и выражения: поставь знаки >, <, =';

    final List<(String, String)> expressions = [];
    for (final line in lines) {
      final clean = line.replaceAll('*', '').replaceAll(RegExp(r'^\s*[-•]\s*'), '').trim();
      if (clean.contains('...') || clean.contains('___') || clean.contains('О') || clean.contains('O') || clean.contains('?')) {
        final parts = clean.split(RegExp(r'\.{2,}|_{2,}|\s*[ОO\?]\s*'));
        if (parts.length >= 2) {
          expressions.add((parts[0].trim(), parts[1].trim()));
        }
      }
    }

    if (expressions.isEmpty) {
      expressions.addAll([('7 + 3', '12 - 4'), ('15 - 6', '8 + 2'), ('4 * 2', '10 - 2')]);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF6366F1), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF4F46E5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • СРАВНЕНИЕ (> < =)', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF312E81)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          for (final expr in expressions)
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 3),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(expr.$1, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B))),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    width: 18,
                    height: 18,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF6366F1), width: 1.2),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Text(expr.$2, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B))),
                ],
              ),
            ),
          pw.SizedBox(height: 6),
          pw.Text('Впиши в кружок знак больше (>), меньше (<) или равно (=).', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// 3. Карточка «Вставка букв в орфографические окошки»
  static pw.Widget _buildLetterBoxesCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Вставь пропущенные буквы в орфографические окошки';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF0284C7), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF0284C7),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ  • ОКОШКИ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0369A1)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('[окошки]') && !l.toLowerCase().contains('линии для ответа') && !l.contains('____')).toList()),
          ],
          if (!lines.any((l) => RegExp(r'(\[\s*[^\]]+\s*\]\s*){2,}').hasMatch(l) || l.contains('[___]') || l.contains('[.]') || l.contains('[_]'))) ...[
            pw.SizedBox(height: 6),
            pw.Text('Запиши проверенные слова каллиграфически аккуратно в косую строку:',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF075985))),
            pw.SizedBox(height: 4),
            _buildNarrowObliqueRuling(rows: 3),
          ],
        ],
      ),
    );
  }

  /// 4. Карточка «Шифровка / Секретный код / Детектив Pro»
  static pw.Widget _buildCipherCodeCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Разгадай секретный код (Детектив Pro)';

    const keySymbols = ['1', '2', '3', '4', '5', '6', '7'];
    const keyLetters = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'К'];

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAF5FF),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF9333EA), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF7E22CE),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ШИФРОВКА • ДЕТЕКТИВ PRO', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF581C87)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('линии для ответа') && !l.contains('____')).toList()),
          ],
          pw.SizedBox(height: 6),
          // Таблица-ключ дешифратора
          pw.Text('Таблица-ключ шифра:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6B21A8))),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFC084FC), width: 0.8),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3E8FF)),
                children: [
                  for (final sym in keySymbols)
                    pw.Container(
                      height: 18,
                      alignment: pw.Alignment.center,
                      child: pw.Text(sym, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF581C87))),
                    ),
                ],
              ),
              pw.TableRow(
                children: [
                  for (final let in keyLetters)
                    pw.Container(
                      height: 18,
                      alignment: pw.Alignment.center,
                      child: pw.Text(let, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
                    ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Запиши разгаданное слово в клеточки:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              for (int c = 0; c < 6; c++)
                pw.Container(
                  width: 20,
                  height: 20,
                  margin: const pw.EdgeInsets.only(right: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF7E22CE), width: 1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5. Карточка «Числовой луч / Числовая прямая»
  static pw.Widget _buildNumberLineCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Выполни действие по числовому лучу';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF059669), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF059669),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ЧИСЛОВОЙ ЛУЧ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF065F46)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          // Векторный числовой луч
          pw.Container(
            height: 38,
            child: pw.CustomPaint(
              size: const PdfPoint(500, 38),
              painter: (canvas, size) {
                // Главная ось
                canvas.setColor(const PdfColor.fromInt(0xFF059669));
                canvas.setLineWidth(1.2);
                canvas.drawLine(10, size.y / 2, size.x - 10, size.y / 2);
                // Стрелочка в конце
                canvas.drawLine(size.x - 16, size.y / 2 - 4, size.x - 10, size.y / 2);
                canvas.drawLine(size.x - 16, size.y / 2 + 4, size.x - 10, size.y / 2);
                canvas.strokePath();

                // Деления и засечки
                canvas.setColor(const PdfColor.fromInt(0xFF047857));
                canvas.setLineWidth(0.8);
                const step = 42.0;
                for (double x = 20; x < size.x - 30; x += step) {
                  canvas.drawLine(x, size.y / 2 - 5, x, size.y / 2 + 5);
                }
                canvas.strokePath();
              },
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Отметь шаги дугами над числовым лучом и запиши верный ответ.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// 6. Карточка «ТРИЗ: анализ противоречия (Хорошо — Плохо)»
  static pw.Widget _buildTrizContradictionCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'ТРИЗ-анализ объекта: Хорошо — Плохо';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD97706), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFD97706),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ТРИЗ • ХОРОШО - ПЛОХО', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF78350F)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('линии для ответа') && !l.contains('____')).toList()),
          ],
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0FDF4),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ХОРОШО (+)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF166534))),
                      pw.SizedBox(height: 3),
                      _buildNarrowObliqueRuling(rows: 2, rowHeight: 18),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFFFBEB),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ПЛОХО (-)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF92400E))),
                      pw.SizedBox(height: 3),
                      _buildNarrowObliqueRuling(rows: 2, rowHeight: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 7. Карточка «Тестовый выбор с чекбоксами»
  static pw.Widget _buildMultipleChoiceCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Выбери правильный ответ из предложенных';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo600,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ТЕСТОВЫЙ ВЫБОР', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 4),
          pw.Text('Отметь галочкой верный кружок или квадратик.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// 8. Карточка «Предметный счёт YandexART»
  static pw.Widget _buildMathCountingArtCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Сосчитай предметы и запиши число';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF16A34A), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF16A34A),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ПРЕДМЕТНЫЙ СЧЁТ YANDEXART', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF14532D)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0FDF4),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Сколько всего предметов? Запиши число в клетку:',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D))),
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF16A34A), width: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Схема предложения и морфемные рамки (состав слова)
  static pw.Widget _buildSentenceAndMorphemeCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Составь предложение по схеме и разбери слова по составу';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF0284C7), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF0284C7),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • СХЕМА ПРЕДЛОЖЕНИЯ / РАЗБОР СЛОВА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0F9FF),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFBAE6FD), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Графическая модель предложения:', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 55,
                      height: 14,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.indigo900, width: 2),
                          bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 65,
                      height: 14,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 60,
                      height: 14,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      width: 4,
                      height: 4,
                      margin: const pw.EdgeInsets.only(top: 10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.indigo900,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Text('Обозначения морфем:  ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    pw.Text('[приставка]  |  [корень]  |  [суффикс]  |  [окончание]', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Запиши составленное предложение каллиграфически:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          _buildNarrowObliqueRuling(rows: 2, rowHeight: 22.0),
        ],
      ),
    );
  }

  /// 2. Вычислительная цепочка и числовая пирамида
  static pw.Widget _buildMathChainAndPyramidCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Вычислительная цепочка и числовая пирамида';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF7C3AED), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF7C3AED),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ВЫЧИСЛИТЕЛЬНАЯ ЦЕПОЧКА / ПИРАМИДА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // 1. Вычислительная цепочка
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF5F3FF),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFDDD6FE), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Цепочка вычислений:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 26,
                            height: 26,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF7C3AED), width: 1.5),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text('8', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                          ),
                          pw.SizedBox(width: 3),
                          pw.Column(
                            children: [
                              pw.Text('+ 4', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.Text('-->', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                          pw.SizedBox(width: 3),
                          pw.Container(
                            width: 26,
                            height: 26,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: PdfColors.grey400, width: 1.2),
                            ),
                          ),
                          pw.SizedBox(width: 3),
                          pw.Column(
                            children: [
                              pw.Text('- 3', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.Text('-->', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                          pw.SizedBox(width: 3),
                          pw.Container(
                            width: 26,
                            height: 26,
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFFEF3C7),
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFFD97706), width: 1.5),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text('?', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              // 2. Числовая пирамидка (кирпичики)
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF5F3FF),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFDDD6FE), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Числовая пирамида:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 26,
                        height: 18,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFFEF3C7),
                          borderRadius: pw.BorderRadius.circular(3),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFD97706), width: 1.2),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text('?', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 24,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: PdfColors.grey400, width: 1),
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Container(
                            width: 24,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: PdfColors.grey400, width: 1),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 22,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF7C3AED), width: 1.2),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text('2', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                          ),
                          pw.SizedBox(width: 3),
                          pw.Container(
                            width: 22,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF7C3AED), width: 1.2),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text('3', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                          ),
                          pw.SizedBox(width: 3),
                          pw.Container(
                            width: 22,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF7C3AED), width: 1.2),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text('4', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4C1D95))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Графический диктант по клеточкам
  static pw.Widget _buildGraphicDictationCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Графический диктант по клеточкам';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFEA580C), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEA580C),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ГРАФИЧЕСКИЙ ДИКТАНТ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFFF7ED),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFFED7AA), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Алгоритм шагов (от точки СТАРТ):', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          for (final step in ['2 ->', '1 v', '3 ->', '2 ^', '2 ->', '3 v', '1 <-', '2 v', '4 <-', '1 ^'])
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(color: const PdfColor.fromInt(0xFFF97316), width: 0.8),
                              ),
                              child: pw.Text(step, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Что за фигура получилась? Запиши отгадку:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 3),
                      pw.Text('Ответ: _________________________________', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.indigo900)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 140,
                height: 110,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.8),
                ),
                child: pw.Stack(
                  children: [
                    pw.CustomPaint(
                      size: const PdfPoint(140, 110),
                      painter: (canvas, size) {
                        final cellSize = 5.0 * 2.83465;
                        final cols = (size.x / cellSize).floor();
                        final rows = (size.y / cellSize).floor();

                        for (int c = 0; c <= cols; c++) {
                          final x = c * cellSize;
                          canvas.drawLine(x, 0, x, rows * cellSize);
                        }
                        for (int r = 0; r <= rows; r++) {
                          final y = r * cellSize;
                          canvas.drawLine(0, y, cols * cellSize, y);
                        }
                        canvas.setColor(const PdfColor.fromInt(0xFFCBD5E1));
                        canvas.setLineWidth(0.4);
                        canvas.strokePath();

                        final startX = 2 * cellSize;
                        final startY = 2 * cellSize;
                        canvas.drawEllipse(startX, startY, 2.5, 2.5);
                        canvas.setColor(const PdfColor.fromInt(0xFFEA580C));
                        canvas.fillPath();
                      },
                    ),
                    pw.Positioned(
                      left: 32,
                      top: 10,
                      child: pw.Text('СТАРТ *', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Диаграмма Венна / Круги Эйлера
  static pw.Widget _buildVennDiagramCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Диаграмма Венна / Круги Эйлера: распредели понятия';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF0D9488), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF0D9488),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • ДИАГРАММА ВЕННА / КРУГИ ЭЙЛЕРА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0FDFA),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF99F6E4), width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    height: 80,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.horizontal(left: pw.Radius.circular(40)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF0D9488), width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ТОЛЬКО СВОЙСТВО А:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 4),
                        pw.Text('1. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('2. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('3. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    height: 80,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFCCFBF1),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF0F766E), width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('ОБЩЕЕ (И А, И Б):', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 4),
                        pw.Text('* _____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.indigo900)),
                        pw.Text('* _____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.indigo900)),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    height: 80,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.horizontal(right: pw.Radius.circular(40)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF0D9488), width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ТОЛЬКО СВОЙСТВО Б:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 4),
                        pw.Text('1. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('2. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('3. ________________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
            ),
            child: pw.Row(
              children: [
                pw.Text('Банк слов для распределения: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.Expanded(
                  child: pw.Text('выбери из предложенных вариантов и впиши в нужную область диаграммы', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Кластер / Древо понятий (Mind Map)
  static pw.Widget _buildConceptClusterCard(String header, List<String> lines, int num) {
    final sanitized = sanitizeTaskHeader(header);
    final displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Кластер понятий: систематизируй материал';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF4F46E5), width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF4F46E5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num • КЛАСТЕР / ДРЕВО ПОНЯТИЙ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEEF2FF),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFC7D2FE), width: 0.8),
            ),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFF4F46E5),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text('ГЛАВНОЕ ПОНЯТИЕ / ТЕМА', style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('[Группа 1]', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                    pw.Text('[Группа 2]', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                    pw.Text('[Группа 3]', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF818CF8), width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('ВЕТВЬ А', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            pw.SizedBox(height: 3),
                            pw.Text('1. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            pw.Text('2. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF818CF8), width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('ВЕТВЬ Б', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            pw.SizedBox(height: 3),
                            pw.Text('1. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            pw.Text('2. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF818CF8), width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('ВЕТВЬ В', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            pw.SizedBox(height: 3),
                            pw.Text('1. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            pw.Text('2. ____________', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStandardTaskCard(String header, List<String> lines, int num, bool isWorksheet, {bool isMath = false}) {
    final sanitized = sanitizeTaskHeader(header);
    var displayHeader = sanitized.title.isNotEmpty ? sanitized.title : 'Выполни задание';
    final List<String> effectiveLines = List<String>.from(lines);

    // Если в заголовок попал не вопрос, а готовый пример или словосочетание с тире
    if (displayHeader.contains('—') &&
        (displayHeader.toLowerCase().contains('время') ||
            displayHeader.toLowerCase().contains('признак') ||
            displayHeader.toLowerCase().contains('число') ||
            displayHeader.toLowerCase().contains('род '))) {
      effectiveLines.insert(0, displayHeader);
      displayHeader = 'Выполни задание по образцу';
    }

    final fullContent = (header + ' ' + effectiveLines.join(' ')).toLowerCase();
    final bool isRussianOrLanguage = fullContent.contains('слово') ||
        fullContent.contains('букв') ||
        fullContent.contains('предложен') ||
        fullContent.contains('текст') ||
        fullContent.contains('прилагательн') ||
        fullContent.contains('существительн') ||
        fullContent.contains('глагол') ||
        fullContent.contains('орфограмм') ||
        fullContent.contains('звук') ||
        fullContent.contains('слог') ||
        fullContent.contains('падеж') ||
        fullContent.contains('род ') ||
        fullContent.contains('чистописан') ||
        fullContent.contains('пропис') ||
        fullContent.contains('каллиграф') ||
        fullContent.contains('сказк') ||
        fullContent.contains('стихотворен');

    final isMathTask = isMath || (!isRussianOrLanguage &&
        (fullContent.contains('вычисли') ||
            fullContent.contains('реши пример') ||
            fullContent.contains('задач') ||
            fullContent.contains('счет') ||
            fullContent.contains('уравнени') ||
            RegExp(r'\d+\s*[\+\-\*\/]\s*\d+').hasMatch(fullContent)));

    final bool isPureSample = displayHeader.toLowerCase().contains('образец выполнения') && !effectiveLines.any((l) => l.contains('1)') || l.contains('____'));
    final bool alreadyHasAnswerArea = effectiveLines.any((l) {
      final low = l.toLowerCase();
      return low.contains('____') ||
          low.contains('линии для ответа') ||
          low.contains('место для ответа') ||
          (l.trim().startsWith('|') && l.trim().endsWith('|')) ||
          low.contains('[прописи]') ||
          low.contains('[клетка]') ||
          low.contains('[математическая сетка]') ||
          low.contains('[окошки]');
    });

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo600,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('ЗАДАНИЕ $num', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildFormattedText(
                  displayHeader,
                  defaultStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
              ),
            ],
          ),
          if (effectiveLines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(effectiveLines, isMath: isMathTask),
          ],
          if (isWorksheet && !alreadyHasAnswerArea && !isPureSample) ...[
            pw.SizedBox(height: 6),
            if (isMathTask)
              _buildMathGridArea(height: 56)
            else
              _buildNarrowObliqueRuling(rows: 3),
          ],
        ],
      ),
    );
  }

  /// Отображение строк внутри карточки с поддержкой таблиц, списков и полей для ответов
  static pw.Widget _buildLinesContent(List<String> lines, {bool isMath = false}) {
    final List<pw.Widget> widgets = [];
    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Иллюстрация YandexART
      if (line.contains('Иллюстрация YandexART') || line.contains('[Иллюстрация YandexART')) {
        widgets.add(_buildYandexArtPlaceholderCard(line));
        i++;
        continue;
      }

      // Таблицы Markdown
      if (line.startsWith('|') && line.endsWith('|')) {
        final List<String> tableLines = [];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        widgets.add(_buildMarkdownTable(tableLines));
        continue;
      }

      // Интерактивные карточки-буквы для раскрашивания/выбора: [ А ] [ Б ] [ У ] ...
      if (RegExp(r'^(\[\s*[^ \]]+\s*\]\s*){2,}\$').hasMatch(line) ||
          (line.contains('[') && line.contains(']') && RegExp(r'(\[\s*[^ \]]+\s*\]\s*){3,}').hasMatch(line))) {
        final matches = RegExp(r'\[\s*([^\]]+)\s*\]').allMatches(line);
        final items = matches.map((m) => m.group(1)!.trim()).toList();
        if (items.isNotEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in items)
                    pw.Container(
                      constraints: const pw.BoxConstraints(minWidth: 28),
                      height: 28,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFF94A3B8), width: 1),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        _replaceEmojisWithSymbols(item),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
          i++;
          continue;
        }
      }

      // Поля для ответа / пропуски
      if (line.contains('____') || line.toLowerCase().contains('линии для ответа')) {
        widgets.add(KeepTogether(child: _buildAnswerLine(line, isMath: isMath)));
        i++;
        continue;
      }

      // Хронометраж этапа: [Тайминг: ХХ мин]
      final timingMatch = RegExp(r'^\s*\[(?:Тайминг|Время)[:\s]*([^\]]+)\]', caseSensitive: false).firstMatch(line);
      if (timingMatch != null) {
        final timeStr = timingMatch.group(1)?.trim() ?? '';
        final restOfLine = line.substring(timingMatch.end).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.amber600, width: 0.6),
                  ),
                  child: pw.Text(
                    'Время: $timeStr',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                  ),
                ),
                if (restOfLine.isNotEmpty) ...[
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: _buildFormattedText(
                      restOfLine,
                      defaultStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Речь учителя: "Учитель: ..."
      final teacherMatch = RegExp(r'^\s*(?:Учитель|Педагог|Ведущий)[:\s]+(.*)$', caseSensitive: false).firstMatch(line);
      if (teacherMatch != null) {
        final speechText = teacherMatch.group(1)?.trim() ?? '';
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 12,
                  margin: const pw.EdgeInsets.only(right: 6, top: 1),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo600,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.Text('Учитель: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.indigo900)),
                pw.Expanded(
                  child: _buildFormattedText(
                    speechText,
                    defaultStyle: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey900, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Реплика учеников: "Дети: ..." или "Дети хором: ..."
      final studentMatch = RegExp(r'^\s*(?:Дети(?:\s+хором)?|Ученик|Ученики|Ученица|Ответ детей|Предполагаемый ответ)[:\s]+(.*)$', caseSensitive: false).firstMatch(line);
      if (studentMatch != null) {
        final studentText = studentMatch.group(1)?.trim() ?? '';
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0FDFA),
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFCCFBF1), width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 12,
                  margin: const pw.EdgeInsets.only(right: 6, top: 1),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal600,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.Text('Дети: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.teal900)),
                pw.Expanded(
                  child: _buildFormattedText(
                    studentText,
                    defaultStyle: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey900),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Сократовский диалог и перехват ошибки
      final socraticMatch = RegExp(r'^\s*(?:Педагогический перехват ошибки|Сократовский диалог|Разбор ошибки)[:\s]+(.*)$', caseSensitive: false).firstMatch(line);
      if (socraticMatch != null) {
        final errText = socraticMatch.group(1)?.trim() ?? '';
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 3),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFFBEB),
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A), width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 6, top: 1),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber700,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Педагогический перехват ошибки:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.amber900)),
                      pw.SizedBox(height: 2),
                      _buildFormattedText(
                        errText,
                        defaultStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Интерактивные разминки: Физкультминутка / Нейрогимнастика
      final pauseMatch = RegExp(r'^\s*#*\s*(?:Физкультминутка|Пальчиковая гимнастика|Нейрогимнастика|Динамическая пауза|Разминка)[:\s]*(.*)$', caseSensitive: false).firstMatch(line);
      if (pauseMatch != null) {
        final pauseTitle = pauseMatch.group(0)?.replaceAll(RegExp(r'^#+\s*'), '').trim() ?? 'Разминка';
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 3),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0FDF4),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green700,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text('РАЗМИНКА', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _buildFormattedText(
                    pauseTitle,
                    defaultStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Нумерованные пункты списка
      final numMatch = RegExp(r'^(\d+)[\.\)]\s+(.+)$').firstMatch(line);
      if (numMatch != null) {
        final itemNum = numMatch.group(1)!;
        final itemText = numMatch.group(2)!;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 6, top: 1),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.indigo300, width: 0.8),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    itemNum,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                  ),
                ),
                pw.Expanded(
                  child: _buildFormattedText(
                    itemText,
                    defaultStyle: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey900),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Маркированные списки
      final bulletMatch = RegExp(r'^[-*•]\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final bulletText = bulletMatch.group(1)!;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 6, top: 1.5, bottom: 1.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(right: 6, top: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo600,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: _buildFormattedText(
                    bulletText,
                    defaultStyle: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Обычный текст
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: _buildFormattedText(
            line,
            defaultStyle: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
          ),
        ),
      );
      i++;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Парсер и отрисовщик красивых таблиц
  static pw.Widget _buildMarkdownTable(List<String> tableLines) {
    if (tableLines.isEmpty) return pw.SizedBox();

    final List<List<String>> rows = [];
    for (final line in tableLines) {
      if (RegExp(r'^\|[\s\-:]+\|$').hasMatch(line) || line.contains('---')) {
        continue;
      }
      final cells = line
          .split('|')
          .map((c) => c.trim())
          .toList();
      if (cells.isNotEmpty && cells.first.isEmpty) cells.removeAt(0);
      if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
      if (cells.isNotEmpty) {
        rows.add(cells);
      }
    }

    if (rows.isEmpty) return pw.SizedBox();

    final headerRow = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    // Обеспечиваем достаточный запас строк (минимум 5 строк) для записи всех слов распределения
    final displayDataRows = List<List<String>>.from(dataRows);
    while (displayDataRows.length < 5) {
      displayDataRows.add(List.filled(headerRow.length, ''));
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.indigo200, width: 0.8),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
            children: [
              for (final header in headerRow)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    _replaceEmojisWithSymbols(header),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),
            ],
          ),
          for (final row in displayDataRows)
            pw.TableRow(
              children: [
                for (int c = 0; c < headerRow.length; c++)
                  pw.Container(
                    height: 28,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      c < row.length ? _replaceEmojisWithSymbols(row[c]) : '',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Карточка дидактической иллюстрации YandexART
  static pw.Widget _buildYandexArtPlaceholderCard(String label) {
    final cleanLabel = _replaceEmojisWithSymbols(label).replaceAll('[', '').replaceAll(']', '').trim();
    final lower = cleanLabel.toLowerCase();
    final isColoring = lower.contains('раскраск') || lower.contains('контур') || lower.contains('моторика');
    final isMath = lower.contains('счет') || lower.contains('счёт') || lower.contains('чисел');
    final isPhonetic = lower.contains('звук') || lower.contains('фонетическ') || lower.contains('букв');

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4),
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF16A34A),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'YANDEXART • ДИДАКТИЧЕСКИЙ РИСУНОК',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                cleanLabel,
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: isColoring ? 58 : 46,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFCBD5E1),
                width: 0.8,
                style: pw.BorderStyle.dashed,
              ),
            ),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  isColoring
                      ? '[Контурный рисунок YandexART для раскрашивания и штриховки]'
                      : (isMath
                          ? '[Наглядные предметы для пересчета: сосчитай и запиши число]'
                          : (isPhonetic
                              ? '[Предметные карточки YandexART для звукового анализа]'
                              : '[Дидактическая сюжетная иллюстрация YandexART к условию]')),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Место для визуального анализа и выполнения задания учеником',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Линия для ответа ученика
  static pw.Widget _buildAnswerLine(String line, {bool isMath = false}) {
    final cleanLine = _replaceEmojisWithSymbols(line);
    final prefix = cleanLine.replaceAll(RegExp(r'_{2,}'), '').trim();
    final lower = prefix.toLowerCase();
    
    // Клетки 5х5 мм — для математики (предмет математика либо математические маркеры).
    // Для русского языка, чтения, прописей и общих ответов ВСЕГДА используется частая косая линейка 65°!
    final bool isPureMath = isMath ||
        ((lower.contains('вычисли') ||
            lower.contains('реши пример') ||
            lower.contains('найди значение') ||
            lower.contains('математическ') ||
            RegExp(r'^\s*решение\s*[\:\=]?\s*$').hasMatch(lower) ||
            RegExp(r'^\s*[\d\+\-\*\/\=\(\)\s]{4,}\s*$').hasMatch(prefix)) &&
        !lower.contains('слово') &&
        !lower.contains('букв') &&
        !lower.contains('предложен') &&
        !lower.contains('текст') &&
        !lower.contains('род') &&
        !lower.contains('падеж'));

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (prefix.isNotEmpty) ...[
            _buildFormattedText(
              prefix,
              defaultStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 3),
          ],
          if (isPureMath)
            _buildMathGridArea(height: 56)
          else
            _buildNarrowObliqueRuling(rows: 3),
        ],
      ),
    );
  }

  static pw.Widget _buildCalloutBox({
    required String tag,
    required String title,
    required String content,
    required PdfColor bgColor,
    required PdfColor borderColor,
    required PdfColor titleColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 7),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _withOpacity(borderColor, 0.18),
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: _withOpacity(borderColor, 0.4), width: 0.6),
                ),
                child: pw.Text(
                  tag,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              content,
              style: const pw.TextStyle(
                fontSize: 10,
                lineSpacing: 1.35,
                color: PdfColors.grey900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Бейдж уровня сложности (чистый вектор, без эмодзи)
  static pw.Widget _buildDifficultyBadge(
    String tierLabel,
    String title,
    PdfColor bgColor,
    PdfColor textColor,
    PdfColor borderColor,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: pw.BoxDecoration(
              color: _withOpacity(borderColor, 0.2),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              tierLabel,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          if (title.isNotEmpty && title != tierLabel) ...[
            pw.SizedBox(width: 8),
            pw.Text(
              _stripEmojis(title),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Рабочая зона "Место для ответа ученика" - улучшенный дизайн с чистым полем для письма
  static Future<pw.Widget> _buildStudentWorkArea({String workMaterial = ''}) async {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16, bottom: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.blue100,
            blurRadius: 6,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Заголовок зоны для ответа (светлый и ненавязчивый)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(12),
                topRight: pw.Radius.circular(12),
              ),
              border: pw.Border.all(color: PdfColors.blue200, width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue400,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '✎',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Рабочее поле ученика',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
          
          // Описание задания (если есть)
          if (workMaterial.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Text(
                workMaterial,
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 1.6,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          
          // Поле для письма с аккуратными линиями
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: pw.Column(
              children: [
                // Линии для письма с промежутками
                for (int i = 0; i < 8; i++)
                  pw.Container(
                    margin: i == 0 ? pw.EdgeInsets.zero : const pw.EdgeInsets.only(top: 16),
                    height: 1.2,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.blue300,
                          width: 1.0,
                          style: pw.BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Подсказка для ученика (светлая)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(12),
                bottomRight: pw.Radius.circular(12),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Пиши аккуратно',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blue600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.Text(
                  'Строки для ответа',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blue600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Профессиональный блок самооценки и рефлексии
  static pw.Widget _buildSelfAssessmentBox() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 16),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.amber50, PdfColors.orange50],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.amber400, width: 1.2),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 4,
            offset: const PdfPoint(1, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Заголовок блока
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber500,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '✓',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  'РЕФЛЕКСИЯ И САМООЦЕНКА',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Описание
          pw.Text(
            'Оцени свой прогресс и эмоции после занятия:',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey800,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 12),
          
          // Карточки оценки
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildEnhancedAssessmentCard('□ Отлично!', 'Справился легко', PdfColors.green500),
              _buildEnhancedAssessmentCard('□ Хорошо', 'Потребовались усилия', PdfColors.blue500),
              _buildEnhancedAssessmentCard('□ Помощь', 'Нужна поддержка', PdfColors.orange500),
            ],
          ),
          pw.SizedBox(height: 14),
          
          // Настроение
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.amber200, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '💭 МОЁ НАСТРОЕНИЕ ПОСЛЕ ЗАНЯТИЯ:',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMoodOption('□ Восторг', PdfColors.green400),
                    _buildMoodOption('□ Спокойствие', PdfColors.blue400),
                    _buildMoodOption('□ Задумчивость', PdfColors.purple400),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          
          // Подпись и дата
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Подпись ученика:',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Container(
                    width: 120,
                    height: 1,
                    margin: const pw.EdgeInsets.only(top: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey500,
                          width: 0.7,
                          style: pw.BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Дата:',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Container(
                    width: 80,
                    height: 1,
                    margin: const pw.EdgeInsets.only(top: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey500,
                          width: 0.7,
                          style: pw.BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Улучшенная карточка оценки
  static pw.Widget _buildEnhancedAssessmentCard(String mark, String label, PdfColor color) {
    return pw.Container(
      width: 80,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _withOpacity(color, 0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _withOpacity(color, 0.3), width: 1),
        boxShadow: [
          pw.BoxShadow(
            color: _withOpacity(PdfColors.grey400, 0.2),
            blurRadius: 3,
            offset: const PdfPoint(0, 1),
          ),
        ],
      ),
      child: pw.Column(
        children: [
          pw.Text(
            mark,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Опция настроения
  static pw.Widget _buildMoodOption(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: pw.BoxDecoration(
        color: _withOpacity(color, 0.1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          color: color,
        ),
      ),
    );
  }

  /// Шаг 3: Экспорт раздаточных карточек в формате А4 (сетка 2x3 карточки с полями для вырезания)
  static Future<void> exportCardsPdf({
    required List<PrintableCard> cards,
    required String lessonTitle,
    String? methodName,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();
    final fontItalic = await _loadRobotoItalic();

    // Разбиваем карточки на страницы по 6 штук (2 колонки x 3 ряда)
    const cardsPerPage = 6;
    for (int i = 0; i < cards.length; i += cardsPerPage) {
      final end = (i + cardsPerPage < cards.length) ? i + cardsPerPage : cards.length;
      final pageCards = cards.sublist(i, end);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            italic: fontItalic,
            fontFallback: [fontRegular, fontBold],
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Шапка страницы распечатки
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Раздаточные карточки: $lessonTitle',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                        ),
                        if (methodName != null && methodName.isNotEmpty)
                          pw.Text(
                            'Методика: $methodName',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Лист для вырезания А4 (2x3)',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Сетка карточек 2 колонки x 3 ряда
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: pageCards.map((card) {
                      return _buildPrintableCardItem(card);
                    }).toList(),
                  ),
                ),

                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Разрежьте по пунктирным линиям. Рекомендуется наклеить на плотный картон.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await _shareOrDownloadPdf(
      bytes: await pdf.save(),
      filename: 'Карточки_${lessonTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Виджет табличного задания (грибы, леса, моря) с сеткой ячеек
  static pw.Widget _buildTableTask(Map<String, dynamic> params) {
    final theme = (params['theme'] ?? 'Таблица').toString();
    final rows = (params['rows'] as List<dynamic>? ?? []);

    if (rows.isEmpty) {
      return pw.Container();
    }

    final firstRow = rows[0] as Map<dynamic, dynamic>;
    final keys = firstRow.keys.toList();
    final colCount = keys.length;

    final tableBody = <List<pw.Widget>>[];

    // Заголовок
    tableBody.add(keys.map((k) => _tableCell(k.toString(), isHeader: true)).toList());

    // Данные
    for (final row in rows) {
      final mapRow = row as Map<dynamic, dynamic>;
      tableBody.add(keys.map((k) => _tableCell(mapRow[k]?.toString() ?? '', isHeader: false)).toList());
    }

    final colWidth = List.filled(colCount, 1.0 / colCount);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.green200, width: 0.8),
            ),
            child: pw.Text(
              theme,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.green400, width: 0.8),
            columnWidths: Map.fromIterable(
              List.generate(colCount, (i) => i),
              value: (i) => pw.FractionColumnWidth(colWidth[i as int]),
            ),
            children: tableBody.asMap().entries.map((entry) {
              final idx = entry.key;
              final cells = entry.value;
              return pw.TableRow(
                decoration: idx % 2 == 0
                    ? pw.BoxDecoration(color: const PdfColor(0.92, 0.99, 0.96))
                    : null,
                children: cells,
              );
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 8),
            height: 1.0,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.green300,
                  width: 0.8,
                  style: pw.BorderStyle.solid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Клеточный кроссворд (без линий) — сетка ячеек с нумерацией
  static pw.Widget _buildCrosswordGrid(Map<String, dynamic> params) {
    final gridSize = (params['gridSize'] ?? 10) as int;
    final cells = (params['cells'] as List<dynamic>? ?? []);
    final cluesAcross = (params['cluesAcross'] as List<dynamic>? ?? []);
    final cluesDown = (params['cluesDown'] as List<dynamic>? ?? []);

    final cellSize = 22.0;

    final gridRows = <pw.Widget>[];
    for (int r = 0; r < gridSize; r++) {
      final rowCells = <pw.Widget>[];
      for (int c = 0; c < gridSize; c++) {
        final cellIndex = r * gridSize + c;
        final cellData = cellIndex < cells.length ? cells[cellIndex] : null;
        final isBlack = cellData != null &&
            (cellData as Map).containsKey('black') &&
            (cellData as Map)['black'] == true;
        final number = cellData != null && (cellData as Map).containsKey('number')
            ? (cellData as Map)['number']
            : null;

        rowCells.add(
          pw.Container(
            width: cellSize,
            height: cellSize,
            decoration: pw.BoxDecoration(
              color: isBlack ? PdfColors.black : PdfColors.white,
              border: pw.Border.all(color: PdfColors.black, width: 0.6),
            ),
            child: isBlack
                ? null
                : pw.Stack(
                    children: [
                      if (number != null)
                        pw.Positioned(
                          left: 1,
                          top: 1,
                          child: pw.Text(
                            number.toString(),
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      pw.Center(
                        child: pw.Container(
                          width: 10,
                          height: 10,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.grey300, width: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }
      gridRows.add(pw.Row(children: rowCells, mainAxisAlignment: pw.MainAxisAlignment.center));
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo300, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Кроссворд клетками',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Column(children: gridRows),
          pw.SizedBox(height: 10),
          if (cluesAcross.isNotEmpty) ...[
            pw.Text(
              'По горизонтали:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
            pw.SizedBox(height: 4),
            ...cluesAcross.asMap().entries.map((e) {
              final idx = e.key;
              final clue = e.value.toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3, left: 8),
                child: pw.Text(
                  '${idx + 1}. $clue',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              );
            }),
          ],
          pw.SizedBox(height: 8),
          if (cluesDown.isNotEmpty) ...[
            pw.Text(
              'По вертикали:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
            pw.SizedBox(height: 4),
            ...cluesDown.asMap().entries.map((e) {
              final idx = e.key;
              final clue = e.value.toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3, left: 8),
                child: pw.Text(
                  '${idx + 1}. $clue',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Задание с буквами и разлиновкой (прописные/строчные буквы)
  static pw.Widget _buildLetterTask(Map<String, dynamic> params) {
    final letter = (params['letter'] ?? 'А').toString();
    final words = (params['words'] as List<dynamic>? ?? []);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.purple300, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 36,
                height: 36,
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.purple200, width: 0.8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    letter,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple800,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  'Буква «$letter»',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 28,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.purple300,
                  width: 0.8,
                  style: pw.BorderStyle.solid,
                ),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                letter,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple600,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          for (int i = 0; i < 4; i++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              height: 1.0,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.purple200,
                    width: 0.6,
                    style: pw.BorderStyle.solid,
                  ),
                ),
              ),
            ),
          if (words.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Слова для практики:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.take(4).map((w) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor(0.96, 0.95, 1.0),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.purple200, width: 0.6),
                  ),
                  child: pw.Text(
                    w.toString(),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.purple800),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Обёртка любого практического задания с бейджем уровня сложности
  static pw.Widget _buildPracticalTaskWrapper(
    pw.Widget child, {
    required String level,
    required String title,
  }) {
    final levelConfig = _getLevelConfig(level);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildDifficultyBadge(
            levelConfig['label'] as String,
            title,
            levelConfig['bgColor'] as PdfColor,
            levelConfig['textColor'] as PdfColor,
            levelConfig['borderColor'] as PdfColor,
          ),
          pw.SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  static Map<String, dynamic> _getLevelConfig(String level) {
    switch (level) {
      case '1':
        return {
          'label': 'Уровень 1 • Старт',
          'bgColor': PdfColors.blue50,
          'textColor': PdfColors.blue800,
          'borderColor': PdfColors.blue300,
        };
      case '2':
        return {
          'label': 'Уровень 2 • Практик',
          'bgColor': PdfColors.amber50,
          'textColor': PdfColors.amber800,
          'borderColor': PdfColors.amber300,
        };
      case '3':
        return {
          'label': 'Уровень 3 • Детектив Pro',
          'bgColor': PdfColors.purple50,
          'textColor': PdfColors.purple800,
          'borderColor': PdfColors.purple300,
        };
      default:
        return {
          'label': 'Уровень 1 • Старт',
          'bgColor': PdfColors.blue50,
          'textColor': PdfColors.blue800,
          'borderColor': PdfColors.blue300,
        };
    }
  }

  /// Ячейка таблицы с отступами и выравниванием
  static pw.Widget _tableCell(String text, {required bool isHeader}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.green800 : PdfColors.black,
        ),
      ),
    );
  }

  /// Виджет одной карточки с пунктирной рамкой и полями для вырезания
  static pw.Widget _buildPrintableCardItem(PrintableCard card) {
    pw.MemoryImage? cardImage;
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      try {
        final clean = card.imageUrl!.contains(',') ? card.imageUrl!.split(',').last : card.imageUrl!;
        cardImage = pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: PdfColors.grey600,
          width: 1.0,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Верх: тип карточки и ножницы
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: cardImage != null ? PdfColors.amber50 : PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(
                    color: cardImage != null ? PdfColors.amber300 : PdfColors.indigo200,
                    width: 0.5,
                  ),
                ),
                child: pw.Text(
                  cardImage != null
                      ? 'PRO • ${PrintableCard.getTypeLabel(card.type).toUpperCase()}'
                      : PrintableCard.getTypeLabel(card.type).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: cardImage != null ? PdfColors.amber900 : PdfColors.indigo800,
                  ),
                ),
              ),
              pw.Text(
                '-- вырезать --',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
              ),
            ],
          ),

          // Центр: если есть картинка YandexART - выводим ее над текстом
          pw.Expanded(
            child: cardImage != null
                ? pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 72,
                        child: pw.Image(cardImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _stripEmojis(card.frontText),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: card.frontText.length <= 4 ? 20 : 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ],
                  )
                : pw.Center(
                    child: pw.Text(
                      _stripEmojis(card.frontText),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: card.frontText.length <= 4 ? 32 : (card.frontText.length <= 12 ? 22 : 14),
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                  ),
          ),

          // Низ: подсказка / образ / оборотная сторона
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (card.imageHint != null && card.imageHint!.isNotEmpty)
                  pw.Text(
                    'Образ: ${_stripEmojis(card.imageHint!)}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                    maxLines: 1,
                  ),
                if (card.backText.isNotEmpty)
                  pw.Text(
                    'Подсказка: ${_stripEmojis(card.backText)}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pro-блок раскраски для рабочего листа
  static pw.Widget _buildProColoringSection(String? coloringBase64, {pw.MemoryImage? fallbackImage}) {
    pw.MemoryImage? img;
    if (coloringBase64 != null && coloringBase64.isNotEmpty) {
      try {
        final clean = coloringBase64.contains(',') ? coloringBase64.split(',').last : coloringBase64;
        img = pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }
    img ??= fallbackImage;

    if (img == null) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16, bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo300, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Творческая разминка: раскрась по образцу',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
                ),
                child: pw.Text(
                  'YandexART Pro',
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColors.indigo800, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Container(
              height: 130,
              child: pw.Image(img, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Инструкция: раскрасьте аккуратно цветными карандашами, не выходя за контуры.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Pro-блок наградной медали / стикера для домашнего задания
  static pw.Widget _buildProRewardSection(String? rewardBase64, {pw.MemoryImage? fallbackImage}) {
    pw.MemoryImage? img;
    if (rewardBase64 != null && rewardBase64.isNotEmpty) {
      try {
        final clean = rewardBase64.contains(',') ? rewardBase64.split(',').last : rewardBase64;
        img = pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }
    img ??= fallbackImage;

    if (img == null) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber300, width: 1, style: pw.BorderStyle.dashed),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 56,
            height: 56,
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Знак отличия: «Успешно пройдено!»',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                    ),
                    pw.Text(
                      '-- вырезать наклейку --',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.amber700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Педагог или родитель может вырезать эту памятную медаль и наклеить в тетрадь ученика за прилежно выполненную работу.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @visibleForTesting
  static pw.Widget buildPdfTitleForTest(
    Conspect conspect,
    PdfMaterialType type,
    pw.MemoryImage? materialIcon, {
    bool isPro = true,
    pw.MemoryImage? mascotImage,
    ThematicWorld? world,
    pw.MemoryImage? bannerImage,
  }) =>
      _buildPdfTitle(
        conspect,
        type,
        materialIcon,
        isPro: isPro,
        mascotImage: mascotImage,
        world: world,
        bannerImage: bannerImage,
      );

  @visibleForTesting
  static pw.Widget buildMaterialInfoForTest(Conspect conspect, PdfMaterialType type) =>
      _buildMaterialInfo(conspect, type);

  @visibleForTesting
  static List<pw.Widget> buildContentWidgetsForTest(
    String content,
    pw.Font regular,
    pw.Font bold,
    Map<String, pw.MemoryImage?> sectionIcons, {
    pw.MemoryImage? starGold,
    pw.MemoryImage? starGray,
    bool isWorksheetOrHomework = false,
  }) =>
      _buildContentWidgets(content, regular, bold, sectionIcons, starGold: starGold, starGray: starGray, isWorksheetOrHomework: isWorksheetOrHomework);


  /// Генерация PDF-байтов карточки итога урока в премиальном executive-дизайне Mobbin
  static Future<Uint8List> generateLessonSummaryPdfBytes(
    LessonSummaryCard card, {
    ThematicWorld? world,
    String? methodology,
  }) async {
    final pdf = pw.Document();
    final effectiveWorld = world ?? ThematicWorld.fromId(card.thematicWorldId);

    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();
    final fontItalic = await _loadRobotoItalic();

    final mascotImage = await _loadWorldMascot(effectiveWorld, null);

    final worldPrimary = effectiveWorld.pdfPrimary;
    final worldSecondary = effectiveWorld.pdfSecondary;
    final worldAccent = effectiveWorld.pdfAccent;

    final bgLight = _withOpacity(worldSecondary, 0.08);
    final borderCol = _withOpacity(worldPrimary, 0.35);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Header Banner (Mobbin Minimalist Executive)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: borderCol, width: 1.2),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: worldPrimary,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  'МЕТОДИСТ PRO • КАРТОЧКА ИТОГА УРОКА',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: _withOpacity(worldAccent, 0.2),
                                  borderRadius: pw.BorderRadius.circular(4),
                                  border: pw.Border.all(color: worldAccent, width: 0.8),
                                ),
                                child: pw.Text(
                                  _replaceEmojisWithSymbols(effectiveWorld.title),
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: worldPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            _replaceEmojisWithSymbols(card.topic),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Ученик / Класс: ${_replaceEmojisWithSymbols(card.studentOrClass)}  |  Дата: ${DateFormat('dd.MM.yyyy').format(card.date)}  |  Методика: ${methodology != null && methodology.isNotEmpty ? _replaceEmojisWithSymbols(methodology) : "ФГОС НОО"}',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mascotImage != null) ...[
                      pw.SizedBox(width: 12),
                      pw.Container(
                        width: 48,
                        height: 48,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: worldAccent, width: 2),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(mascotImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // 2. Executive KPI Scoreboard (3 Mobbin Stat Tiles)
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ОБЩИЙ БАЛЛ УСВОЕНИЯ',
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Text(
                                '${card.averageScore.toStringAsFixed(1)}',
                                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: worldPrimary),
                              ),
                              pw.Text(' / 5.0', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Spacer(),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: worldPrimary,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  '${card.masteryPercent}%',
                                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'СТАТУС ПО ФГОС',
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _replaceEmojisWithSymbols(card.academicStatus),
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ДОМАШНЕЕ ЗАДАНИЕ',
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _replaceEmojisWithSymbols(card.homeworkAssigned),
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: worldPrimary),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // 3. Criteria Table with Progress Bars
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ОЦЕНКА УСВОЕНИЯ ПО КРИТЕРИЯМ (1 - 5)',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: worldPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    ...card.criteriaScores.entries.map((entry) {
                      final val = entry.value.clamp(1, 5);
                      final progress = val / 5.0;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 6,
                              child: pw.Text(
                                _replaceEmojisWithSymbols(entry.key),
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              width: 110,
                              height: 6,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Row(
                                children: [
                                  pw.Container(
                                    width: 110 * progress,
                                    height: 6,
                                    decoration: pw.BoxDecoration(
                                      color: val >= 4 ? worldPrimary : (val == 3 ? PdfColors.amber700 : PdfColors.red700),
                                      borderRadius: pw.BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              width: 28,
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                '$val / 5',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              // 4. Tags & Observations Pill Cloud
              if (card.tags.isNotEmpty || card.teacherNotes.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ПОМЕТКИ И НАБЛЮДЕНИЯ УЧИТЕЛЯ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: worldPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (card.tags.isNotEmpty)
                        pw.Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: card.tags.map((t) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: _withOpacity(worldSecondary, 0.12),
                                borderRadius: pw.BorderRadius.circular(10),
                                border: pw.Border.all(color: _withOpacity(worldPrimary, 0.3), width: 0.6),
                              ),
                              child: pw.Text(
                                _replaceEmojisWithSymbols(t),
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: worldPrimary),
                              ),
                            );
                          }).toList(),
                        ),
                      if (card.teacherNotes.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            border: pw.Border(left: pw.BorderSide(color: worldPrimary, width: 2.5)),
                          ),
                          child: pw.Text(
                            _replaceEmojisWithSymbols(card.teacherNotes),
                            style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              // 5. MetodistPRO AI Reflection Box
              if (card.aiReflection != null && card.aiReflection!.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _withOpacity(PdfColors.indigo50, 0.7),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _withOpacity(PdfColors.indigo400, 0.4), width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ПЕДАГОГИЧЕСКИЙ АНАЛИЗ AI-НАСТАВНИКА СОВЁНКА (METODISTPRO)',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _replaceEmojisWithSymbols(card.aiReflection!),
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey900,
                          lineSpacing: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              // 6. Parent Chat Announcement (WhatsApp/TG)
              if (card.parentChatMessage != null && card.parentChatMessage!.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green300, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ТЕКСТ ДЛЯ РОДИТЕЛЬСКОГО ЧАТА (WHATSAPP / TELEGRAM)',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _replaceEmojisWithSymbols(card.parentChatMessage!),
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey800,
                          lineSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              pw.Spacer(),

              // 7. Executive Footer & Stamp
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Методист Pro • Цифровая образовательная экосистема • MetodistPRO & YandexART',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Подпись учителя: _________________  Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Экспорт и распечатка PDF карточки итога урока
  static Future<void> exportLessonSummaryPdf(
    LessonSummaryCard card, {
    ThematicWorld? world,
    String? methodology,
  }) async {
    final bytes = await generateLessonSummaryPdfBytes(card, world: world, methodology: methodology);
    final filename = 'lesson_summary_${card.topic.replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-Я]'), '_')}.pdf';
    await _shareOrDownloadPdf(bytes: bytes, filename: filename);
  }

  /// Генерация Eco-Print 2-в-1 PDF: две идентичные карточки формата А5 на одном листе А4 (альбомная ориентация)
  static Future<Uint8List> generateEcoPrint2in1PdfBytes(Conspect conspect) async {
    final pdf = pw.Document();

    final fontRegular = await _loadRobotoRegular();
    final fontBold = await _loadRobotoBold();

    // Извлекаем правило и текст заданий
    String ruleText = 'Рассуждай по шагам, применяй главное правило и проверяй ответ!';
    final lines = conspect.content.split('\n');
    final extractedTasks = <String>[];
    String? pisaCase = PromptBuilder.extractPisaLifeCase(conspect.content);

    bool inRule = false;
    final ruleBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().contains('главное правило')) {
        inRule = true;
        continue;
      }
      if (inRule) {
        if (trimmed.startsWith('#') || (trimmed.isEmpty && ruleBuffer.isNotEmpty)) {
          inRule = false;
        } else if (trimmed.isNotEmpty) {
          ruleBuffer.writeln(trimmed);
        }
      }

      if (trimmed.startsWith('**Задание') || trimmed.startsWith('#### Задание') || trimmed.startsWith('Задание 1:') || trimmed.startsWith('Задание 2:') || trimmed.startsWith('Задание 3:') || trimmed.startsWith('Задание 4:')) {
        extractedTasks.add(trimmed.replaceAll('*', ''));
      }
    }

    if (ruleBuffer.isNotEmpty) {
      ruleText = ruleBuffer.toString().trim();
      if (ruleText.length > 140) {
        ruleText = '${ruleText.substring(0, 137)}...';
      }
    }

    final taskItems = extractedTasks.isNotEmpty
        ? extractedTasks.take(4).toList()
        : [
            '1. Старт: Выполни образец по указанию учителя у доски.',
            '2. Практик: Заполни таблицу соответствий в тетради.',
            '3. Ловушка Незнайки: Найди ошибку и обоснуй верный ответ.',
          ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold],
        ),
        build: (context) {
          pw.Widget buildCardHalf(String studentNumber) {
            return pw.Container(
              width: 380,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'РАБОЧИЙ ЛИСТ • ЭКО-ФОРМАТ А5',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            constraints: const pw.BoxConstraints(maxWidth: 260),
                            child: pw.Text(
                              conspect.title,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.indigo50,
                          border: pw.Border.all(color: PdfColors.indigo700, width: 0.6),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          conspect.ageGroup,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Text('Ученик: __________________________', style: const pw.TextStyle(fontSize: 8)),
                      pw.Spacer(),
                      pw.Text('Дата: __________', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'Правило: $ruleText',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      maxLines: 2,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        ...taskItems.map((item) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Text(
                                item,
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
                                maxLines: 2,
                              ),
                            )),
                        if (pisaCase != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.all(5),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.teal50,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                            ),
                            child: pw.Text(
                              '🌍 Жизненный кейс (PISA): ${pisaCase.length > 150 ? pisaCase.substring(0, 147) + "..." : pisaCase}',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.teal900),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Самопроверка: ⭐ ⭐ ⭐', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text('🌱 Eco-Print: 2 ученика на 1 лист А4', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            );
          }

          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              buildCardHalf('1'),
              pw.Container(
                width: 32,
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('✁', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    ...List.generate(16, (i) => pw.Container(
                          width: 1,
                          height: 14,
                          margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
                          color: PdfColors.grey400,
                        )),
                    pw.SizedBox(height: 4),
                    pw.Text('✁', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
              ),
              buildCardHalf('2'),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Экспорт и распечатка Eco-Print 2-в-1 PDF
  static Future<void> exportEcoPrint2in1Pdf(Conspect conspect) async {
    final bytes = await generateEcoPrint2in1PdfBytes(conspect);
    final filename = 'eco_print_2in1_${conspect.topic.replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-Я]'), '_')}.pdf';
    await _shareOrDownloadPdf(bytes: bytes, filename: filename);
  }
}
