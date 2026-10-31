import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/services/yandex_art_service.dart';
import 'package:metodist/models/printable_card.dart';
import 'package:metodist/services/pdf_icons_helper.dart';

/// Типы материалов для генерации
enum PdfMaterialType {
  conspect,    // Основной конспект занятия
  worksheet,   // Лист заданий для печати
  homework     // Домашняя работа
}

class PdfExportService {
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



  /// Экспорт отдельного материала (конспект, лист заданий или домашняя работа)
  static Future<void> exportMaterialPdf(Conspect conspect, PdfMaterialType type, {bool isPro = false}) async {
    await _exportSinglePdf(conspect, type, isPro: isPro);
  }

  /// Экспорт полного комплекта материалов (где каждый материал гарантированно с нового листа)
  static Future<void> exportAllMaterialsCombinedPdf(Conspect conspect, {bool isPro = false}) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final world = conspect.thematicWorld;
    final mascotImage = await _loadWorldMascot(world, conspect.illustrationMascot);
    final bannerImage = await _loadWorldBanner(world);
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
        margin: const pw.EdgeInsets.fromLTRB(44, 24, 24, 24),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
        ),
        header: (context) => _buildPdfHeader(conspect, PdfMaterialType.conspect, isPro: isPro),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (isPro)
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
          _buildPdfTitle(conspect, PdfMaterialType.conspect, null, isPro: isPro, mascotImage: mascotImage, bannerImage: bannerImage),
          pw.SizedBox(height: 10),
          _buildMaterialInfo(conspect, PdfMaterialType.conspect),
          pw.SizedBox(height: 12),
          ..._buildContentWidgets(
            conspect.content,
            fontRegular,
            fontBold,
            sectionIcons,
            starGold: starGold,
            starGray: starGray,
            isWorksheetOrHomework: false,
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Комплект_${conspect.title.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Exports conspect to formatted PDF document and opens print/share dialog
  static Future<void> exportAndSharePdf(Conspect conspect, {bool isPro = false}) async {
    if (conspect.generatedMaterials.length <= 1) {
      await _exportSinglePdf(conspect, PdfMaterialType.conspect, isPro: isPro);
    } else {
      await exportAllMaterialsCombinedPdf(conspect, isPro: isPro);
    }
  }

  /// Экспорт отдельного PDF по типу материала
  static Future<void> _exportSinglePdf(Conspect conspect, PdfMaterialType type, {bool isPro = false}) async {
    final pdf = pw.Document();

    // Load Cyrillic-compatible Google Font (Roboto)
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    // Извлекаем только нужную часть контента строго в зависимости от типа материала
    final filteredContent = _extractMaterialContent(conspect.content, type);
    if (filteredContent.isEmpty) {
      final label = _getMaterialLabel(type);
      throw Exception('Материал «$label» не был сформирован в этом конспекте.');
    }

    // Загружаем иконку для типа материала, маскота и звезд
    final materialTypeName = type.toString().split('.').last;
    final materialIconName = PdfIconsHelper.getMaterialIconName(materialTypeName);
    final materialIcon = await PdfIconsHelper.loadIcon(materialIconName);
    final world = conspect.thematicWorld;
    final mascotImage = await _loadWorldMascot(world, conspect.illustrationMascot);
    final bannerImage = await _loadWorldBanner(world);
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
        margin: const pw.EdgeInsets.fromLTRB(44, 24, 24, 24),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          fontFallback: [fontRegular, fontBold],
        ),
        header: (context) => _buildPdfHeader(conspect, type, isPro: isPro),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (isPro)
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
          // Премиум шапка с маскотом
          _buildPdfTitle(conspect, type, materialIcon, isPro: isPro, mascotImage: mascotImage, bannerImage: bannerImage),
          pw.SizedBox(height: 10),

          // Информация о материале и поля ученика
          _buildMaterialInfo(conspect, type),
          pw.SizedBox(height: 12),

          // Основной структурированный контент (неразрывные задания)
          ..._buildContentWidgets(
            filteredContent,
            fontRegular,
            fontBold,
            sectionIcons,
            starGold: starGold,
            starGray: starGray,
            isWorksheetOrHomework: type != PdfMaterialType.conspect,
          ),

          // Pro: Творческая разминка / раскраска для рабочего листа
          if (isPro && type == PdfMaterialType.worksheet && conspect.illustrationColoring != null)
            _buildProColoringSection(conspect.illustrationColoring!),

          // Pro: Наградной стикер / медаль для домашней работы
          if (isPro && type == PdfMaterialType.homework && conspect.illustrationReward != null)
            _buildProRewardSection(conspect.illustrationReward!),
        ],
      ),
    );

    // Share/print the generated PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: _getPdfFilename(conspect.title, type),
    );
  }

  /// Старый метод для обратной совместимости
  static Future<void> _exportLegacyPdf(Conspect conspect) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

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
    await Printing.sharePdf(
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
    'лист заданий',
    'рабочий лист',
    'раздаточный лист',
    'раздаточный материал',
  ];

  static final List<String> _homeworkKeywords = [
    'домашнее задание',
    'домашняя работа',
    'задания на дом',
    'блок дополнительных заданий',
    'домашка',
  ];

  static final List<String> _cardsKeywords = [
    'карточки для занятия',
    'раздаточные карточки',
    '```json',
  ];

  static int _findSectionStartIndex(String text, List<String> keywords, [int startFrom = 0]) {
    final lower = text.toLowerCase();
    int minIndex = -1;

    for (final kw in keywords) {
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

  /// Проверяет наличие конкретного материала в тексте
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
  static pw.Widget _buildPdfHeader(Conspect conspect, PdfMaterialType type, {bool isPro = false}) {
    final headerText = _getMaterialHeaderText(type);
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
          if (isPro)
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
            '$headerText: ${conspect.methodName} — ${conspect.subject}',
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

    final assetIcon = await PdfIconsHelper.loadIcon('mascot_${world.id}');
    if (assetIcon != null) return assetIcon;

    try {
      final base64Png = await YandexArtService.generateFallbackEducationalArt(
        type: 'world_mascot_${world.id}',
        label: world.mascotName,
        width: 140,
        height: 140,
      );
      return pw.MemoryImage(base64Decode(base64Png));
    } catch (_) {}

    return await PdfIconsHelper.loadMascot();
  }

  static Future<pw.MemoryImage?> _loadWorldBanner(ThematicWorld world) async {
    final assetBanner = await PdfIconsHelper.loadIcon('banner_${world.id}');
    if (assetBanner != null) return assetBanner;

    try {
      final base64Png = await YandexArtService.generateFallbackEducationalArt(
        type: 'world_banner_${world.id}',
        label: world.title,
        width: 640,
        height: 160,
      );
      return pw.MemoryImage(base64Decode(base64Png));
    } catch (_) {}

    return null;
  }

  /// Создает заголовок в формате "Тема: название темы" с иконкой и легким оформлением
  static pw.Widget _buildPdfTitle(
    Conspect conspect,
    PdfMaterialType type,
    pw.MemoryImage? materialIcon, {
    bool isPro = false,
    pw.MemoryImage? mascotImage,
    ThematicWorld? world,
    pw.MemoryImage? bannerImage,
  }) {
    final effectiveWorld = world ?? conspect.thematicWorld;
    final topic = _replaceEmojisWithSymbols(conspect.topic.isNotEmpty ? conspect.topic : conspect.title);

    if (mascotImage == null && conspect.illustrationMascot != null && conspect.illustrationMascot!.isNotEmpty) {
      try {
        final clean = conspect.illustrationMascot!.contains(',')
            ? conspect.illustrationMascot!.split(',').last
            : conspect.illustrationMascot!;
        mascotImage = pw.MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    final worldPrimary = effectiveWorld.pdfPrimary;
    final worldSecondary = effectiveWorld.pdfSecondary;
    final worldAccent = effectiveWorld.pdfAccent;
    final bgLight = _withOpacity(worldSecondary, 0.08);
    final borderCol = _withOpacity(worldPrimary, 0.35);

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
  static pw.Widget _buildMaterialInfo(Conspect conspect, PdfMaterialType type) {
    final bool isStudentSheet = type == PdfMaterialType.worksheet || type == PdfMaterialType.homework;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColors.blue50,
            PdfColors.indigo50,
          ],
        ),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Предмет: ${_replaceEmojisWithSymbols(conspect.subject)} • ${_replaceEmojisWithSymbols(conspect.ageGroup)}',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
              ),
              pw.Text(
                'Методика: ${_replaceEmojisWithSymbols(conspect.methodName)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          if (isStudentSheet) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.indigo200, width: 0.8),
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

  /// Памятка для родителей (спокойный совет и скрипт помощи)
  static pw.Widget _buildParentBriefingCard(String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
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
              pw.Text(
                'Ориентир времени: 15-20 минут (не затягивайте)',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.green900),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            content,
            style: const pw.TextStyle(
              fontSize: 10,
              lineSpacing: 1.4,
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

static List<pw.Widget> _buildContentWidgets(
    String content,
    pw.Font regular,
    pw.Font bold,
    Map<String, pw.MemoryImage?> sectionIcons, {
    pw.MemoryImage? starGold,
    pw.MemoryImage? starGray,
    bool isWorksheetOrHomework = false,
  }) {
    final cleanedContent = _cleanHtmlTags(content);
    final rawLines = cleanedContent.split('\n');
    final List<pw.Widget> widgets = [];

    String? currentHeader;
    String currentType = 'standard';
    int currentLevel = 0;
    List<String> currentBlockLines = [];
    int taskNumber = 0;

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
        }

        final iconName = PdfIconsHelper.getSectionIconName(header);
        final iconImage = sectionIcons[iconName];
        widgets.add(_buildSectionHeader(header, iconImage));
        if (lines.isNotEmpty) {
          widgets.add(_buildLinesContent(lines));
        }
        return;
      }

      // 2. Баннер разделителя уровней (Уровень 1: Старт...)
      if (type == 'level_header') {
        widgets.add(_buildLevelHeader(header));
        return;
      }

      // 3. Блок самооценки и рефлексии
      if (type == 'assessment' ||
          lowerHeader.contains('самооценка') ||
          lowerHeader.contains('рефлексия') ||
          fullText.contains('⭐⭐⭐') ||
          fullText.contains('оцени свои успехи')) {
        widgets.add(_buildSelfAssessmentCard(header, lines, starGold, starGray));
        return;
      }

      // 4. Памятка для родителей
      if (lowerHeader.contains('памятка для родителей') || fullText.contains('памятка для родителей')) {
        widgets.add(_buildParentBriefingCard(lines.isNotEmpty ? lines.join('\n') : header));
        return;
      }

      // 5. Талон обратной связи учителю
      if (lowerHeader.contains('обратная связь') || lowerHeader.contains('талон') || fullText.contains('отрезной корешок')) {
        widgets.add(_buildParentFeedbackSlip());
        return;
      }

      // 6. Карточка «Правило урока / Теория / Памятка»
      if (type == 'rule' || lowerHeader.contains('правило') || lowerHeader.contains('теория')) {
        widgets.add(_buildRuleCard(header, lines));
        return;
      }

      // 7. Карточка «Ключи и ответы для учителя»
      if (type == 'keys' || lowerHeader.contains('ключи') || lowerHeader.contains('ответы для учителя')) {
        widgets.add(_buildTeacherKeysCard(header, lines));
        return;
      }

      int currentTaskNum = taskNumber;
      final explicitTaskMatch = RegExp(r'^Задание\s+(\d+)[:\.]?\s*(.*)$', caseSensitive: false).firstMatch(header);
      if (explicitTaskMatch != null) {
        currentTaskNum = int.tryParse(explicitTaskMatch.group(1)!) ?? (taskNumber + 1);
        taskNumber = currentTaskNum;
      } else {
        taskNumber++;
        currentTaskNum = taskNumber;
      }

      // 8. Ловушка Незнайки / Ловушка для внимательных
      if (type == 'trap' || lowerHeader.contains('ловушка') || fullText.contains('ловушка незнайки') || fullText.contains('найди ошибки')) {
        widgets.add(_buildTrapCard(header, lines, currentTaskNum));
        return;
      }

      // 9. Прописи / каллиграфия (для начальной школы и русского языка)
      if (type == 'handwriting' || fullText.contains('[прописи]') || lowerHeader.contains('каллиграфическ') || lowerHeader.contains('чистописан')) {
        widgets.add(_buildHandwritingCard(header, lines, currentTaskNum));
        return;
      }

      // 10. Соедини стрелками
      if (type == 'matching' || fullText.contains('[соедини стрелками]') || lowerHeader.contains('соедини стрелк')) {
        widgets.add(_buildMatchingTaskCard(header, lines, currentTaskNum));
        return;
      }

      // 11. Стандартная неделимая карточка задания
      widgets.add(_buildStandardTaskCard(header, lines, currentTaskNum, isWorksheetOrHomework));
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
        flushCurrentBlock();
        final hText = hnMatch.group(1)!.trim();
        currentHeader = hText;
        final lower = hText.toLowerCase();

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

      // 3. Задания (Задание 1: ... или 1. ...)
      final isExplicitTask = RegExp(r'^Задание\s+\d+', caseSensitive: false).hasMatch(trimmed);
      final currentIsExplicitTask = currentHeader != null &&
          RegExp(r'^Задание\s+\d+', caseSensitive: false).hasMatch(currentHeader!);

      final isTopLevelNumbered = !rawLine.startsWith(' ') &&
          !rawLine.startsWith('\t') &&
          RegExp(r'^\d+[\.\)]\s+').hasMatch(trimmed) &&
          !currentIsExplicitTask;

      if ((isExplicitTask || isTopLevelNumbered) && currentType != 'assessment' && currentType != 'keys') {
        flushCurrentBlock();
        currentHeader = trimmed;
        final lower = trimmed.toLowerCase();
        if (lower.contains('ловушка')) {
          currentType = 'trap';
        } else if (lower.contains('соедини')) {
          currentType = 'matching';
        } else if (lower.contains('чистописан') || lower.contains('каллиграф') || lower.contains('прописи')) {
          currentType = 'handwriting';
        } else {
          currentType = 'standard';
        }
        continue;
      }

      // 4. Обычная строка содержимого текущего блока
      currentBlockLines.add(trimmed);
    }
    flushCurrentBlock();

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
    final cleanHeader = _replaceEmojisWithSymbols(header);
    String displayHeader = cleanHeader;
    final explicitMatch = RegExp(r'^Задание\s+\d+[:\.]?\s*', caseSensitive: false).firstMatch(displayHeader);
    if (explicitMatch != null) {
      displayHeader = displayHeader.substring(explicitMatch.end).trim();
    } else {
      final numPrefixMatch = RegExp(r'^\d+[\.\)]\s*').firstMatch(cleanHeader);
      if (numPrefixMatch != null) {
        displayHeader = cleanHeader.substring(numPrefixMatch.end).trim();
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
                child: pw.Text('ЗАДАНИЕ $num • ЧИСТОПИСАНИЕ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              if (displayHeader.isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(displayHeader, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                ),
              ],
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines.where((l) => !l.toLowerCase().contains('[прописи]')).toList()),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Образец и письмо элементов в косую строку:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan900)),
          pw.SizedBox(height: 4),
          for (int r = 0; r < 2; r++)
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
              height: 20,
              child: pw.CustomPaint(
                size: const PdfPoint(500, 20),
                painter: (canvas, size) {
                  canvas.setColor(PdfColor.fromInt(0xFF94A3B8));
                  canvas.setLineWidth(0.8);
                  canvas.drawLine(0, 0, size.x, 0);
                  canvas.drawLine(0, size.y, size.x, size.y);
                  canvas.strokePath();

                  canvas.setColor(PdfColor.fromInt(0xFFCBD5E1));
                  canvas.setLineWidth(0.5);
                  canvas.drawLine(0, size.y * 0.45, size.x, size.y * 0.45);
                  canvas.strokePath();

                  canvas.setColor(PdfColor.fromInt(0xFFE2E8F0));
                  canvas.setLineWidth(0.5);
                  final dx = size.y / 2.14;
                  for (double x = -20; x < size.x + 20; x += 18) {
                    canvas.drawLine(x, size.y, x + dx, 0);
                  }
                  canvas.strokePath();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Карточка «Ловушка Незнайки»
  static pw.Widget _buildTrapCard(String header, List<String> lines, int num) {
    final cleanHeader = _replaceEmojisWithSymbols(header);
    String displayHeader = cleanHeader;
    final explicitMatch = RegExp(r'^Задание\s+\d+[:\.]?\s*', caseSensitive: false).firstMatch(displayHeader);
    if (explicitMatch != null) {
      displayHeader = displayHeader.substring(explicitMatch.end).trim();
    } else {
      final numPrefixMatch = RegExp(r'^\d+[\.\)]\s*').firstMatch(cleanHeader);
      if (numPrefixMatch != null) {
        displayHeader = cleanHeader.substring(numPrefixMatch.end).trim();
      }
    }
    if (displayHeader.toLowerCase().startsWith('ловушка незнайки:')) {
      displayHeader = displayHeader.substring('ловушка незнайки:'.length).trim();
    } else if (displayHeader.toLowerCase().startsWith('ловушка для внимательных:')) {
      displayHeader = displayHeader.substring('ловушка для внимательных:'.length).trim();
    }
    if (displayHeader.isEmpty) {
      displayHeader = 'Найди и исправь хитрые ошибки:';
    }

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
                child: pw.Text('ЗАДАНИЕ $num • ЛОВУШКА', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(displayHeader, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF78350F))),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Исправленный вариант: __________________________________________________________________', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  /// Карточка задания «Соедини стрелками»
  static pw.Widget _buildMatchingTaskCard(String header, List<String> lines, int num) {
    final cleanHeader = _replaceEmojisWithSymbols(header);
    String displayHeader = cleanHeader;
    final explicitMatch = RegExp(r'^Задание\s+\d+[:\.]?\s*', caseSensitive: false).firstMatch(displayHeader);
    if (explicitMatch != null) {
      displayHeader = displayHeader.substring(explicitMatch.end).trim();
    } else {
      final numPrefixMatch = RegExp(r'^\d+[\.\)]\s*').firstMatch(cleanHeader);
      if (numPrefixMatch != null) {
        displayHeader = cleanHeader.substring(numPrefixMatch.end).trim();
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
                child: pw.Text('ЗАДАНИЕ $num • СОЕДИНИ', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              if (displayHeader.isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(displayHeader, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                ),
              ],
            ],
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Соедини аккуратными цветными стрелочками нужные пары.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// Стандартная неразрывная карточка задания
  static pw.Widget _buildStandardTaskCard(String header, List<String> lines, int num, bool isWorksheet) {
    final cleanHeader = _replaceEmojisWithSymbols(header);
    String displayHeader = cleanHeader;
    final explicitMatch = RegExp(r'^Задание\s+\d+[:\.]?\s*', caseSensitive: false).firstMatch(displayHeader);
    if (explicitMatch != null) {
      displayHeader = displayHeader.substring(explicitMatch.end).trim();
    } else {
      final numPrefixMatch = RegExp(r'^\d+[\.\)]\s*').firstMatch(cleanHeader);
      if (numPrefixMatch != null) {
        displayHeader = cleanHeader.substring(numPrefixMatch.end).trim();
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
          if (displayHeader.isNotEmpty)
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
                  child: pw.Text(
                    displayHeader,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                  ),
                ),
              ],
            ),
          if (lines.isNotEmpty) ...[
            if (displayHeader.isNotEmpty) pw.SizedBox(height: 6),
            _buildLinesContent(lines),
          ],
          if (isWorksheet) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              height: 1,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Отображение строк внутри карточки с поддержкой таблиц, списков и полей для ответов
  static pw.Widget _buildLinesContent(List<String> lines) {
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
        widgets.add(_buildAnswerLine(line));
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
                  child: pw.Text(
                    _replaceEmojisWithSymbols(itemText),
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey900),
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
                  child: pw.Text(
                    _replaceEmojisWithSymbols(bulletText),
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
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
          child: pw.Text(
            _replaceEmojisWithSymbols(line),
            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
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

    final displayDataRows = dataRows.isNotEmpty
        ? dataRows
        : [
            List.filled(headerRow.length, ''),
            List.filled(headerRow.length, ''),
          ];

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
  static pw.Widget _buildAnswerLine(String line) {
    final cleanLine = _replaceEmojisWithSymbols(line);
    final prefix = cleanLine.replaceAll(RegExp(r'_{2,}'), '').trim();
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
            pw.Text(prefix, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 3),
          ],
          pw.Container(
            height: 12,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF94A3B8), width: 0.8),
              ),
            ),
          ),
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
                  style: const pw.TextStyle(
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
                      style: const pw.TextStyle(
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
            style: const pw.TextStyle(
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

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

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

    await Printing.sharePdf(
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
              style: const pw.TextStyle(
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
                            style: const pw.TextStyle(
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
            style: const pw.TextStyle(
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
              style: const pw.TextStyle(
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
              style: const pw.TextStyle(
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
                    style: const pw.TextStyle(
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
                  style: const pw.TextStyle(
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
                style: const pw.TextStyle(
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
              style: const pw.TextStyle(
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
                      ? '★ PRO • ${PrintableCard.getTypeLabel(card.type).toUpperCase()}'
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
  static pw.Widget _buildProColoringSection(String coloringBase64) {
    pw.MemoryImage? img;
    try {
      final clean = coloringBase64.contains(',') ? coloringBase64.split(',').last : coloringBase64;
      img = pw.MemoryImage(base64Decode(clean));
    } catch (_) {}

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
                '🎨 Творческая разминка: раскрась по образцу',
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
                  '★ YandexART Pro',
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
  static pw.Widget _buildProRewardSection(String rewardBase64) {
    pw.MemoryImage? img;
    try {
      final clean = rewardBase64.contains(',') ? rewardBase64.split(',').last : rewardBase64;
      img = pw.MemoryImage(base64Decode(clean));
    } catch (_) {}

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
                      '🏆 Знак отличия: «Успешно пройдено!»',
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

}
