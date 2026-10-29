import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/conspect.dart';

/// Сервис экспорта занятия в календарь (.ics / iCalendar RFC 5545)
class IcsExportService {
  /// Парсинг длительности занятия в минутах
  static int parseDurationMinutes(String rawDuration, {int fallback = 30}) {
    final match = RegExp(r'\d+').firstMatch(rawDuration);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ?? fallback;
    }
    return fallback;
  }

  /// Экранирование специальных символов для RFC 5545
  static String _escapeIcsText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n');
  }

  /// Форматирование даты в формат iCalendar UTC (YYYYMMDDTHHMMSSZ)
  static String _formatUtc(DateTime dt) {
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dt.toUtc());
  }

  /// Генерация содержимого .ics файла
  static String generateIcsString({
    required Conspect conspect,
    required DateTime startDateTime,
    int? customDurationMinutes,
  }) {
    final durationMinutes = customDurationMinutes ??
        parseDurationMinutes(conspect.duration, fallback: 30);
    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    final summary = _escapeIcsText('Урок: ${conspect.topic} (${conspect.methodName})');

    final descriptionBuffer = StringBuffer();
    descriptionBuffer.writeln('📚 Тема: ${conspect.topic}');
    descriptionBuffer.writeln('🎓 Методика: ${conspect.methodName}');
    descriptionBuffer.writeln('👶 Возраст: ${conspect.ageGroup}');
    descriptionBuffer.writeln('⏱ Длительность: $durationMinutes мин.');
    if (conspect.notes.isNotEmpty) {
      descriptionBuffer.writeln('📝 Заметки: ${conspect.notes}');
    }
    if (conspect.parentAudioScript != null &&
        conspect.parentAudioScript!.trim().isNotEmpty) {
      descriptionBuffer.writeln(
        '💡 Подсказка: ${conspect.parentAudioScript!.trim()}',
      );
    }
    descriptionBuffer.writeln('\nСгенерировано в приложении «Методист»');

    final escapedDescription = _escapeIcsText(descriptionBuffer.toString());
    final uid = '${conspect.id}_${startDateTime.millisecondsSinceEpoch}@metodist.app';

    final buffer = StringBuffer();
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//Metodist App//Pedagogical Lesson Planner//RU\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');
    buffer.write('BEGIN:VEVENT\r\n');
    buffer.write('UID:$uid\r\n');
    buffer.write('DTSTAMP:${_formatUtc(now)}\r\n');
    buffer.write('DTSTART:${_formatUtc(startDateTime)}\r\n');
    buffer.write('DTEND:${_formatUtc(endDateTime)}\r\n');
    buffer.write('SUMMARY:$summary\r\n');
    buffer.write('DESCRIPTION:$escapedDescription\r\n');
    buffer.write('STATUS:CONFIRMED\r\n');
    buffer.write('TRANSP:OPAQUE\r\n');
    buffer.write('END:VEVENT\r\n');
    buffer.write('END:VCALENDAR\r\n');

    return buffer.toString();
  }

  /// Получение байтов .ics файла
  static Uint8List generateIcsBytes({
    required Conspect conspect,
    required DateTime startDateTime,
    int? customDurationMinutes,
  }) {
    final icsString = generateIcsString(
      conspect: conspect,
      startDateTime: startDateTime,
      customDurationMinutes: customDurationMinutes,
    );
    return Uint8List.fromList(utf8.encode(icsString));
  }

  /// Шеринг / скачивание .ics файла события
  static Future<void> shareIcsFile({
    required Conspect conspect,
    required DateTime startDateTime,
    int? customDurationMinutes,
  }) async {
    final bytes = generateIcsBytes(
      conspect: conspect,
      startDateTime: startDateTime,
      customDurationMinutes: customDurationMinutes,
    );

    final cleanTitle = conspect.title
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9_]'), '_')
        .toLowerCase();
    final filename = 'lesson_${cleanTitle}_${DateFormat('yyyyMMdd').format(startDateTime)}.ics';

    final xFile = XFile.fromData(
      bytes,
      mimeType: 'text/calendar',
      name: filename,
    );

    await Share.shareXFiles(
      [xFile],
      text: 'Занятие «${conspect.topic}» добавлено в календарь',
    );
  }
}
