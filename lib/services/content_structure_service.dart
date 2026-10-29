import 'dart:convert';
import '../models/conspect.dart';

/// Сервис для улучшения структуры контента конспектов
class ContentStructureService {
  /// Улучшает структуру контента конспекта для лучшей генерации PDF
  static String enhanceContentStructure(String content, String topic, String subject) {
    // Разбиваем контент на строки
    final lines = content.split('\n');
    final enhancedLines = <String>[];
    
    bool hasH1 = false;
    int sectionCounter = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('# ') && !hasH1) {
        // Первый H1 заголовок
        enhancedLines.add('# $topic');
        hasH1 = true;
      } else if (line.startsWith('## ')) {
        // H2 заголовок - добавляем эмодзи и структуру
        final originalTitle = line.substring(3).trim();
        final enhancedTitle = _enhanceH2Title(originalTitle, sectionCounter + 1);
        enhancedLines.add(enhancedTitle);
        sectionCounter++;
      } else if (line.startsWith('### ')) {
        // H3 заголовок - улучшаем структуру
        final originalTitle = line.substring(4).trim();
        final enhancedTitle = _enhanceH3Title(originalTitle, subject);
        enhancedLines.add(enhancedTitle);
      } else if (_isSpecialBlock(line)) {
        // Особые блоки - улучшаем форматирование
        enhancedLines.add(_enhanceSpecialBlock(line));
      } else if (_needsAnswerLines(line)) {
        // Добавляем линии для ответов
        enhancedLines.add(line);
        enhancedLines.add('Линии для ответа: _______________________');
      } else {
        enhancedLines.add(line);
      }
    }
    
    // Добавляем блок самооценки, если его нет
    if (!_containsSelfAssessment(enhancedLines)) {
      enhancedLines.add('');
      enhancedLines.add('## 💭 Рефлексия и самооценка');
      enhancedLines.add('⭐⭐⭐ Оцени свои успехи на занятии');
      enhancedLines.add('');
      enhancedLines.add('Мой прогресс:');
      enhancedLines.add('- [ ] Отлично! Справился со всеми заданиями');
      enhancedLines.add('- [ ] Хорошо! Было непросто, но я справился');
      enhancedLines.add('- [ ] Нужна помощь учителя');
      enhancedLines.add('');
      enhancedLines.add('Мое настроение после занятия:');
      enhancedLines.add('- [ ] Восторг! Было очень интересно');
      enhancedLines.add('- [ ] Спокойствие и уверенность');
      enhancedLines.add('- [ ] Задумчивость - есть над чем подумать');
    }
    
    return enhancedLines.join('\n');
  }
  
  /// Улучшает H2 заголовок с эмодзи и структурой
  static String _enhanceH2Title(String originalTitle, int sectionNumber) {
    final lowerTitle = originalTitle.toLowerCase();
    
    // Определяем тип раздела и добавляем соответствующий эмодзи
    if (lowerTitle.contains('цел') || lowerTitle.contains('задач')) {
      return '## 🎯 Цели и задачи занятия ($sectionNumber)';
    } else if (lowerTitle.contains('объяснен') || lowerTitle.contains('теория') || lowerTitle.contains('материал')) {
      return '## 📋 Объяснение нового материала ($sectionNumber)';
    } else if (lowerTitle.contains('задани') || lowerTitle.contains('упражнен') || lowerTitle.contains('практик')) {
      return '## 📝 Практические задания ($sectionNumber)';
    } else if (lowerTitle.contains('ход') || lowerTitle.contains('сценари') || lowerTitle.contains('план')) {
      return '## 🕐 Ход занятия ($sectionNumber)';
    } else if (lowerTitle.contains('игра') || lowerTitle.contains('игров')) {
      return '## 🎮 Игровые элементы ($sectionNumber)';
    } else if (lowerTitle.contains('дом') || lowerTitle.contains('самостоятельн')) {
      return '## 🏠 Домашняя работа ($sectionNumber)';
    } else if (lowerTitle.contains('рефлекс') || lowerTitle.contains('оценк') || lowerTitle.contains('итог')) {
      return '## 💭 Рефлексия и самооценка ($sectionNumber)';
    } else if (lowerTitle.contains('правило') || lowerTitle.contains('основн')) {
      return '## 📌 Главное правило урока ($sectionNumber)';
    } else if (lowerTitle.contains('ловушка') || lowerTitle.contains('внимани') || lowerTitle.contains('ошибк')) {
      return '## ⚠️ Ловушка для внимательных ($sectionNumber)';
    } else if (lowerTitle.contains('родител') || lowerTitle.contains('памятк') || lowerTitle.contains('совет')) {
      return '## 👨‍👩‍👧 Памятка для родителей ($sectionNumber)';
    }
    
    return '## 📋 $originalTitle ($sectionNumber)';
  }
  
  /// Улучшает H3 заголовок
  static String _enhanceH3Title(String originalTitle, String subject) {
    final lowerTitle = originalTitle.toLowerCase();
    final lowerSubject = subject.toLowerCase();
    
    if (lowerTitle.contains('уровень 1') || lowerTitle.contains('старт') || lowerTitle.contains('базов')) {
      return '### Уровень 1 • Старт 🔰';
    } else if (lowerTitle.contains('уровень 2') || lowerTitle.contains('практик') || lowerTitle.contains('основн')) {
      return '### Уровень 2 • Практик ⚡';
    } else if (lowerTitle.contains('уровень 3') || lowerTitle.contains('детектив') || lowerTitle.contains('профи')) {
      return '### Уровень 3 • Детектив Pro 🔍';
    } else if (lowerTitle.contains('блок 1') || lowerTitle.contains('тренировк')) {
      return '### Блок 1: Тренировочные упражнения 💪';
    } else if (lowerTitle.contains('блок 2') || lowerTitle.contains('практик') || lowerTitle.contains('быт')) {
      return '### Блок 2: Практика в быту 🏠';
    } else if (lowerTitle.contains('блок 3') || lowerTitle.contains('творчеств') || lowerTitle.contains('вызов')) {
      return '### Блок 3: Творческий вызов 🎨';
    }
    
    // Предметные эмодзи
    if (lowerSubject.contains('математик')) {
      return '### $originalTitle 🔢';
    } else if (lowerSubject.contains('язык') || lowerSubject.contains('чтение') || lowerSubject.contains('письм')) {
      return '### $originalTitle 📚';
    } else if (lowerSubject.contains('природ') || lowerSubject.contains('окружающ')) {
      return '### $originalTitle 🌿';
    } else if (lowerSubject.contains('творчеств') || lowerSubject.contains('рисован') || lowerSubject.contains('музык')) {
      return '### $originalTitle 🎨';
    } else if (lowerSubject.contains('истори')) {
      return '### $originalTitle 🏛️';
    } else if (lowerSubject.contains('географи')) {
      return '### $originalTitle 🗺️';
    }
    
    return '### $originalTitle';
  }
  
  /// Проверяет, является ли строка особым блоком
  static bool _isSpecialBlock(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('главное правило урока:') ||
           lowerLine.contains('ловушка для внимательных:') ||
           lowerLine.contains('памятка для родителей:') ||
           lowerLine.contains('заметки учителя:') ||
           lowerLine.contains('линии для ответа:');
  }
  
  /// Улучшает особые блоки
  static String _enhanceSpecialBlock(String line) {
    final lowerLine = line.toLowerCase();
    
    if (lowerLine.contains('главное правило урока:')) {
      return '**Главное правило урока:** ${line.substring(line.indexOf(':') + 1).trim()}';
    } else if (lowerLine.contains('ловушка для внимательных:')) {
      return '**Ловушка для внимательных:** ${line.substring(line.indexOf(':') + 1).trim()}';
    } else if (lowerLine.contains('памятка для родителей:')) {
      return '**Памятка для родителей:** ${line.substring(line.indexOf(':') + 1).trim()}';
    } else if (lowerLine.contains('заметки учителя:')) {
      return '**Заметки учителя:** ${line.substring(line.indexOf(':') + 1).trim()}';
    }
    
    return line;
  }
  
  /// Проверяет, нужны ли линии для ответов
  static bool _needsAnswerLines(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('задание') ||
           lowerLine.contains('упражнение') ||
           lowerLine.contains('вопрос') ||
           (lowerLine.contains('ответ') && !lowerLine.contains('ответ:'));
  }
  
  /// Проверяет, содержит ли контент блок самооценки
  static bool _containsSelfAssessment(List<String> lines) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('самооценк') ||
          lowerLine.contains('рефлекс') ||
          lowerLine.contains('⭐⭐⭐') ||
          lowerLine.contains('оцени свои успехи')) {
        return true;
      }
    }
    return false;
  }
  
  /// Добавляет структуру Markdown к существующему контенту
  static String addMarkdownStructure(String content, Conspect conspect) {
    final buffer = StringBuffer();
    final lines = content.split('\n');
    
    buffer.writeln('# ${conspect.title}');
    buffer.writeln();
    buffer.writeln('**Предмет:** ${conspect.subject}');
    buffer.writeln('**Возрастная группа:** ${conspect.ageGroup}');
    buffer.writeln('**Длительность:** ${conspect.duration}');
    buffer.writeln();
    
    bool inSpecialSection = false;
    String currentSection = '';
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.isEmpty) {
        buffer.writeln();
        continue;
      }
      
      if (trimmed.toLowerCase().contains('цели и задачи')) {
        buffer.writeln('## 🎯 Цели и задачи занятия');
        inSpecialSection = true;
        currentSection = 'цели';
      } else if (trimmed.toLowerCase().contains('объяснение') || trimmed.toLowerCase().contains('теория')) {
        buffer.writeln('## 📋 Объяснение нового материала');
        inSpecialSection = true;
        currentSection = 'объяснение';
      } else if (trimmed.toLowerCase().contains('практическ') || trimmed.toLowerCase().contains('задани')) {
        buffer.writeln('## 📝 Практические задания');
        inSpecialSection = true;
        currentSection = 'задания';
      } else if (trimmed.toLowerCase().contains('домашн')) {
        buffer.writeln('## 🏠 Домашняя работа');
        inSpecialSection = true;
        currentSection = 'домашка';
      } else {
        buffer.writeln(line);
      }
    }
    
    // Добавляем недостающие разделы
    if (!content.toLowerCase().contains('рефлекс') && !content.toLowerCase().contains('самооценк')) {
      buffer.writeln();
      buffer.writeln('## 💭 Рефлексия и самооценка');
      buffer.writeln('⭐⭐⭐ Оцени свои успехи на занятии');
      buffer.writeln();
      buffer.writeln('- [ ] Отлично! Справился со всеми заданиями');
      buffer.writeln('- [ ] Хорошо! Было непросто, но я справился');
      buffer.writeln('- [ ] Нужна помощь учителя');
    }
    
    return buffer.toString();
  }
  
  /// Проверяет качество структуры контента
  static Map<String, dynamic> analyzeContentStructure(String content) {
    final lines = content.split('\n');
    
    // Инициализируем переменные с явными типами
    bool hasH1 = false;
    int h2Count = 0;
    int h3Count = 0;
    bool hasSpecialBlocks = false;
    bool hasAnswerLines = false;
    bool hasSelfAssessment = false;
    bool hasEmojis = false;
    final sections = <String>[];
    final recommendations = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('# ') && !trimmed.startsWith('##')) {
        hasH1 = true;
      } else if (trimmed.startsWith('## ')) {
        h2Count++;
        final title = trimmed.substring(3).trim();
        sections.add(title);
      } else if (trimmed.startsWith('### ')) {
        h3Count++;
      }
      
      if (_isSpecialBlock(trimmed)) {
        hasSpecialBlocks = true;
      }
      
      if (trimmed.contains('_______________________') || trimmed.contains('Линии для ответа:')) {
        hasAnswerLines = true;
      }
      
      if (trimmed.contains('⭐⭐⭐') || trimmed.toLowerCase().contains('самооценк') || trimmed.toLowerCase().contains('рефлекс')) {
        hasSelfAssessment = true;
      }
      
      // Проверка эмодзи (простые Unicode эмодзи)
      if (trimmed.contains('📋') || trimmed.contains('📄') || trimmed.contains('🏠') ||
          trimmed.contains('🎯') || trimmed.contains('💡') || trimmed.contains('⭐')) {
        hasEmojis = true;
      }
    }
    
    // Формируем рекомендации
    if (!hasH1) {
      recommendations.add('Добавьте заголовок H1 (# Название темы)');
    }
    
    if (h2Count < 3) {
      recommendations.add('Добавьте больше разделов H2 (## Раздел) - минимум 3');
    }
    
    if (!hasSpecialBlocks) {
      recommendations.add('Добавьте специальные блоки: "Главное правило урока:", "Ловушка для внимательных:"');
    }
    
    if (!hasAnswerLines) {
      recommendations.add('Добавьте "Линии для ответа: _______________________" к заданиям');
    }
    
    if (!hasSelfAssessment) {
      recommendations.add('Добавьте блок самооценки с ⭐⭐⭐');
    }
    
    if (!hasEmojis) {
      recommendations.add('Добавьте эмодзи в заголовки (📋, 📄, 🏠) для лучшей визуализации');
    }
    
    // Возвращаем результат как Map
    return {
      'hasH1': hasH1,
      'h2Count': h2Count,
      'h3Count': h3Count,
      'hasSpecialBlocks': hasSpecialBlocks,
      'hasAnswerLines': hasAnswerLines,
      'hasSelfAssessment': hasSelfAssessment,
      'hasEmojis': hasEmojis,
      'sections': sections,
      'recommendations': recommendations,
    };
  }
}