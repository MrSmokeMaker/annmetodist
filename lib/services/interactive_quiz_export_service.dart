import 'dart:convert';

/// Модель одного вопроса викторины/теста
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_option_id': correctOptionIndex,
        'explanation': explanation,
      };
}

/// Сервис экспорта вопросов в интерактивные квизы (Telegram Polls, Яндекс.Формы, JSON)
class InteractiveQuizExportService {
  /// Автоматически извлекает или генерирует 3–5 вопросов квиза из конспекта и листа заданий
  static List<QuizQuestion> extractQuizQuestions({
    required String content,
    required String topic,
    required String subject,
    required String ageGroup,
  }) {
    final questions = <QuizQuestion>[];

    // 1. Попытка извлечь ловушку Незнайки как вопрос на поиск ошибки
    final trapRegex = RegExp(
      r'Незнайка[^:]*:\s*["«]([^"»\n]+)["»]',
      caseSensitive: false,
    );
    final trapMatch = trapRegex.firstMatch(content);
    if (trapMatch != null) {
      final mistake = trapMatch.group(1)!.trim();
      questions.add(
        QuizQuestion(
          question: 'Незнайка утверждает: "$mistake". Прав ли Незнайка?',
          options: const [
            'Незнайка не прав — допущена ошибка в правиле',
            'Незнайка абсолютно прав',
            'Правило здесь вообще не применимо',
          ],
          correctOptionIndex: 0,
          explanation: 'Незнайка ошибся! Для верного ответа нужно применить главное правило урока по теме "$topic".',
        ),
      );
    }

    // 2. Извлечение главного правила урока
    final ruleRegex = RegExp(
      r'(?:Главное правило урока|Правило|Мнемоника)[:\s]+([^\n]+)',
      caseSensitive: false,
    );
    final ruleMatch = ruleRegex.firstMatch(content);
    if (ruleMatch != null) {
      final rule = ruleMatch.group(1)!.trim();
      questions.add(
        QuizQuestion(
          question: 'Какое главное правило мы изучили по теме "$topic"?',
          options: [
            rule.length > 80 ? '${rule.substring(0, 77)}...' : rule,
            'Правило можно не соблюдать, если торопишься',
            'Ответ всегда выбирается наугад',
          ],
          correctOptionIndex: 0,
          explanation: 'Золотое правило темы: $rule',
        ),
      );
    }

    // 3. Вопрос по ТРИЗ или шифровке
    final cipherRegex = RegExp(
      r'(?:Шифр|Шифровка|Кодовая таблица)[^\n]*\n([^\n]+)',
      caseSensitive: false,
    );
    final cipherMatch = cipherRegex.firstMatch(content);
    if (cipherMatch != null) {
      questions.add(
        QuizQuestion(
          question: 'Какой важный секрет помогла открыть шифровка на уроке по теме "$topic"?',
          options: const [
            'Внимательность к каждому символу и знаку',
            'Быстроту нажатия на кнопки без размышлений',
            'Списывание готового ответа у соседа',
          ],
          correctOptionIndex: 0,
          explanation: 'Шифровка развивает аналитическое мышление, декодирование и самоконтроль.',
        ),
      );
    }

    // 4. Практический вопрос по предмету, если вопросов мало
    if (questions.length < 3) {
      final isMath = subject.toLowerCase().contains('матем');
      if (isMath) {
        questions.add(
          QuizQuestion(
            question: 'Как проверить результат решения задачи по теме "$topic"?',
            options: const [
              'Составить обратную задачу или проверить условие по шагам',
              'Спросить у соседа по парте',
              'Сложить все числа наугад',
            ],
            correctOptionIndex: 0,
            explanation: 'По методике А. С. Пчёлко проверка решения через обратную задачу обязательна!',
          ),
        );
      } else {
        questions.add(
          QuizQuestion(
            question: 'Что помогает писать и читать без ошибок по теме "$topic"?',
            options: const [
              'Чёткое орфографическое проговаривание по слогам и самопроверка',
              'Быстрое письмо без внимания к буквам',
              'Угадывание слов по первой букве',
            ],
            correctOptionIndex: 0,
            explanation: 'По методике Н. А. Костина орфографическое проговаривание — ключ к грамотности!',
          ),
        );
      }
    }

    // 5. Оценочный рефлексивный вопрос
    questions.add(
      const QuizQuestion(
        question: 'Что делать, если в упражнении встретилась трудность («Ступенька вниз»)?',
        options: [
          'Взять карточку-помощницу с наглядным образцом и разобрать по шагам',
          'Сдаться и бросить решение',
          'Закрыть тетрадь и сказать, что всё решено',
        ],
        correctOptionIndex: 0,
        explanation: 'Стратегия скаффолдинга: опора на карточку-помощницу помогает преодолеть трудность!',
      ),
    );

    return questions;
  }

  /// Форматирует вопросы в формат Telegram Quiz (для отправки в боты @annmetodist_bot или @MetodistAIpro_bot)
  static String formatForTelegramQuiz(List<QuizQuestion> questions, String topic) {
    final buffer = StringBuffer();
    buffer.writeln('🎲 **Интерактивная Telegram-викторина по теме: $topic**\n');
    buffer.writeln('_Готовые опросы в режиме Quiz для проведения в школьном чате или через бота:_\n');

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      buffer.writeln('**Вопрос ${i + 1}:** ${q.question}');
      for (int optIdx = 0; optIdx < q.options.length; optIdx++) {
        final prefix = optIdx == q.correctOptionIndex ? '✅' : '⚪';
        buffer.writeln('$prefix ${q.options[optIdx]}');
      }
      buffer.writeln('💡 _Объяснение для учеников:_ ${q.explanation}\n');
    }

    return buffer.toString();
  }

  /// Форматирует вопросы в формат Яндекс.Форм (CSV/текстовая структура для быстрой вставки)
  static String formatForYandexForms(List<QuizQuestion> questions, String topic) {
    final buffer = StringBuffer();
    buffer.writeln('# Яндекс.Формы: Экспресс-квиз по теме "$topic"\n');
    buffer.writeln('Тип формы: Тест с оценкой правильности ответов\n');

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      buffer.writeln('---');
      buffer.writeln('Вопрос ${i + 1} (Один вариант):');
      buffer.writeln(q.question);
      buffer.writeln('Варианты ответа:');
      for (int optIdx = 0; optIdx < q.options.length; optIdx++) {
        final isCorrect = optIdx == q.correctOptionIndex ? ' [ВЕРНЫЙ - 1 балл]' : '';
        buffer.writeln('- ${q.options[optIdx]}$isCorrect');
      }
      buffer.writeln('Комментарий к правильному ответу: ${q.explanation}');
    }

    return buffer.toString();
  }

  /// Форматирует в компактный JSON для программной интеграции с ботами
  static String formatToJson(List<QuizQuestion> questions, String topic) {
    final data = {
      'topic': topic,
      'total_questions': questions.length,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
