
/// Готовые стили оформления PDF перед печатью
enum PdfPreset {
  /// 🌿 Эко-печать: монохром, без заливок, экономия тонера (Бесплатно / Старт)
  ecoPrint,

  /// 📚 Школьный стандарт: синие рамки ГОСТ, линовка 65° (Практик)
  schoolStandard,

  /// 🎨 Премиум Учебник: цветные акценты, маскоты, бейджи (Методист Pro)
  premiumTextbook,

  /// 👑 Фирменный стиль школы: название школы, герб/логотип, ФИО (Директор)
  schoolBranding,
}

/// Размер шрифта документа
enum PdfFontSize {
  compact,  // 9.5 pt (для компактного размещения на 1 страницу)
  standard, // 11.0 pt (стандартный школьный)
  large,    // 13.0 pt (для 1 класса, ОВЗ и слабовидящих)
}

/// Поля страницы
enum PdfMarginSize {
  compact,  // 10 мм
  standard, // 15 мм
  wide,     // 20 мм
}

/// Плотность заданий и межстрочных интервалов
enum PdfDensity {
  compact,     // Плотная верстка (максимум заданий на 1 страницу)
  comfortable, // Просторная верстка с воздухом для записей ребенка
}

/// Конфигурация стиля и параметров экспорта PDF
class PdfStyleConfig {
  final PdfPreset preset;
  final PdfFontSize fontSize;
  final PdfMarginSize marginSize;
  final PdfDensity density;
  final bool showStudentHeader;
  final String schoolName;
  final String teacherName;
  final int brandColorHex;

  const PdfStyleConfig({
    this.preset = PdfPreset.schoolStandard,
    this.fontSize = PdfFontSize.standard,
    this.marginSize = PdfMarginSize.standard,
    this.density = PdfDensity.comfortable,
    this.showStudentHeader = true,
    this.schoolName = '',
    this.teacherName = '',
    this.brandColorHex = 0xFF4338CA, // Indigo по умолчанию
  });

  /// Создает предустановленную конфигурацию по выбранному пресету
  factory PdfStyleConfig.fromPreset(PdfPreset preset, {String? defaultSchool, String? defaultTeacher}) {
    switch (preset) {
      case PdfPreset.ecoPrint:
        return PdfStyleConfig(
          preset: PdfPreset.ecoPrint,
          fontSize: PdfFontSize.standard,
          marginSize: PdfMarginSize.compact,
          density: PdfDensity.compact,
          showStudentHeader: true,
          brandColorHex: 0xFF1E293B, // Slate Dark
        );
      case PdfPreset.schoolStandard:
        return PdfStyleConfig(
          preset: PdfPreset.schoolStandard,
          fontSize: PdfFontSize.standard,
          marginSize: PdfMarginSize.standard,
          density: PdfDensity.comfortable,
          showStudentHeader: true,
          brandColorHex: 0xFF1E40AF, // Classic Royal Blue
        );
      case PdfPreset.premiumTextbook:
        return PdfStyleConfig(
          preset: PdfPreset.premiumTextbook,
          fontSize: PdfFontSize.large,
          marginSize: PdfMarginSize.standard,
          density: PdfDensity.comfortable,
          showStudentHeader: true,
          brandColorHex: 0xFF6D28D9, // Purple Indigo
        );
      case PdfPreset.schoolBranding:
        return PdfStyleConfig(
          preset: PdfPreset.schoolBranding,
          fontSize: PdfFontSize.standard,
          marginSize: PdfMarginSize.standard,
          density: PdfDensity.comfortable,
          showStudentHeader: true,
          schoolName: defaultSchool ?? 'Гимназия №1',
          teacherName: defaultTeacher ?? '',
          brandColorHex: 0xFF991B1B, // Burgundy / Deep Crimson
        );
    }
  }

  PdfStyleConfig copyWith({
    PdfPreset? preset,
    PdfFontSize? fontSize,
    PdfMarginSize? marginSize,
    PdfDensity? density,
    bool? showStudentHeader,
    String? schoolName,
    String? teacherName,
    int? brandColorHex,
  }) {
    return PdfStyleConfig(
      preset: preset ?? this.preset,
      fontSize: fontSize ?? this.fontSize,
      marginSize: marginSize ?? this.marginSize,
      density: density ?? this.density,
      showStudentHeader: showStudentHeader ?? this.showStudentHeader,
      schoolName: schoolName ?? this.schoolName,
      teacherName: teacherName ?? this.teacherName,
      brandColorHex: brandColorHex ?? this.brandColorHex,
    );
  }
}
