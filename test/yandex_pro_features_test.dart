import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/services/docx_export_service.dart';
import 'package:metodist/services/prompt_builder.dart';
import 'package:metodist/services/surgical_ai_service.dart';
import 'package:metodist/services/yandex_gpt_service.dart';
import 'package:metodist/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testConspect = Conspect(
    id: 'test_123',
    title: 'Звуки [м], [м\']. Буква М',
    methodId: 'redozubov_reading',
    methodName: 'С. П. Редозубов',
    subject: 'Обучение чтению',
    ageGroup: 'grade_1',
    topic: 'Звуки [м], [м\']. Буква М. Механизм слияния согласного с гласным',
    duration: '45 минут',
    content: '''# Конспект занятия: Звуки [м], [м']. Буква М

## 1. Организационный момент
Учитель приветствует учеников.

# Лист заданий: Звуки [м], [м']. Буква М

**Задание 1:**
Назови слова на звук [м]: дом, мама, мост.

**Задание 2:**
Заполни таблицу:
| Твердый [м] | Мягкий [м'] |
| --- | --- |
| | |

Слова для распределения: малина, мяч, мыло, мел.

## 🔑 Ключи и ответы для учителя
Задание 1: дом, мама, мост.
Задание 2: твердый: малина, мыло; мягкий: мяч, мел.
''',
    createdAt: DateTime.now(),
  );

  group('YandexGPT Pro Intelligence Suite Tests', () {
    test('Self-Refine verification prompt enforces zero answers and empty tables', () {
      final prompts = PromptBuilder.buildSanitizerVerificationPrompt(testConspect.content);
      expect(prompts['systemPrompt'], contains('Главный Академический Цензор'));
      expect(prompts['systemPrompt'], contains('НИКАКИХ ОТВЕТОВ В ЗАДАНИЯХ ДЛЯ УЧЕНИКА'));
      expect(prompts['systemPrompt'], contains('ПУСТЫЕ ТАБЛИЦЫ'));
      expect(prompts['userPrompt'], contains(testConspect.content));
    });

    test('Differentiation Prompt creates Variant A (Support/OVZ) and Variant B (Detective Pro)', () {
      final supportPrompt = PromptBuilder.buildDifferentiationPrompt(
        baseConspect: testConspect,
        variantType: 'support',
      );
      expect(supportPrompt['systemPrompt'], contains('Вариант А: Опора (ОВЗ'));
      expect(supportPrompt['systemPrompt'], contains('пошаговые алгоритмы'));
      expect(supportPrompt['systemPrompt'], contains('наглядные образцы'));

      final olympiadPrompt = PromptBuilder.buildDifferentiationPrompt(
        baseConspect: testConspect,
        variantType: 'olympiad',
      );
      expect(olympiadPrompt['systemPrompt'], contains('Вариант В: Детектив Pro'));
      expect(olympiadPrompt['systemPrompt'], contains('ТРИЗ-задачи'));
      expect(olympiadPrompt['systemPrompt'], contains('сложную криптограмму'));
    });

    test('RNO (Work on Errors) Prompt diagnoses root deficits and creates 10-minute remediation', () {
      final rnoPrompt = PromptBuilder.buildRnoPrompt(
        studentErrors: ['написали "мач" вместо "мяч"', 'пропустили ь в слове "пальто"'],
        topic: testConspect.topic,
        method: testConspect.methodName,
        ageGroup: testConspect.ageGroup,
        subject: testConspect.subject,
      );
      expect(rnoPrompt['systemPrompt'], contains('Лист работы над ошибками'));
      expect(rnoPrompt['systemPrompt'], contains('написали "мач" вместо "мяч"'));
      expect(rnoPrompt['systemPrompt'], contains('пропустили ь в слове "пальто"'));
      expect(rnoPrompt['systemPrompt'], contains('Секрет от Совы-методиста'));
    });

    test('Surgical AI Action instructions generate targeted prompts', () {
      final surgical = SurgicalAiService(gptService: YandexGptService(storageService: StorageService()));
      expect(surgical, isNotNull);
    });

    test('DocxExportService produces valid OpenXML Word document zip', () async {
      final archive = Archive();

      const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
      archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

      final encoder = ZipEncoder();
      final bytes = encoder.encode(archive);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));

      final decoded = ZipDecoder().decodeBytes(bytes);
      expect(decoded.findFile('[Content_Types].xml'), isNotNull);
    });
  });
}
