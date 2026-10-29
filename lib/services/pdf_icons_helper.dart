import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

/// Вспомогательный класс для работы с иконками в PDF
class PdfIconsHelper {
  static final Map<String, Uint8List?> _iconCache = {};

  /// Загружает иконку из assets и кэширует ее
  static Future<pw.MemoryImage?> loadIcon(String iconName) async {
    try {
      // Проверяем кэш
      if (_iconCache.containsKey(iconName) && _iconCache[iconName] != null) {
        return pw.MemoryImage(_iconCache[iconName]!);
      }

      // Загружаем из assets
      final ByteData data = await rootBundle.load('assets/images/pdf_icons/$iconName.png');
      final Uint8List bytes = data.buffer.asUint8List();

      // Кэшируем
      _iconCache[iconName] = bytes;

      return pw.MemoryImage(bytes);
    } catch (e) {
      print('Ошибка загрузки иконки $iconName: $e');
      return null;
    }
  }

  /// Получает имя файла иконки для типа материала
  static String getMaterialIconName(String type) {
    switch (type.toLowerCase()) {
      case 'conspect':
      case 'конспект':
        return 'icon_conspect';
      case 'worksheet':
      case 'лист заданий':
      case 'рабочий лист':
        return 'icon_worksheet';
      case 'homework':
      case 'домашняя работа':
        return 'icon_homework';
      default:
        return 'icon_default';
    }
  }

  /// Получает имя файла иконки для раздела по его содержанию
  static String getSectionIconName(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('цель') || lowerTitle.contains('задача') || lowerTitle.contains('миссия')) {
      return 'icon_goal';
    } else if (lowerTitle.contains('объяснение') || lowerTitle.contains('теория') || lowerTitle.contains('правило')) {
      return 'icon_theory';
    } else if (lowerTitle.contains('пример') || lowerTitle.contains('образец') || lowerTitle.contains('демонстрация')) {
      return 'icon_examples';
    } else if (lowerTitle.contains('задание') || lowerTitle.contains('упражнение') || lowerTitle.contains('задача')) {
      return 'icon_tasks';
    } else if (lowerTitle.contains('внимание') || lowerTitle.contains('важно') || lowerTitle.contains('ловушка')) {
      return 'icon_attention';
    } else if (lowerTitle.contains('проверка') || lowerTitle.contains('тест') || lowerTitle.contains('опрос')) {
      return 'icon_test';
    } else if (lowerTitle.contains('творчество') || lowerTitle.contains('игра') || lowerTitle.contains('проект')) {
      return 'icon_creativity';
    } else if (lowerTitle.contains('рефлексия') || lowerTitle.contains('оценка') || lowerTitle.contains('самооценка')) {
      return 'icon_reflection';
    } else if (lowerTitle.contains('родител') || lowerTitle.contains('совет') || lowerTitle.contains('рекомендация')) {
      return 'icon_parents';
    } else if (lowerTitle.contains('домашняя') || lowerTitle.contains('дом') || lowerTitle.contains('закрепление')) {
      return 'icon_homework';
    } else if (lowerTitle.contains('материал') || lowerTitle.contains('инструмент') || lowerTitle.contains('ресурс')) {
      return 'icon_materials';
    } else if (lowerTitle.contains('вопрос') || lowerTitle.contains('почему') || lowerTitle.contains('размышление')) {
      return 'icon_questions';
    }
    
    return 'icon_default';
  }

  /// Получает иконку для места ответа ученика
  static String getAnswerIconName() {
    return 'icon_answer';
  }

  /// Получает декоративный разделитель
  static String getDividerIconName() {
    return 'divider_wave';
  }

  /// Получает легкий паттерн для фона
  static String getPatternIconName() {
    return 'pattern_light';
  }

  /// Очищает кэш иконок
  static void clearCache() {
    _iconCache.clear();
  }

  /// Предзагружает все иконки для быстрого доступа
  static Future<void> preloadIcons() async {
    final List<String> iconNames = [
      'icon_conspect',
      'icon_worksheet',
      'icon_homework',
      'icon_goal',
      'icon_theory',
      'icon_examples',
      'icon_tasks',
      'icon_attention',
      'icon_test',
      'icon_creativity',
      'icon_reflection',
      'icon_parents',
      'icon_materials',
      'icon_questions',
      'icon_default',
      'icon_answer',
      'divider_wave',
      'pattern_light',
    ];

    for (final iconName in iconNames) {
      try {
        await loadIcon(iconName);
      } catch (e) {
        // Пропускаем ошибки при предзагрузке
        print('Не удалось предзагрузить иконку $iconName: $e');
      }
    }
  }
}