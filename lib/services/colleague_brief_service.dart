import 'package:share_plus/share_plus.dart';
import '../models/conspect.dart';
import '../models/lesson_stage.dart';
import '../models/topic.dart';

/// Сервис формирования и шеринга краткой шпаргалки к уроку «Для коллеги»
class ColleagueBriefService {
  /// Генерация текстовой карточки/шпаргалки к уроку
  static String generateColleagueBrief(Conspect conspect) {
    final buffer = StringBuffer();

    buffer.writeln('📋 ШПАРГАЛКА К УРОКУ ДЛЯ КОЛЛЕГИ');
    buffer.writeln('════════════════════════════════════');
    buffer.writeln('📚 Тема: ${conspect.topic}');
    buffer.writeln('🎓 Методика: ${conspect.methodName}');
    buffer.writeln('👶 Возраст: ${Topic.getAgeGroupLabel(conspect.ageGroup)}');
    buffer.writeln('⏱ Время: ${conspect.duration}');
    buffer.writeln('────────────────────────────────────');

    // 1. Цели урока (извлечение из текста)
    final goalMatch = RegExp(
      r'#+\s*(?:1\.\s*)?Цель[^\n]*\n([\s\S]*?)(?=(?:\n#+|\Z))',
      caseSensitive: false,
    ).firstMatch(conspect.content);

    if (goalMatch != null) {
      final goals = goalMatch.group(1)?.trim();
      if (goals != null && goals.isNotEmpty) {
        buffer.writeln('🎯 КЛЮЧЕВЫЕ ЦЕЛИ:');
        final firstFewGoals = goals
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(3)
            .map((l) => l.trim().startsWith('-') || l.trim().startsWith('•') ? l.trim() : '• ${l.trim()}')
            .join('\n');
        buffer.writeln(firstFewGoals);
        buffer.writeln();
      }
    }

    // 2. Раздаточные материалы и карточки
    if (conspect.cards != null && conspect.cards!.isNotEmpty) {
      buffer.writeln('📦 РАЗДАТОЧНЫЕ МАТЕРИАЛЫ (${conspect.cards!.length} шт.):');
      for (final card in conspect.cards!) {
        buffer.writeln('• [${card.type.toUpperCase()}] ${card.frontText} — ${card.backText}');
      }
      buffer.writeln();
    } else {
      final matMatch = RegExp(
        r'#+\s*(?:2\.\s*)?Материалы[^\n]*\n([\s\S]*?)(?=(?:\n#+|\Z))',
        caseSensitive: false,
      ).firstMatch(conspect.content);
      if (matMatch != null) {
        final mats = matMatch.group(1)?.trim();
        if (mats != null && mats.isNotEmpty) {
          buffer.writeln('📦 МАТЕРИАЛЫ И ОБОРУДОВАНИЕ:');
          final firstMats = mats
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .take(3)
              .map((l) => l.trim().startsWith('-') || l.trim().startsWith('•') ? l.trim() : '• ${l.trim()}')
              .join('\n');
          buffer.writeln(firstMats);
          buffer.writeln();
        }
      }
    }

    // 3. Структура и тайминг этапов
    final stages = LessonStage.parseFromConspect(conspect.content, conspect.duration);
    if (stages.isNotEmpty) {
      buffer.writeln('⏳ СТРУКТУРА ЗАНЯТИЯ (ЭТАПЫ):');
      for (final stage in stages) {
        buffer.writeln('${stage.stageNumber}. ${stage.title} (${stage.durationMinutes} мин)');
      }
      buffer.writeln();
    }

    // 4. Подсказка и методический совет
    if (conspect.parentAudioScript != null && conspect.parentAudioScript!.trim().isNotEmpty) {
      buffer.writeln('💡 МЕТОДИЧЕСКИЙ АКЦЕНТ:');
      buffer.writeln('«${conspect.parentAudioScript!.trim()}»');
      buffer.writeln();
    }

    if (conspect.parentNotes.trim().isNotEmpty) {
      buffer.writeln('📝 ЗАМЕТКИ ПЕДАГОГА:');
      buffer.writeln(conspect.parentNotes.trim());
      buffer.writeln();
    }

    buffer.writeln('────────────────────────────────────');
    buffer.writeln('Сформировано в приложении «Методист»');

    return buffer.toString();
  }

  /// Шеринг шпаргалки через системный диалог поделиться
  static Future<void> shareColleagueBrief(Conspect conspect) async {
    final brief = generateColleagueBrief(conspect);
    await Share.share(
      brief,
      subject: 'Шпаргалка к уроку: ${conspect.topic} (${conspect.methodName})',
    );
  }
}
