import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:metodist/models/conspect.dart';
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
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{200D}]|[\u{FE0E}-\u{FE0F}]',
      unicode: true,
    );
    
    String result = text.replaceAll(emojiRegex, '');
    
    // Также удаляем все декоративные символы (•, →, ⚡, ✱, ≡, ☑, ✓, ✗, ★, ⌕, ☁, ■, ▰, ◊, №, ‼ и т.д.)
    final decorativeSymbolsRegex = RegExp(r'[•→⚡✱≡☑✓✗★⌕☁■▰◊№‼]');
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
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{200D}]|[\u{FE0E}-\u{FE0F}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r' {2,}'), ' ').trim();
  }



  /// Экспорт отдельного материала (конспект, лист заданий или домашняя работа)
  static Future<void> exportMaterialPdf(Conspect conspect, PdfMaterialType type) async {
    await _exportSinglePdf(conspect, type);
  }

  /// Exports conspect to formatted PDF document and opens print/share dialog
  static Future<void> exportAndSharePdf(Conspect conspect) async {
    // Если выбран только один материал, используем старый метод для обратной совместимости
    if (conspect.generatedMaterials.length == 1 && conspect.generatedMaterials.contains('conspect')) {
      await _exportSinglePdf(conspect, PdfMaterialType.conspect);
      return;
    }
    
    // Генерация нескольких PDF по выбранным материалам
    for (final material in conspect.generatedMaterials) {
      final materialType = _mapMaterialToType(material);
      if (materialType != null) {
        await _exportSinglePdf(conspect, materialType);
      }
    }
  }

  /// Экспорт отдельного PDF по типу материала
  static Future<void> _exportSinglePdf(Conspect conspect, PdfMaterialType type) async {
    final pdf = pw.Document();

    // Load Cyrillic-compatible Google Font (Roboto)
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    // Извлекаем только нужную часть контента в зависимости от типа
    final filteredContent = _extractMaterialContent(conspect.content, type);
    if (filteredContent.isEmpty) {
      // Если контент не найден, используем весь контент
      await _exportLegacyPdf(conspect);
      return;
    }

    // Загружаем иконку для типа материала
    final materialTypeName = type.toString().split('.').last;
    final materialIconName = PdfIconsHelper.getMaterialIconName(materialTypeName);
    final materialIcon = await PdfIconsHelper.loadIcon(materialIconName);

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
        ),
        header: (context) => _buildPdfHeader(conspect, type),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Страница ${context.pageNumber} из ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
          ),
        ),
        build: (context) => [
          // Заголовок с иконкой
          _buildPdfTitle(conspect, type, materialIcon),
          pw.SizedBox(height: 12),

          // Информация о материале
          _buildMaterialInfo(conspect, type),
          pw.SizedBox(height: 16),

          // Основной контент
          ..._buildContentWidgets(filteredContent, fontRegular, fontBold, sectionIcons),
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

  /// Извлекает контент для определенного типа материала
  static String _extractMaterialContent(String content, PdfMaterialType type) {
    final cleanedContent = _removeCardsAndJson(content);
    final sections = _splitContentBySections(cleanedContent);

    switch (type) {
      case PdfMaterialType.conspect:
        final conspectSections = sections.entries
            .where((entry) {
              final lower = entry.key.toLowerCase();
              return !lower.contains('лист заданий') &&
                     !lower.contains('раздаточн') &&
                     !lower.contains('рабочий лист') &&
                     !lower.contains('домашн') &&
                     !lower.contains('блок дополнительных заданий');
            })
            .map((entry) => '# ${entry.key}\n${entry.value}')
            .join('\n\n');
        return conspectSections.isNotEmpty ? conspectSections : cleanedContent;

      case PdfMaterialType.worksheet:
        final worksheetSection = sections.entries
            .firstWhere((entry) {
              final lower = entry.key.toLowerCase();
              return lower.contains('лист заданий') ||
                     lower.contains('раздаточн') ||
                     lower.contains('рабочий лист');
            }, orElse: () => const MapEntry('', ''));

        if (worksheetSection.value.isNotEmpty) {
          return '# Лист заданий для печати\n${worksheetSection.value}';
        }
        // Fallback: search by text block if header wasn't caught
        final lower = cleanedContent.toLowerCase();
        final wsIndex = lower.indexOf('лист заданий');
        if (wsIndex != -1) {
          final hwIndex = lower.indexOf('домашн', wsIndex);
          if (hwIndex != -1) {
            return cleanedContent.substring(wsIndex, hwIndex).trim();
          } else {
            return cleanedContent.substring(wsIndex).trim();
          }
        }
        return '';

      case PdfMaterialType.homework:
        final homeworkSection = sections.entries
            .firstWhere((entry) {
              final lower = entry.key.toLowerCase();
              return lower.contains('домашн') ||
                     lower.contains('блок дополнительных') ||
                     lower.contains('задания на дом');
            }, orElse: () => const MapEntry('', ''));

        if (homeworkSection.value.isNotEmpty) {
          return '# Домашняя работа\n${homeworkSection.value}';
        }
        // Fallback: search by text block
        final lower = cleanedContent.toLowerCase();
        final hwIndex = lower.indexOf('домашн');
        if (hwIndex != -1) {
          return cleanedContent.substring(hwIndex).trim();
        }
        return '';

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
  static pw.Widget _buildPdfHeader(Conspect conspect, PdfMaterialType type) {
    final headerText = _getMaterialHeaderText(type);
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Text(
        '$headerText: ${conspect.methodName} — ${conspect.subject}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
      ),
    );
  }

  /// Создает заголовок в формате "Тема: название темы" с иконкой и легким оформлением
  static pw.Widget _buildPdfTitle(Conspect conspect, PdfMaterialType type, pw.MemoryImage? materialIcon) {
    // Используем тему из конспекта, очищенную от эмодзи
    final topic = _replaceEmojisWithSymbols(conspect.topic.isNotEmpty ? conspect.topic : conspect.title);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
              colors: [
                PdfColors.indigo50,
                PdfColors.blue50,
              ],
            ),
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: PdfColors.indigo300, width: 1.5),
          ),
          child: pw.Row(
            children: [
              // Иконка типа материала
              if (materialIcon != null)
                pw.Container(
                  width: 36,
                  height: 36,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(materialIcon),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Тема:',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      topic,
                      style: const pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
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
                'Методика: ${_replaceEmojisWithSymbols(conspect.methodName)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              ),
              pw.Text(
                'Длительность: ${_replaceEmojisWithSymbols(conspect.duration)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Предмет: ${_replaceEmojisWithSymbols(conspect.subject)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
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
        border: pw.Border(
          left: const pw.BorderSide(color: PdfColors.green700, width: 3.5),
          top: const pw.BorderSide(color: PdfColors.green200, width: 0.8),
          right: const pw.BorderSide(color: PdfColors.green200, width: 0.8),
          bottom: const pw.BorderSide(color: PdfColors.green200, width: 0.8),
        ),
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
    Map<String, pw.MemoryImage?> sectionIcons,
  ) {
    // Очищаем контент от HTML-тегов перед обработкой
    final cleanedContent = _cleanHtmlTags(content);
    final lines = cleanedContent.split('\n');
    final List<pw.Widget> widgets = [];
    bool inList = false;
    int taskCounter = 0;

    for (final line in lines) {
      final trimmed = _replaceEmojisWithSymbols(line);
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        inList = false;
        continue;
      }

      // Заголовок уровня # с иконкой и легким градиентом
      if (trimmed.startsWith('# ')) {
        final sectionTitle = trimmed.substring(2).trim();
        taskCounter = 0; // Сбрасываем счетчик заданий для нового раздела
        
        // Получаем иконку для раздела из маппинга
        final iconName = PdfIconsHelper.getSectionIconName(sectionTitle);
        final iconImage = sectionIcons[iconName];
        
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
                colors: [
                  PdfColors.blue50,
                  PdfColors.indigo50,
                ],
              ),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.indigo200, width: 1),
            ),
            child: pw.Row(
              children: [
                // Иконка раздела
                if (iconImage != null)
                  pw.Container(
                    width: 28,
                    height: 28,
                    margin: const pw.EdgeInsets.only(right: 10),
                    child: pw.Image(iconImage),
                  ),
                pw.Expanded(
                  child: pw.Text(
                    sectionTitle,
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        inList = false;
      } else if (trimmed.startsWith('## ')) {
        // Заголовок уровня ## с легким фоном
        final subTitle = trimmed.substring(3).trim();
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Text(
              subTitle,
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
        );
        inList = false;
      } else if (trimmed.startsWith('### ')) {
        // Заголовок уровня ### - просто полужирный текст
        final heading = trimmed.substring(4).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              heading,
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        );
        inList = false;
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        // Маркированный список - просто текст с отступом
        final itemText = trimmed.substring(2).trim();
        
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Text(
              '• $itemText',
              style: const pw.TextStyle(
                fontSize: 11,
                lineSpacing: 1.5,
                color: PdfColors.black,
              ),
            ),
          ),
        );
        inList = false;
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        // Нумерованный список - увеличиваем счетчик заданий и отображаем с легким фоном
        final dotIndex = trimmed.indexOf('.');
        final itemText = trimmed.substring(dotIndex + 1).trim();
        taskCounter++;
        
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8, top: 4),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 22,
                  height: 22,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.indigo300, width: 1),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '$taskCounter',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    itemText,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      lineSpacing: 1.5,
                      color: PdfColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        inList = false;
      } else if (trimmed.toLowerCase().contains('памятка для родителей') || trimmed.contains('👨‍👩‍👧')) {
        final advice = trimmed.replaceFirst(RegExp(r'.*?памятка для родителей:?\s*', caseSensitive: false), '')
                              .replaceFirst('👨‍👩‍👧', '').trim();
        widgets.add(_buildParentBriefingCard(advice.isNotEmpty ? advice : 'Помогайте ребенку мягко, задавая наводящие вопросы. Не делайте задание за него. Хвалите за усердие и любознательность!'));
        inList = false;
      } else if (trimmed.toLowerCase().contains('обратная связь родителя') || trimmed.toLowerCase().contains('подпись родителя')) {
        widgets.add(_buildParentFeedbackSlip());
        inList = false;
      } else if (trimmed.toLowerCase().contains('место для ответа ученика') || trimmed.contains('_________')) {
        // Игнорируем, так как это будет обработано отдельно в рабочей зоне
        inList = false;
      } else if (trimmed.contains('⭐⭐⭐') || trimmed.toLowerCase().contains('самооценка')) {
        // Пропускаем блоки самооценки
        inList = false;
      } else {
        // Обычный текст
        widgets.add(
          pw.Container(
            margin: pw.EdgeInsets.only(
              bottom: 5,
              left: inList ? 14 : 0,
            ),
            child: pw.Text(
              trimmed,
              style: const pw.TextStyle(
                fontSize: 10.5,
                lineSpacing: 1.5,
                color: PdfColors.grey800,
              ),
            ),
          ),
        );
        inList = false;
      }
    }

    return widgets;
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
        border: pw.Border(
          left: pw.BorderSide(color: borderColor, width: 3.5),
          top: pw.BorderSide(color: _withOpacity(borderColor, 0.25), width: 0.6),
          right: pw.BorderSide(color: _withOpacity(borderColor, 0.25), width: 0.6),
          bottom: pw.BorderSide(color: _withOpacity(borderColor, 0.25), width: 0.6),
        ),
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
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue200, width: 1),
              ),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
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
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
                ),
                child: pw.Text(
                  PrintableCard.getTypeLabel(card.type).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                  ),
                ),
              ),
              pw.Text(
                '-- вырезать --',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
              ),
            ],
          ),

          // Центр: лицевой текст (крупный, яркий)
          pw.Expanded(
            child: pw.Center(
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
            padding: const pw.EdgeInsets.all(6),
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
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    maxLines: 1,
                  ),
                if (card.backText.isNotEmpty)
                  pw.Text(
                    'Подсказка: ${_stripEmojis(card.backText)}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
