import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/conspect.dart';
import '../models/printable_card.dart';

/// Типы материалов для генерации
enum MaterialType {
  conspect,    // Основной конспект занятия
  worksheet,   // Лист заданий для печати
  homework     // Домашняя работа
}

class PdfExportService {
  static PdfColor _withOpacity(PdfColor baseColor, double opacity) =>
      PdfColor(baseColor.red, baseColor.green, baseColor.blue, opacity);
  /// Exports conspect to formatted PDF document and opens print/share dialog
  static Future<void> exportAndSharePdf(Conspect conspect) async {
    // Если выбран только один материал, используем старый метод для обратной совместимости
    if (conspect.generatedMaterials.length == 1 && conspect.generatedMaterials.contains('conspect')) {
      await _exportSinglePdf(conspect, MaterialType.conspect);
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
  static Future<void> _exportSinglePdf(Conspect conspect, MaterialType type) async {
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
          _buildPdfTitle(conspect, type),
          pw.SizedBox(height: 12),

          // Информация о материале
          _buildMaterialInfo(conspect, type),
          pw.SizedBox(height: 16),

          // Основной контент
          ..._buildContentWidgets(filteredContent, fontRegular, fontBold),
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

  /// Преобразует строковый идентификатор материала в MaterialType
  static MaterialType? _mapMaterialToType(String material) {
    switch (material) {
      case 'conspect':
        return MaterialType.conspect;
      case 'worksheet':
        return MaterialType.worksheet;
      case 'homework':
        return MaterialType.homework;
      default:
        return null;
    }
  }

  /// Извлекает контент для определенного типа материала
  static String _extractMaterialContent(String content, MaterialType type) {
    // Удаляем все JSON блоки и карточки из контента
    final cleanedContent = _removeCardsAndJson(content);
    
    // Разделяем контент по заголовкам
    final sections = _splitContentBySections(cleanedContent);
    
    switch (type) {
      case MaterialType.conspect:
        // Берем все секции кроме листа заданий и домашней работы
        return sections.entries
            .where((entry) => !entry.key.toLowerCase().contains('лист заданий') &&
                           !entry.key.toLowerCase().contains('домашняя работа') &&
                           !entry.key.toLowerCase().contains('блок дополнительных заданий'))
            .map((entry) => '# ${entry.key}\n${entry.value}')
            .join('\n\n');
        
      case MaterialType.worksheet:
        // Находим секцию "Лист заданий"
        final worksheetSection = sections.entries
            .firstWhere((entry) => entry.key.toLowerCase().contains('лист заданий'), 
                       orElse: () => MapEntry('', ''));
        return worksheetSection.value.isNotEmpty ? 
               '# Лист заданий для печати\n${worksheetSection.value}' : '';
        
      case MaterialType.homework:
        // Находим секцию "Домашняя работа"
        final homeworkSection = sections.entries
            .firstWhere((entry) => entry.key.toLowerCase().contains('домашняя работа') ||
                                 entry.key.toLowerCase().contains('блок дополнительных заданий'), 
                       orElse: () => MapEntry('', ''));
        return homeworkSection.value.isNotEmpty ? 
               '# Домашняя работа\n${homeworkSection.value}' : '';
        
      default:
        return cleanedContent;
    }
  }

  /// Удаляет карточки и JSON блоки из контента
  static String _removeCardsAndJson(String content) {
    // Удаляем блоки с карточками (JSON массивы)
    final jsonRegex = RegExp(r'```(?:json)?\s*(\[\s*\{[\s\S]*?\}\s*\])\s*```');
    var cleaned = content.replaceAllMapped(jsonRegex, (match) => '');
    
    // Удаляем простые JSON массивы
    final rawJsonRegex = RegExp(r'(\[\s*\{[\s\S]*?\}\s*\])');
    cleaned = cleaned.replaceAllMapped(rawJsonRegex, (match) => '');
    
    // Удаляем описание формата карточек
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
    
    for (final line in lines) {
      if (line.startsWith('# ')) {
        // Сохраняем предыдущую секцию
        if (currentSection != null && sectionContent.isNotEmpty) {
          sections[currentSection] = sectionContent.toString().trim();
          sectionContent.clear();
        }
        // Начинаем новую секцию
        currentSection = line.substring(2).trim();
      } else if (currentSection != null) {
        sectionContent.writeln(line);
      }
    }
    
    // Сохраняем последнюю секцию
    if (currentSection != null && sectionContent.isNotEmpty) {
      sections[currentSection] = sectionContent.toString().trim();
    }
    
    return sections;
  }

  /// Создает заголовок PDF файла
  static pw.Widget _buildPdfHeader(Conspect conspect, MaterialType type) {
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

  /// Создает заголовок PDF с иконкой
  static pw.Widget _buildPdfTitle(Conspect conspect, MaterialType type) {
    final icon = _getMaterialIcon(type);
    final title = _getMaterialTitle(conspect.title, type);
    final color = _getMaterialColor(type);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 36,
                height: 36,
                decoration: pw.BoxDecoration(
                  color: _withOpacity(color, 0.1),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _withOpacity(color, 0.3), width: 1),
                ),
                child: pw.Center(
                  child: pw.Text(
                    icon,
                    style: const pw.TextStyle(fontSize: 20, color: PdfColors.grey800),
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _getMaterialHeaderText(type).replaceFirst('Методист • ', ''),
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _withOpacity(color, 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
              colors: [
                _withOpacity(color, 0.7),
                _withOpacity(color, 0.4),
                _withOpacity(PdfColors.grey300, 0.2),
              ],
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Создает информационный блок материала
  static pw.Widget _buildMaterialInfo(Conspect conspect, MaterialType type) {
    final description = _getMaterialDescription(type);
    final color = _getMaterialColor(type);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            _withOpacity(color, 0.15),
            _withOpacity(color, 0.08),
            _withOpacity(color, 0.03),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _withOpacity(color, 0.2), width: 1),
        boxShadow: [
          pw.BoxShadow(
            color: _withOpacity(PdfColors.grey300, 0.5),
            blurRadius: 6,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                _getMaterialIcon(type),
                style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _withOpacity(color, 0.9),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            height: 1,
            color: _withOpacity(color, 0.2),
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoItem('📘', 'Методика:', conspect.methodName),
                  _buildInfoItem('📚', 'Предмет:', conspect.subject),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildInfoItem('👶', 'Возраст:', conspect.ageGroup),
                  _buildInfoItem('⏱', 'Длительность:', conspect.duration),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Создает элемент информации
  static pw.Widget _buildInfoItem(String icon, String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          icon,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
      ],
    );
  }

  /// Получает заголовок для шапки PDF
  static String _getMaterialHeaderText(MaterialType type) {
    switch (type) {
      case MaterialType.conspect:
        return 'Методист • Конспект занятия';
      case MaterialType.worksheet:
        return 'Методист • Лист заданий';
      case MaterialType.homework:
        return 'Методист • Домашняя работа';
      default:
        return 'Методист';
    }
  }

  /// Получает иконку для типа материала
  static String _getMaterialIcon(MaterialType type) {
    switch (type) {
      case MaterialType.conspect:
        return '📋';
      case MaterialType.worksheet:
        return '📄';
      case MaterialType.homework:
        return '🏠';
      default:
        return '📝';
    }
  }

  /// Получает заголовок PDF
  static String _getMaterialTitle(String baseTitle, MaterialType type) {
    switch (type) {
      case MaterialType.conspect:
        return 'Конспект занятия: $baseTitle';
      case MaterialType.worksheet:
        return 'Лист заданий: $baseTitle';
      case MaterialType.homework:
        return 'Домашняя работа: $baseTitle';
      default:
        return baseTitle;
    }
  }

  /// Получает описание материала
  static String _getMaterialDescription(MaterialType type) {
    switch (type) {
      case MaterialType.conspect:
        return 'Подробный конспект занятия с пошаговым сценарием, целями и задачами';
      case MaterialType.worksheet:
        return 'Раздаточный материал для печати с упражнениями и заданиями';
      case MaterialType.homework:
        return 'Задания для домашней работы с творческими и практическими упражнениями';
      default:
        return 'Учебный материал';
    }
  }

  /// Получает цвет для типа материала
  static PdfColor _getMaterialColor(MaterialType type) {
    switch (type) {
      case MaterialType.conspect:
        return PdfColors.indigo500;
      case MaterialType.worksheet:
        return PdfColors.blue500;
      case MaterialType.homework:
        return PdfColors.green500;
      default:
        return PdfColors.grey500;
    }
  }

  /// Получает имя файла для PDF
  static String _getPdfFilename(String title, MaterialType type) {
    final cleanTitle = title.replaceAll(' ', '_');
    switch (type) {
      case MaterialType.conspect:
        return 'Конспект_$cleanTitle.pdf';
      case MaterialType.worksheet:
        return 'Лист_заданий_$cleanTitle.pdf';
      case MaterialType.homework:
        return 'Домашняя_работа_$cleanTitle.pdf';
      default:
        return 'Материал_$cleanTitle.pdf';
    }
  }

  static List<pw.Widget> _buildContentWidgets(
    String content,
    pw.Font regular,
    pw.Font bold,
  ) {
    final lines = content.split('\n');
    final List<pw.Widget> widgets = [];
    int sectionCounter = 0;
    bool inList = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 10));
        inList = false;
        continue;
      }

      if (trimmed.startsWith('# ')) {
        sectionCounter++;
        final sectionTitle = trimmed.substring(2).trim();
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 24, bottom: 12),
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
                colors: [
                  PdfColors.blue50,
                  PdfColors.indigo50,
                  PdfColors.grey100,
                ],
              ),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.indigo200, width: 1.2),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey400,
                  blurRadius: 4,
                  offset: const PdfPoint(0, 2),
                ),
              ],
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 28,
                  height: 28,
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [PdfColors.blue400, PdfColors.indigo500],
                    ),
                    borderRadius: pw.BorderRadius.circular(14),
                    boxShadow: [
                      pw.BoxShadow(
                        color: _withOpacity(PdfColors.indigo300, 0.4),
                        blurRadius: 3,
                        offset: const PdfPoint(0, 1),
                      ),
                    ],
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '$sectionCounter',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Text(
                    sectionTitle,
                    style: pw.TextStyle(
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
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [PdfColors.blue400, PdfColors.indigo400],
                    ),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  trimmed.substring(3).trim(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        );
        inList = false;
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo500,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      trimmed.substring(2).trim(),
                      style: const pw.TextStyle(
                        fontSize: 11,
                        lineSpacing: 1.5,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        inList = true;
      } else if (trimmed.startsWith('1. ') || trimmed.startsWith('2. ') || trimmed.startsWith('3. ') ||
                 trimmed.startsWith('4. ') || trimmed.startsWith('5. ') || trimmed.startsWith('6. ') ||
                 trimmed.startsWith('7. ') || trimmed.startsWith('8. ') || trimmed.startsWith('9. ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  margin: const pw.EdgeInsets.only(top: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.indigo300, width: 0.8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      trimmed.substring(0, 2).trim(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      trimmed.substring(2).trim(),
                      style: const pw.TextStyle(
                        fontSize: 11,
                        lineSpacing: 1.5,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        inList = true;
      } else {
        // Обычный текст
        widgets.add(
          pw.Container(
            margin: pw.EdgeInsets.only(
              bottom: 6,
              left: inList ? 16 : 0,
            ),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                fontSize: 11,
                lineSpacing: 1.6,
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
                        '✂ Лист для вырезания А4 (2×3)',
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
                '✂',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
            ],
          ),

          // Центр: лицевой текст (крупный, яркий)
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                card.frontText,
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
                    '💡 Образ: ${card.imageHint}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    maxLines: 1,
                  ),
                if (card.backText.isNotEmpty)
                  pw.Text(
                    'Подсказка: ${card.backText}',
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
