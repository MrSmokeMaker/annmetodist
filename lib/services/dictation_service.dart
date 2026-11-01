import '../models/dictation_exercise.dart';

/// Сервис подготовки и проведения интерактивных аудио-диктантов (по Костину, Редозубову и Пчёлке)
class DictationService {
  /// Извлекает или формирует диктант на основе текста конспекта и темы
  static DictationExercise extractDictation({
    required String content,
    required String topic,
    required String subject,
    required String ageGroup,
  }) {
    final isMath = subject.toLowerCase().contains('матем') ||
        topic.toLowerCase().contains('числ') ||
        topic.toLowerCase().contains('счёт') ||
        topic.toLowerCase().contains('сложен') ||
        topic.toLowerCase().contains('вычитан');

    final items = <DictationItem>[];

    if (isMath) {
      // 1. Математический слуховой диктант по А. С. Пчёлке
      final mathProblems = _extractOrGenerateMathProblems(content, topic);
      for (int i = 0; i < mathProblems.length; i++) {
        final p = mathProblems[i];
        items.add(
          DictationItem(
            index: i + 1,
            spokenText: 'Пример номер ${i + 1}. ${p['spoken']}. Запишите только ответ.',
            cleanWord: '${p['equation']} = ${p['answer']}',
            ruleHint: p['hint'] ?? 'Арифметическое действие по шагам',
            pauseSeconds: 6,
          ),
        );
      }
    } else {
      // 2. Орфографический/словарный слуховой диктант по Н. А. Костину и С. П. Редозубову
      final words = _extractWordsFromContent(content, topic);
      for (int i = 0; i < words.length; i++) {
        final w = words[i];
        final syllables = _syllabify(w);
        items.add(
          DictationItem(
            index: i + 1,
            spokenText: 'Слово ${i + 1}. $w. Пишем орфографически: $syllables. Слово $w.',
            cleanWord: w,
            ruleHint: _detectRuleHint(w, topic),
            pauseSeconds: 5,
          ),
        );
      }
    }

    return DictationExercise(
      title: isMath
          ? 'Математический слуховой диктант: $topic'
          : 'Слуховой орфографический диктант: $topic',
      subject: subject,
      ageGroup: ageGroup,
      items: items,
      introScript: isMath
          ? 'Приготовьте черновик или тетрадь для устного счёта. Послушайте задание и запишите ответы через запятую.'
          : 'Приготовьте тетрадь в косую линейку и ручку. Записывайте слова аккуратно, диктуя себе по слогам.',
      conclusionScript: isMath
          ? 'Диктант окончен! Возьмите зелёную ручку и проверьте ответы по образцу.'
          : 'Диктант окончен! Возьмите зелёный карандаш и найдите свою лучшую букву-королеву.',
    );
  }

  /// Извлечение слов из конспекта (из банка слов, списков или каллиграфии)
  static List<String> _extractWordsFromContent(String content, String topic) {
    final Set<String> extracted = {};

    // Поиск банков слов
    final bankRegex = RegExp(
      r'(?:Слова для распределения|Банк слов|Слова для справок|Слова для практики|Пропиши слоги)[:\s]+([^\n]+)',
      caseSensitive: false,
    );
    final match = bankRegex.firstMatch(content);
    if (match != null) {
      final rawList = match.group(1)!;
      final parts = rawList.split(RegExp(r'[,;•\s]+'));
      for (final p in parts) {
        final clean = p.replaceAll(RegExp(r'[^а-яА-ЯёЁa-zA-Z0-9\-]'), '').trim();
        if (clean.length >= 2 && clean.length <= 15) {
          extracted.add(clean.toLowerCase());
          if (extracted.length >= 6) break;
        }
      }
    }

    // Если слов мало, дополняем качественным педагогическим набором по теме
    if (extracted.length < 5) {
      final t = topic.toLowerCase();
      if (t.contains('жи') || t.contains('ши')) {
        extracted.addAll(['машина', 'жираф', 'ёжик', 'шишка', 'чижик', 'лыжи']);
      } else if (t.contains('ча') || t.contains('ща')) {
        extracted.addAll(['чашка', 'роща', 'чудо', 'щука', 'туча', 'чайка']);
      } else if (t.contains('безударн')) {
        extracted.addAll(['вода', 'трава', 'гора', 'зима', 'река', 'леса']);
      } else if (t.contains('парн')) {
        extracted.addAll(['дуб', 'гриб', 'мороз', 'зуб', 'глаз', 'сказка']);
      } else if (t.contains('мягк') || t.contains('ь')) {
        extracted.addAll(['день', 'соль', 'конь', 'пальто', 'пень', 'медведь']);
      } else if (t.contains('слог')) {
        extracted.addAll(['мама', 'парта', 'школа', 'книга', 'ручка', 'пенал']);
      } else {
        extracted.addAll(['школа', 'ученик', 'парта', 'книга', 'тетрадь', 'класс']);
      }
    }

    return extracted.take(6).toList();
  }

  /// Разбиение слова на слоги с дефисом для орфографического проговаривания
  static String _syllabify(String word) {
    const vowels = 'аеёиоуыэюяАЕЁИОУЫЭЮЯ';
    final buffer = StringBuffer();
    for (int i = 0; i < word.length; i++) {
      buffer.write(word[i]);
      if (i < word.length - 1 &&
          vowels.contains(word[i]) &&
          !vowels.contains(word[i + 1])) {
        if (i < word.length - 2 && !vowels.contains(word[i + 2])) {
          // слог закрытый
          buffer.write(word[i + 1]);
          buffer.write('-');
          i++;
        } else {
          buffer.write('-');
        }
      }
    }
    return buffer.toString();
  }

  /// Определение правила для подсветки
  static String _detectRuleHint(String word, String topic) {
    final w = word.toLowerCase();
    if (w.contains('жи') || w.contains('ши')) {
      return 'Правило: ЖИ и ШИ пиши с буквой И';
    }
    if (w.contains('ча') || w.contains('ща')) {
      return 'Правило: ЧА и ЩА пиши с буквой А';
    }
    if (w.contains('чу') || w.contains('щу')) {
      return 'Правило: ЧУ и ЩУ пиши с буквой У';
    }
    if (w.endsWith('ь') || w.contains('ль') || w.contains('нь')) {
      return 'Мягкий знак указывает на мягкость согласного';
    }
    return 'Проговаривай четко каждый звук перед записью';
  }

  /// Генерация примеров для математического диктанта (Пчёлко)
  static List<Map<String, String>> _extractOrGenerateMathProblems(String content, String topic) {
    return [
      {
        'spoken': 'К числу 3 прибавить 2',
        'equation': '3 + 2',
        'answer': '5',
        'hint': 'Сложение единиц',
      },
      {
        'spoken': 'Из числа 5 вычесть 1',
        'equation': '5 - 1',
        'answer': '4',
        'hint': 'Вычитание единицы',
      },
      {
        'spoken': 'Первое слагаемое 2, второе 2. Найдите сумму',
        'equation': '2 + 2',
        'answer': '4',
        'hint': 'Нахождение суммы слагаемых',
      },
      {
        'spoken': 'Уменьшаемое 5, вычитаемое 3. Чему равна разность?',
        'equation': '5 - 3',
        'answer': '2',
        'hint': 'Нахождение разности',
      },
      {
        'spoken': 'Сколько нужно прибавить к 4, чтобы получить 5?',
        'equation': '4 + 1',
        'answer': '1',
        'hint': 'Состав числа 5',
      },
    ];
  }
}
