import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/topic_explanation_service.dart';
import 'package:metodist/services/worksheet_audit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> allTopics;
  late List<Map<String, dynamic>> newTopics;

  setUpAll(() {
    final file = File('assets/data/topics.json');
    expect(file.existsSync(), isTrue, reason: 'assets/data/topics.json must exist');
    final content = file.readAsStringSync();
    allTopics = (jsonDecode(content) as List).cast<Map<String, dynamic>>();
    expect(allTopics.length, 224, reason: 'Total topics count must be exactly 224');
    newTopics = allTopics.skip(173).toList();
    expect(newTopics.length, 51, reason: 'There must be 51 new topics (#174 to #224)');
  });

  String getSubjectForMethod(String methodId) {
    final m = methodId.toLowerCase();
    if (m.contains('pchelko')) return 'Математика';
    if (m.contains('kostin')) return 'Русский язык';
    if (m.contains('bogolyubov') || m.contains('mazina')) return 'Чистописание';
    if (m.contains('redozubov') || m.contains('chaplygin')) return 'Обучение чтению';
    return 'Грамота и логопедия';
  }

  group('Pedagogical Package Completeness for all 51 New Topics', () {
    test('Every new topic receives a rich, dedicated PedagogicalPackage', () {
      for (final topic in newTopics) {
        final title = topic['title'] as String;
        final age = topic['ageGroup'] as String? ?? 'grade_1';
        final methodId = topic['methodId'] as String? ?? '';
        final subject = getSubjectForMethod(methodId);

        final pkg = TopicExplanationService.getPedagogicalPackage(subject, title, age);

        // 1. Dedicated category (never fallback to generic default)
        expect(pkg.category, isNot(equals('default')),
            reason: 'Topic "$title" must have a specific category, not default');

        // 2. Deep pedagogical essence and metaphors
        expect(pkg.essence.length, greaterThanOrEqualTo(100),
            reason: 'Essence for "$title" must be detailed (>= 100 chars)');
        expect(pkg.metaphors.length, greaterThanOrEqualTo(2),
            reason: 'Must have at least 2 child-friendly metaphors for "$title"');

        // 3. Rule, misconception, and live dialogue
        expect(pkg.rule.trim(), isNotEmpty, reason: 'Rule cannot be empty for "$title"');
        expect(pkg.misconception.trim(), isNotEmpty, reason: 'Misconception cannot be empty for "$title"');
        expect(pkg.dialogueScript, contains('Учитель:'), reason: 'Dialogue must feature teacher for "$title"');
        expect(pkg.dialogueScript, contains('Дети:'), reason: 'Dialogue must feature children for "$title"');

        // 4. Materials: Table headers, isolated word bank
        expect(pkg.tableHeaders.length, greaterThanOrEqualTo(2),
            reason: 'Table must have at least 2 columns for "$title"');
        expect(pkg.wordBank.length, greaterThanOrEqualTo(4),
            reason: 'Word bank must contain at least 4 items for "$title"');

        // 5. Neznayka trap: mistake & correction
        expect(pkg.neznaykaMistake.trim(), isNotEmpty, reason: 'Neznayka mistake required for "$title"');
        expect(pkg.neznaykaCorrection.trim(), isNotEmpty, reason: 'Neznayka correction required for "$title"');

        // 6. Authentic Cipher & Zero Answer Leakage
        expect(pkg.cipherKey.length, greaterThanOrEqualTo(3), reason: 'Cipher key needs >= 3 entries for "$title"');
        expect(pkg.cipherCode.trim(), isNotEmpty, reason: 'Cipher code required for "$title"');
        expect(pkg.cipherAnswer.trim(), isNotEmpty, reason: 'Cipher answer required for "$title"');
        expect(pkg.cipherCode.contains(pkg.cipherAnswer), isFalse,
            reason: 'Cipher code must NEVER leak the answer in student task for "$title"');

        // 7. TRIZ Challenge
        expect(pkg.trizChallenge.trim(), isNotEmpty, reason: 'TRIZ challenge required for "$title"');
        expect(pkg.trizAnswer.trim(), isNotEmpty, reason: 'TRIZ answer required for "$title"');

        // 8. Teacher Answer Key (isolated)
        expect(pkg.teacherAnswers.trim(), isNotEmpty, reason: 'Teacher answers required for "$title"');
        expect(pkg.calligraphyElements.trim(), isNotEmpty, reason: 'Calligraphy elements required for "$title"');
      }
    });
  });

  group('Worksheet Audit & YandexART Alignment for all 51 New Topics', () {
    test('Simulated worksheet generation and audit scores meet logic & visual criteria', () {
      int totalArtCount = 0;
      int totalTasksAudited = 0;

      for (final topic in newTopics) {
        final title = topic['title'] as String;
        final age = topic['ageGroup'] as String? ?? 'grade_1';
        final methodId = topic['methodId'] as String? ?? '';
        final subject = getSubjectForMethod(methodId);
        final pkg = TopicExplanationService.getPedagogicalPackage(subject, title, age);

        // Build simulated 8-task markdown worksheet strictly following prompt template
        final worksheetContent = '''
# Лист заданий для печати: $title

#### Главное правило урока:
${pkg.rule}

#### Ловушка для внимательных:
${pkg.misconception}

**Задание 1: Образец решения**
Рассмотри готовый образец и выполни задание по аналогии.
Образец: первый пункт уже решен учителем.
Линии для ответа: _______________________

**Задание 2: Соедини стрелками**
Соедини линиями элементы левого и правого столбиков.
Элемент 1   ---   Признак А
Элемент 2   ---   Признак Б

**Задание 3: Графомоторная дорожка**
${pkg.calligraphyElements}
Линии для письма: _______________________

**Задание 4: Сортировочная таблица**
Распредели слова из корзинки по колонкам таблицы:
| ${pkg.tableHeaders.join(' | ')} |
|---|---|
|   |   |
|   |   |
Слова для распределения: ${pkg.wordBank.join(', ')}

**Задание 5: Ловушка Незнайки**
${pkg.neznaykaMistake}
Найди ошибку Незнайки и запиши правильное объяснение:
Линии для ответа: _______________________

**Задание 6: Практическое задание**
Примени изученное правило на практике.
Линии для ответа: _______________________

**Задание 7: Шифровка**
Разгадай зашифрованное слово с помощью кодовой таблицы:
${pkg.cipherKey.entries.map((e) => '[ ${e.key} = ${e.value} ]').join('  ')}
Код: ${pkg.cipherCode}
Разгаданное слово: _______________________

**Задание 8: ТРИЗ-задача для умников**
${pkg.trizChallenge}
Варианты для проверки: ${pkg.trizWords.join(', ')}
Линии для ответа: _______________________

#### ⭐⭐⭐ Оцени свои успехи на занятии:
- [ ] Я понял главное правило темы
- [ ] Я помог Незнайке исправить ошибку
- [ ] Я сам разгадал секретный шифр

## 🔑 Ключи и ответы для учителя:
${pkg.teacherAnswers}
''';

        // Run audit through WorksheetAuditService
        final evaluations = WorksheetAuditService.auditWorksheet(
          content: worksheetContent,
          topic: title,
          ageGroup: age,
          subject: subject,
          methodId: methodId,
        );

        expect(evaluations, isNotEmpty, reason: 'Audit must find tasks for "$title"');
        expect(evaluations.length, greaterThanOrEqualTo(6), reason: 'Worksheet should contain full exercise suite');

        for (final eval in evaluations) {
          totalTasksAudited++;
          // Pedagogical logic criteria
          expect(eval.logicScore, greaterThanOrEqualTo(8),
              reason: 'Logic score for task ${eval.taskIndex} in "$title" must be >= 8 (was ${eval.logicScore})');
          // Visual scaffolding criteria
          expect(eval.visualScore, greaterThanOrEqualTo(7),
              reason: 'Visual score for task ${eval.taskIndex} in "$title" must be >= 7 (was ${eval.visualScore})');
          // Orthography criteria
          expect(eval.orthographyScore, greaterThanOrEqualTo(9),
              reason: 'Orthography score for task ${eval.taskIndex} in "$title" must be >= 9');

          // YandexART checks
          if (eval.requiresArt) {
            totalArtCount++;
            expect(eval.isArtLogicallyAligned, isTrue,
                reason: 'Art must be logically aligned for task ${eval.taskIndex} in "$title"');
            expect(eval.yandexArtPrompt, isNotNull);
            expect(eval.yandexArtPrompt!, isNotEmpty);
            expect(eval.yandexArtPrompt!, contains(title));
          }
        }
      }

      // Check calibrated art percentage: 5% to 20% across all evaluated tasks
      final artRatio = totalArtCount / totalTasksAudited;
      expect(artRatio, inInclusiveRange(0.05, 0.20),
          reason: 'YandexART requirement should be calibrated to 5-20% of tasks (actual: ${(artRatio * 100).toStringAsFixed(1)}%)');
    });
  });
}
