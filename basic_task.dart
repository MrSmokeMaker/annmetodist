/// Basic task definitions for the "Методист" application.
///
/// Каждый объект описывает один тип задания из категории **basic**.
/// Поля:
/// - `id` – уникальный идентификатор, используется в payload и system‑prompt.
/// - `title` – короткое название, отображается в UI.
/// - `template` – формулировка задания, которую видит учитель.
/// - `schema` – JSON‑схема параметров задания (в виде строки).
/// - `rendererId` – идентификатор функции отрисовки в `pdfmake_helper.js`.
/// - `iconId` – id SVG‑символа из `icons.svg`.
/// - `level` – уровень сложности: '1' (Старт), '2' (Практик), '3' (Детектив Pro).
/// - `difficultyVariants` – карта сложности → дополнительные параметры (можно расширять).
/// - `category` – категория задания: 'russian', 'math', 'reading', 'penmanship', 'logic', 'speech', 'memory', 'graphic', 'game', 'nature'.
///
/// При необходимости можно добавить новые поля, но текущие покрывают все требования.

class BasicTask {
  final String id;
  final String title;
  final String template;
  final String schema; // JSON schema as string
  final String rendererId;
  final String iconId;
  final String level; // '1' = Старт, '2' = Практик, '3' = Детектив Pro
  final String category; // 'russian' | 'math' | 'reading' | 'penmanship' | 'logic' | 'speech' | 'memory' | 'graphic' | 'game' | 'nature'
  final Map<String, dynamic> difficultyVariants;

  const BasicTask({
    required this.id,
    required this.title,
    required this.template,
    required this.schema,
    required this.rendererId,
    required this.iconId,
    this.level = '1',
    this.category = 'basic',
    this.difficultyVariants = const {},
  });
}

// ---------------------------------------------------------------------------
// Список всех базовых задач. Расширенный список с новыми типами заданий
// ---------------------------------------------------------------------------

const List<BasicTask> BASIC_TASKS = [
  // Русский язык - базовые задания (Уровень 1: Старт)
  BasicTask(
    id: 'dictation_short',
    title: 'Слуховой мини‑диктант',
    template: 'Продиктуйте 3–5 коротких слов по теме, ученик пишет их в строку‑пропись.',
    schema: '{"type":"object","properties":{"words":{"type":"array","items":{"type":"string"}}},"required":["words"]}',
    rendererId: 'renderDictationShort',
    iconId: 'icon-dictation',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'copy_text',
    title: 'Списывание с образцом',
    template: 'Покажите образец текста крупным шрифтом, ученик копирует его под образцом.',
    schema: '{"type":"object","properties":{"sample":{"type":"string"}},"required":["sample"]}',
    rendererId: 'renderCopyText',
    iconId: 'icon-copy',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'missing_letters',
    title: 'Вставь пропущенную букву',
    template: 'В слове одна буква заменена рамкой‑пропуском, ученику нужно вписать её.',
    schema: '{"type":"object","properties":{"word":{"type":"string"},"missingIndex":{"type":"integer"}},"required":["word","missingIndex"]}',
    rendererId: 'renderMissingLetters',
    iconId: 'icon-missing-letter',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'capital_letter',
    title: 'Большая буква',
    template: 'В предложении с именем собственным или в начале предложения нужно вписать заглавную букву.',
    schema: '{"type":"object","properties":{"sentence":{"type":"string"}},"required":["sentence"]}',
    rendererId: 'renderCapitalLetter',
    iconId: 'icon-capital',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'transfer_words',
    title: 'Раздели слова для переноса',
    template: 'Разделите слово на части, вставив вертикальную черту‑пропуск в нужном месте.',
    schema: '{"type":"object","properties":{"word":{"type":"string"}},"required":["word"]}',
    rendererId: 'renderTransferWords',
    iconId: 'icon-transfer',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Новые задания по русскому языку
  BasicTask(
    id: 'underline_vowels',
    title: 'Подчеркни гласные буквы',
    template: 'В словах или предложениях ученик подчёркивает все гласные буквы.',
    schema: '{"type":"object","properties":{"text":{"type":"string"}},"required":["text"]}',
    rendererId: 'renderUnderlineVowels',
    iconId: 'icon-vowel',
    level: '1',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'soft_sign',
    title: 'Мягкий знак',
    template: 'Вставь мягкий знак в нужное место слова.',
    schema: '{"type":"object","properties":{"words":{"type":"array","items":{"type":"string"}}},"required":["words"]}',
    rendererId: 'renderSoftSign',
    iconId: 'icon-soft-sign',
    level: '2',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'unscramble',
    title: 'Составь слово из букв',
    template: 'Составь правильное слово из перемешанных букв.',
    schema: '{"type":"object","properties":{"scrambledWord":{"type":"string"},"hint":{"type":"string"}},"required":["scrambledWord"]}',
    rendererId: 'renderUnscramble',
    iconId: 'icon-puzzle',
    level: '2',
    category: 'russian',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Математические задания
  BasicTask(
    id: 'addition_problems',
    title: 'Задачи на сложение',
    template: 'Реши задачи на сложение с наглядными примерами.',
    schema: '{"type":"object","properties":{"problems":{"type":"array","items":{"type":"string"}}},"required":["problems"]}',
    rendererId: 'renderAdditionProblems',
    iconId: 'icon-plus',
    level: '1',
    category: 'math',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'subtraction_problems',
    title: 'Задачи на вычитание',
    template: 'Реши задачи на вычитание с наглядными примерами.',
    schema: '{"type":"object","properties":{"problems":{"type":"array","items":{"type":"string"}}},"required":["problems"]}',
    rendererId: 'renderSubtractionProblems',
    iconId: 'icon-minus',
    level: '2',
    category: 'math',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'number_comparison',
    title: 'Сравнение чисел',
    template: 'Сравни числа и поставь знаки >, < или =.',
    schema: '{"type":"object","properties":{"pairs":{"type":"array","items":{"type":"string"}}},"required":["pairs"]}',
    rendererId: 'renderNumberComparison',
    iconId: 'icon-compare',
    level: '1',
    category: 'math',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'counting_objects',
    title: 'Счёт предметов',
    template: 'Посчитай предметы на картинке и запиши ответ.',
    schema: '{"type":"object","properties":{"imageDescription":{"type":"string"},"questions":{"type":"array","items":{"type":"string"}}},"required":["questions"]}',
    rendererId: 'renderCountingObjects',
    iconId: 'icon-count',
    level: '1',
    category: 'math',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Задания на чтение
  BasicTask(
    id: 'read_and_answer',
    title: 'Прочитай и ответь',
    template: 'Прочитай короткий текст и ответь на вопросы.',
    schema: '{"type":"object","properties":{"text":{"type":"string"},"questions":{"type":"array","items":{"type":"string"}}},"required":["text","questions"]}',
    rendererId: 'renderReadAndAnswer',
    iconId: 'icon-read',
    level: '2',
    category: 'reading',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'find_word_in_text',
    title: 'Найди слово в тексте',
    template: 'Найди и подчеркни в тексте указанные слова.',
    schema: '{"type":"object","properties":{"text":{"type":"string"},"wordsToFind":{"type":"array","items":{"type":"string"}}},"required":["text","wordsToFind"]}',
    rendererId: 'renderFindWordInText',
    iconId: 'icon-find',
    level: '2',
    category: 'reading',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'sequencing',
    title: 'Восстанови последовательность',
    template: 'Расставь предложения или картинки в правильном порядке.',
    schema: '{"type":"object","properties":{"items":{"type":"array","items":{"type":"string"}}},"required":["items"]}',
    rendererId: 'renderSequencing',
    iconId: 'icon-sequence',
    level: '1',
    category: 'reading',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Творческие и развивающие задания
  BasicTask(
    id: 'draw_and_label',
    title: 'Нарисуй и подпиши',
    template: 'Нарисуй предмет и подпиши его название.',
    schema: '{"type":"object","properties":{"items":{"type":"array","items":{"type":"string"}}},"required":["items"]}',
    rendererId: 'renderDrawAndLabel',
    iconId: 'icon-draw',
    level: '1',
    category: 'speech',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'match_pairs',
    title: 'Соедини пары',
    template: 'Соедини линией связанные между собой предметы или слова.',
    schema: '{"type":"object","properties":{"pairs":{"type":"array","items":{"type":"string"}}},"required":["pairs"]}',
    rendererId: 'renderMatchPairs',
    iconId: 'icon-match',
    level: '1',
    category: 'logic',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'word_search',
    title: 'Поиск слов',
    template: 'Найди слова в буквенной сетке.',
    schema: '{"type":"object","properties":{"gridSize":{"type":"integer"},"words":{"type":"array","items":{"type":"string"}}},"required":["gridSize","words"]}',
    rendererId: 'renderWordSearch',
    iconId: 'icon-search',
    level: '2',
    category: 'logic',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Графические и моторные задания
  BasicTask(
    id: 'trace_lines',
    title: 'Обведи линии',
    template: 'Обведи пунктирные линии, развивая мелкую моторику.',
    schema: '{"type":"object","properties":{"paths":{"type":"array","items":{"type":"string"}}},"required":["paths"]}',
    rendererId: 'renderTraceLines',
    iconId: 'icon-trace',
    level: '1',
    category: 'graphic',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'connect_dots',
    title: 'Соедини точки',
    template: 'Соедини точки по порядку, чтобы получилась картинка.',
    schema: '{"type":"object","properties":{"points":{"type":"array","items":{"type":"integer"}},"imageName":{"type":"string"}},"required":["points"]}',
    rendererId: 'renderConnectDots',
    iconId: 'icon-dots',
    level: '1',
    category: 'graphic',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Игровые задания
  BasicTask(
    id: 'crossword_simple',
    title: 'Простой кроссворд',
    template: 'Заполни кроссворд по изученной теме.',
    schema: '{"type":"object","properties":{"clues":{"type":"array","items":{"type":"string"}},"answers":{"type":"array","items":{"type":"string"}}},"required":["clues","answers"]}',
    rendererId: 'renderCrosswordSimple',
    iconId: 'icon-crossword',
    level: '2',
    category: 'game',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'riddles',
    title: 'Загадки',
    template: 'Разгадай загадки и запиши ответы.',
    schema: '{"type":"object","properties":{"riddles":{"type":"array","items":{"type":"string"}}},"required":["riddles"]}',
    rendererId: 'renderRiddles',
    iconId: 'icon-riddle',
    level: '2',
    category: 'speech',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Задания на развитие речи
  BasicTask(
    id: 'describe_picture',
    title: 'Опиши картинку',
    template: 'Рассмотри картинку и составь по ней рассказ.',
    schema: '{"type":"object","properties":{"imageDescription":{"type":"string"},"promptQuestions":{"type":"array","items":{"type":"string"}}},"required":["imageDescription"]}',
    rendererId: 'renderDescribePicture',
    iconId: 'icon-describe',
    level: '2',
    category: 'speech',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Задания на логику
  BasicTask(
    id: 'patterns',
    title: 'Продолжи узор',
    template: 'Продолжи логический узор или последовательность.',
    schema: '{"type":"object","properties":{"pattern":{"type":"string"},"options":{"type":"array","items":{"type":"string"}}},"required":["pattern","options"]}',
    rendererId: 'renderPatterns',
    iconId: 'icon-pattern',
    level: '2',
    category: 'logic',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  
  // Задания на память
  BasicTask(
    id: 'memory_game',
    title: 'Игра на память',
    template: 'Запомни и воспроизведи последовательность.',
    schema: '{"type":"object","properties":{"items":{"type":"array","items":{"type":"string"}}},"required":["items"]}',
    rendererId: 'renderMemoryGame',
    iconId: 'icon-memory',
    level: '2',
    category: 'memory',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),

  // ============================================================
  // НОВЫЕ ЗАДАНИЯ: таблицы (грибы, леса, моря) и кроссворды клетками
  // ============================================================

  // Табличные задания — природа (Уровень 2: Практик)
  BasicTask(
    id: 'table_mushrooms',
    title: 'Таблица: Грибы',
    template: 'Заполни таблицу о грибах: название, съедобность, где растёт.',
    schema: '{"type":"object","properties":{"theme":{"type":"string"},"rows":{"type":"array","items":{"type":"object"}}},"required":["theme","rows"]}',
    rendererId: 'renderTableTask',
    iconId: 'icon-table',
    level: '2',
    category: 'nature',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'table_forests',
    title: 'Таблица: Леса',
    template: 'Заполни таблицу о лесах: тип леса, растения, животные.',
    schema: '{"type":"object","properties":{"theme":{"type":"string"},"rows":{"type":"array","items":{"type":"object"}}},"required":["theme","rows"]}',
    rendererId: 'renderTableTask',
    iconId: 'icon-table',
    level: '2',
    category: 'nature',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
  BasicTask(
    id: 'table_seas',
    title: 'Таблица: Моря',
    template: 'Заполни таблицу о морях: обитатель, среда обитания, чем питается.',
    schema: '{"type":"object","properties":{"theme":{"type":"string"},"rows":{"type":"array","items":{"type":"object"}}},"required":["theme","rows"]}',
    rendererId: 'renderTableTask',
    iconId: 'icon-table',
    level: '2',
    category: 'nature',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),

  // Кроссворд клетками (без линий) — Уровень 3: Детектив Pro
  BasicTask(
    id: 'crossword_grid',
    title: 'Кроссворд клетками',
    template: 'Заполни клеточный кроссворд по подсказкам по теме занятия.',
    schema: '{"type":"object","properties":{"gridSize":{"type":"integer"},"cells":{"type":"array","items":{"type":"object"}},"cluesAcross":{"type":"array","items":{"type":"string"}},"cluesDown":{"type":"array","items":{"type":"string"}},"answers":{"type":"array","items":{"type":"string"}}},"required":["gridSize","cells","cluesAcross","cluesDown","answers"]}',
    rendererId: 'renderCrosswordGrid',
    iconId: 'icon-crossword-grid',
    level: '3',
    category: 'game',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),

  // Задания с буквами и разлиновкой — Уровень 1: Старт
  BasicTask(
    id: 'letter_tracing',
    title: 'Буквы с разлиновкой',
    template: 'Обведи букву по пунктиру и напиши самостоятельно на линиях.',
    schema: '{"type":"object","properties":{"letter":{"type":"string"},"words":{"type":"array","items":{"type":"string"}}},"required":["letter"]}',
    rendererId: 'renderLetterTask',
    iconId: 'icon-letter',
    level: '1',
    category: 'penmanship',
    difficultyVariants: {
      '1st': {},
      '2nd': {},
      '3rd': {},
    },
  ),
];
