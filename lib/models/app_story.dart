import 'package:flutter/material.dart';

enum StoryActionType {
  openGenerator,
  openThematicWorlds,
  openBotsSheet,
  openNews,
  openSettings,
  openTemplates,
  openDirector,
}

class AppStorySlide {
  final String id;
  final String badge;
  final String title;
  final String subtitle;
  final String description;
  final List<String> bulletPoints;
  final String iconEmoji;
  final String ctaLabel;
  final StoryActionType ctaAction;
  final List<Color> gradientColors;

  const AppStorySlide({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bulletPoints,
    required this.iconEmoji,
    required this.ctaLabel,
    required this.ctaAction,
    required this.gradientColors,
  });
}

class AppStoryGroup {
  final String id;
  final String title;
  final String authorName;
  final String avatarEmoji;
  final List<Color> ringColors;
  final List<AppStorySlide> slides;
  bool isViewed;

  AppStoryGroup({
    required this.id,
    required this.title,
    required this.authorName,
    required this.avatarEmoji,
    required this.ringColors,
    required this.slides,
    this.isViewed = false,
  });
}

class AppStoriesData {
  static List<AppStoryGroup> getSampleStories() {
    return [
      // 1. Экспресс-старт
      AppStoryGroup(
        id: 'welcome',
        title: 'Методист Pro',
        authorName: 'Анна Методист',
        avatarEmoji: '✨',
        ringColors: const [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
        slides: [
          const AppStorySlide(
            id: 'welcome_1',
            badge: 'ФГОС 2026',
            title: 'Умный генератор уроков за секунды',
            subtitle: 'Без шаблонных фраз и сухой теории',
            description:
                'Приложение генерирует пошаговые сценарии занятий с живыми диалогами педагога и учеников, таймингом каждого этапа и дидактическими играми.',
            bulletPoints: [
              'Живая речь учителя и естественные реплики класса',
              'Точный хронометраж каждого этапа занятия',
              'Соблюдение академических стандартов ФГОС',
            ],
            iconEmoji: '🎓',
            ctaLabel: 'Создать конспект',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
          const AppStorySlide(
            id: 'welcome_2',
            badge: 'КЛАССИКИ ПЕДАГОГИКИ',
            title: '8 легендарных методик образования',
            subtitle: 'От А. С. Пчёлко до ТРИЗ и Сингапура',
            description:
                'Генерируйте материалы по проверенным системам: арифметика Пчёлко, грамматика Костина, чистописание Боголюбова и Мазиной, кубики Чаплыгина, логопедия Косиновой и метод CPA.',
            bulletPoints: [
              'Предметная наглядность и счетные множества',
              'Глубокий морфемный анализ и этимология',
              'Нейропсихологический образный подход к письму',
            ],
            iconEmoji: '📚',
            ctaLabel: 'Выбрать методику',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ],
      ),

      // 2. Сингапурский метод и PISA
      AppStoryGroup(
        id: 'singapore_pisa',
        title: 'Сингапур & PISA',
        authorName: 'Мировой уровень',
        avatarEmoji: '🇸🇬',
        ringColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF10B981)],
        slides: [
          const AppStorySlide(
            id: 'singapore_1',
            badge: 'ТОП-1 В МИРЕ (PISA & TIMSS)',
            title: 'Сингапурский метод: от спичек к олимпиадной логике',
            subtitle: 'Как учить глубоко на простых подручных предметах',
            description:
                'Трёхступенчатый CPA-подход (Concrete -> Pictorial -> Abstract): ребёнок сначала трогает предметы руками, затем строит наглядную блок-модель (Bar Model), и лишь потом пишет формулу. Понимание без слепой зубрёжки!',
            bulletPoints: [
              'C (Concrete): спички, пуговицы, фасоль из кармана',
              'P (Pictorial): метод полосок Bar Modeling в тетради',
              'A (Abstract): осознанная математическая запись формул',
            ],
            iconEmoji: '🇸🇬',
            ctaLabel: 'Попробовать CPA-метод',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF083344), Color(0xFF0E7490)],
          ),
          const AppStorySlide(
            id: 'singapore_2',
            badge: 'СЕЛЬСКАЯ ЛАБОРАТОРИЯ',
            title: 'Функциональная грамотность в реальной жизни',
            subtitle: 'Математика за пределами школьной доски',
            description:
                'Каждый урок вооружает ребёнка жизненными кейсами: расчёт семян для грядки, взвешивание без гирь, экономика сельской ярмарки. Даже в сельской школе ребёнок получает старт мирового уровня.',
            bulletPoints: [
              'Eco-Print 2-в-1: экономия 50% бумаги для сельских школ',
              'Меловая доска (Zero-Paper): эталонный урок без принтера',
              'Смена ролей: 100% включение каждого ученика без шума',
            ],
            iconEmoji: '🌍',
            ctaLabel: 'Создать урок PISA',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF064E3B), Color(0xFF047857)],
          ),
        ],
      ),

      // 3. Сельская школа & Zero-Paper
      AppStoryGroup(
        id: 'zero_paper_rural',
        title: 'Zero-Paper',
        authorName: 'Сельская школа',
        avatarEmoji: '🌾',
        ringColors: const [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF84CC16)],
        slides: [
          const AppStorySlide(
            id: 'rural_1',
            badge: 'ZERO-PAPER ДОСКА',
            title: 'Меловая доска: урок без принтера и бумаги',
            subtitle: '3-створчатая архитектура наглядности',
            description:
                'Даже если в школе закончилась бумага или отключили свет — учитель проводит эталонный открытый урок по четкой схеме трех створок доски.',
            bulletPoints: [
              'Створка 1: Опорный банк и словарные слова',
              'Створка 2: CPA-модель и главное правило темы',
              'Створка 3: 3 уровня самостоятельных заданий',
            ],
            iconEmoji: '📋',
            ctaLabel: 'Раскладка доски',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF064E3B), Color(0xFF14532D)],
          ),
          const AppStorySlide(
            id: 'rural_2',
            badge: 'ЭКО-ПЕЧАТЬ ✂',
            title: 'Эко-печать 2-в-1: вдвое меньше бумаги',
            subtitle: 'Две карточки А5 на одном листе А4',
            description:
                'Умный экспорт размещает две полноценные индивидуальные карточки на одном горизонтальном листе с центральной линией разреза ножничками.',
            bulletPoints: [
              'Экономия 50% бумаги и ресурса картриджа',
              'Четкая пунктирная линия для разреза ✂',
              'Идеально подходит для малокомплектных классов',
            ],
            iconEmoji: '✂️',
            ctaLabel: 'Попробовать эко-печать',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF065F46), Color(0xFF047857)],
          ),
          const AppStorySlide(
            id: 'rural_3',
            badge: 'KITCHEN LAB',
            title: 'Пособия из подручных средств (0 ₽)',
            subtitle: 'Тактильное мышление без покупных наборов',
            description:
                'Совёнок подсказывает, как превратить обычные спички, пуговицы, сухие веточки и крупу в мощный нейротренажёр счёта и каллиграфии.',
            bulletPoints: [
              '10 спичек в нитке = «вязанка-десяток» по Пчёлке',
              'Фасолины двух цветов для перехода через десяток',
              'Шнурок с узелками вместо линейки и шагомера',
            ],
            iconEmoji: '🪵',
            ctaLabel: 'Открыть Kitchen Lab',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF1E3A8A), Color(0xFF172554)],
          ),
        ],
      ),

      // 4. Аудио-Студия & Диктант [PRO]
      AppStoryGroup(
        id: 'audio_studio',
        title: 'Аудио-Студия',
        authorName: 'Звук & Речь [PRO]',
        avatarEmoji: '🎙️',
        ringColors: const [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFD946EF)],
        slides: [
          const AppStorySlide(
            id: 'audio_1',
            badge: 'ГОЛОС СОВЁНКА',
            title: 'Голосовая заметка родителю в 1 клик',
            subtitle: 'Синтез речи Web Speech API без задержек',
            description:
                'Совёнок озвучивает доброжелательный 60-секундный итог урока для родителей с бегущим эквалайзером и встроенным телесуфлёром для педагога.',
            bulletPoints: [
              'Регулировка темпа речи (0.8x, 1.0x, 1.2x)',
              '18-полосный неоновый эквалайзер с волной',
              'Быстрая отправка текста в WhatsApp и Telegram',
            ],
            iconEmoji: '🎧',
            ctaLabel: 'Открыть аудио-студию',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF581C87), Color(0xFF3B0764)],
          ),
          const AppStorySlide(
            id: 'audio_2',
            badge: 'СЛУХОВОЙ ТРЕНАЖЁР',
            title: 'Интерактивный аудио-диктант',
            subtitle: '3 академических этапа диктовки',
            description:
                'Слуховой тренажёр по канонам Костина и Редозубова: сначала восприятие смысла, затем диктовка с паузами и таймером, и в конце — самопроверка «Зелёный карандаш».',
            bulletPoints: [
              'Этап 1: Ознакомительное прослушивание текста',
              'Этап 2: Пошаговая диктовка с мягким гонгом',
              'Этап 3: Самопроверка орфограмм и разбор ловушек',
            ],
            iconEmoji: '📝',
            ctaLabel: 'Запустить диктант',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF4A044E), Color(0xFF2E1065)],
          ),
          const AppStorySlide(
            id: 'audio_3',
            badge: 'ДИСЦИПЛИНА БЕЗ КРИКА',
            title: 'Колокольчик тишины 🔔 у доски',
            subtitle: 'Кристаллический звук на Web Audio API',
            description:
                'Нажмите клавишу B во время ведения урока — зазвучит перелив школьного звонка и появится доброжелательная рифмовка: «Раз-два — кружева! Внимание на экран!»',
            bulletPoints: [
              'Синтезированный звон без скачивания MP3-файлов',
              'Горячая клавиша «B» для моментального вызова',
              'Удержание 100% тишины и фокуса без крика',
            ],
            iconEmoji: '🔔',
            ctaLabel: 'Узнать про режим урока',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ],
      ),

      // 5. Игровые миры и маскоты
      AppStoryGroup(
        id: 'worlds',
        title: '5 Миров',
        authorName: 'Студия миров',
        avatarEmoji: '🦊',
        ringColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        slides: [
          const AppStorySlide(
            id: 'worlds_1',
            badge: 'ГЕЙМИФИКАЦИЯ',
            title: 'Сквозной сюжет и маскоты',
            subtitle: 'Дети учатся с горящими глазами',
            description:
                'Каждое занятие объединено единой легендой. Маскот встречает учеников в начале, задаёт загадки на раздатке и сопровождает в домашке.',
            bulletPoints: [
              '🦉 София: Академический космос знаний',
              '🦊 Лео: Детективное сыскное агентство',
              '🤖 Нова: Кибер-лаборатория изобретателей',
              '🐉 Игнис: Академия магии и стихий',
              '🐙 Немо: Батискаф подводных глубин',
            ],
            iconEmoji: '🚀',
            ctaLabel: 'Выбрать игровой мир',
            ctaAction: StoryActionType.openThematicWorlds,
            gradientColors: [Color(0xFF0C4A6E), Color(0xFF082F49)],
          ),
          const AppStorySlide(
            id: 'worlds_2',
            badge: 'YANDEX ART ШАПКИ',
            title: 'Фирменные иллюстрации YandexART',
            subtitle: 'Панорамный арт для каждого мира',
            description:
                'Премиальные раздаточные листы оформляются авторскими панорамными шапками и стикерами маскотов, создавая эффект профессиональной полиграфии.',
            bulletPoints: [
              'Художественные шапки 4K для каждого мира',
              'Эмоции и позы маскотов для раздаток',
              'Цветная и экономичная ч/б печать',
            ],
            iconEmoji: '🎨',
            ctaLabel: 'Попробовать арт-шапки',
            ctaAction: StoryActionType.openThematicWorlds,
            gradientColors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
          ),
        ],
      ),

      // 6. Кооперация: Смена ролей
      AppStoryGroup(
        id: 'role_shifting',
        title: 'Смена ролей',
        authorName: 'Кооперация (S)',
        avatarEmoji: '🎭',
        ringColors: const [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFBE123C)],
        slides: [
          const AppStorySlide(
            id: 'role_1',
            badge: 'KAGAN STRUCTURES',
            title: 'Парная работа: 4 роли в каждом задании',
            subtitle: 'Каждый ребёнок говорит и действует',
            description:
                'Вместо пассивного сидения за партой дети работают слаженной командой с четким разделением обязанностей.',
            bulletPoints: [
              '🧭 Штурман: читает условие и рассуждает вслух',
              '✍️ Летописец: ведет аккуратную запись решения',
              '🟢 Контролёр: подчеркивает успех зелёным карандашом',
              '📢 Спикер: защищает решение пары у доски',
            ],
            iconEmoji: '🤝',
            ctaLabel: 'Включить смену ролей',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF881337), Color(0xFF4C0519)],
          ),
          const AppStorySlide(
            id: 'role_2',
            badge: 'ГОРЯЧАЯ КЛАВИША S',
            title: 'Смена ролей по сигналу гонга (S)',
            subtitle: 'Ротация без хаоса и споров',
            description:
                'Нажмите клавишу S в режиме урока — раздастся мелодичный гонг, и пары поменяются обязанностями. Никто не устает от одной роли!',
            bulletPoints: [
              'Мягкий сигнал колокольчика на смену хода',
              'Всплывающая подсказка с правилами новой роли',
              'Равный опыт лидерства и исполнительства для всех',
            ],
            iconEmoji: '⚡',
            ctaLabel: 'Попробовать в уроке',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF9F1239), Color(0xFF500724)],
          ),
        ],
      ),

      // 7. Раздаточные листы без подсказок
      AppStoryGroup(
        id: 'worksheets',
        title: 'Раздатки Pro',
        authorName: 'Конструктор заданий',
        avatarEmoji: '📋',
        ringColors: const [Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF3B82F6)],
        slides: [
          const AppStorySlide(
            id: 'worksheets_1',
            badge: '3 УРОВНЯ СЛОЖНОСТИ',
            title: 'Трёхуровневые раздаточные листы',
            subtitle: 'Никаких подсказок в заданиях ученика!',
            description:
                'В раздаточных листах строго запрещены ответы в скобках. Все ключи и эталоны решений скрыты в отдельный блок для учителя.',
            bulletPoints: [
              'Уровень 1 • Старт: Базовые упражнения с образцом',
              'Уровень 2 • Практик: Таблицы с банком слов и исправление Незнайки',
              'Уровень 3 • Детектив Pro: ТРИЗ, шифровки и логические парадоксы',
            ],
            iconEmoji: '🎯',
            ctaLabel: 'Создать рабочий лист',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF064E3B), Color(0xFF022C22)],
          ),
          const AppStorySlide(
            id: 'worksheets_2',
            badge: 'КАЛЛИГРАФИЯ И СЕТКА',
            title: 'Сетка клеток 5х5 мм и Карточка-помощница',
            subtitle: 'Скаффолдинг по канонам Пчёлко и Мазиной',
            description:
                'Векторная сетка с точками-ориентирами формирует идеальный почерк, а отрезная «Карточка-помощница ✂» даёт подсказку тем, кто затрудняется.',
            bulletPoints: [
              'Тетрадная сетка клеток 5х5 мм с разметкой строк',
              'Отрезная памятка со стрелочками и алгоритмом',
              'Линии для ответов и трекер самооценки ⭐⭐⭐',
            ],
            iconEmoji: '📐',
            ctaLabel: 'Посмотреть раздатку',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF14532D), Color(0xFF052E16)],
          ),
        ],
      ),

      // 8. ТРИЗ: Мышление без зубрежки
      AppStoryGroup(
        id: 'triz_pedagogy',
        title: 'ТРИЗ Уроки',
        authorName: 'Лаборатория смекалки',
        avatarEmoji: '🧩',
        ringColors: const [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFE11D48)],
        slides: [
          const AppStorySlide(
            id: 'triz_1',
            badge: 'ПРОТИВОРЕЧИЯ АЛЬТШУЛЛЕРА',
            title: 'Учим мыслить, а не повторять',
            subtitle: 'Проблемные ситуации в каждом уроке',
            description:
                'В каждый конспект закладывается ТРИЗ-противоречие: как сделать предмет легким, но прочным; как измерить без линейки. Дети сами формулируют закон!',
            bulletPoints: [
              'Снятие страха ошибки и психологической инерции',
              'Поиск идеального конечного результата (ИКР)',
              'Эвристические вопросы открытого типа',
            ],
            iconEmoji: '💡',
            ctaLabel: 'Попробовать ТРИЗ',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF7C2D12), Color(0xFF431407)],
          ),
          const AppStorySlide(
            id: 'triz_2',
            badge: 'ЛОВУШКА НЕЗНАЙКИ',
            title: 'Ловушка Незнайки с прямой речью',
            subtitle: 'Критическое мышление через юмор',
            description:
                'Персонаж делает типичную детскую ошибку и убежденно доказывает её. Ученики ищут подвох, находят истину и защищают правило.',
            bulletPoints: [
              'Прямая речь Незнайки с характерной ошибкой',
              'Поиск нестыковок в аргументации персонажа',
              'Твёрдое закрепление правила без скуки',
            ],
            iconEmoji: '🪤',
            ctaLabel: 'Создать урок с ловушкой',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF831843), Color(0xFF500724)],
          ),
        ],
      ),

      // 9. Presenter Mode: Ведение урока
      AppStoryGroup(
        id: 'presenter_mode',
        title: 'Режим Урока',
        authorName: 'Presenter Mode',
        avatarEmoji: '⏱️',
        ringColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
        slides: [
          const AppStorySlide(
            id: 'presenter_1',
            badge: 'ЖИВОЙ ПУЛЬТ УРОКА',
            title: 'Ведение урока со смартфона и панели',
            subtitle: 'Тайминг этапов и контроль динамики',
            description:
                'Удобный экран презентера: таймер обратного отсчета по каждому этапу, прогресс-бар урока и быстрые переключатели этапов стрелками клавиатуры.',
            bulletPoints: [
              'Пробел: Пауза / Возобновить таймер',
              'Стрелки ← / →: Переход между этапами урока',
              'R: Сброс и повтор времени этапа',
            ],
            iconEmoji: '🚀',
            ctaLabel: 'Попробовать режим',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          const AppStorySlide(
            id: 'presenter_2',
            badge: 'САНПИН И ЗРЕНИЕ',
            title: 'Крупный шрифт и речевые паузы',
            subtitle: 'Здоровьесберегающие технологии',
            description:
                'Мгновенное переключение размера шрифта (16 -> 19 -> 22 pt) для чтения у доски, встроенная гимнастика для глаз и пальчиковые физминутки.',
            bulletPoints: [
              'Адаптивный размер шрифта в один клик',
              'Речевые паузы с готовым текстом разминки',
              'Охрана зрения и смена видов деятельности каждые 7-10 мин',
            ],
            iconEmoji: '🧘',
            ctaLabel: 'Открыть урок',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
        ],
      ),

      // 10. AI Совёнок-Методист
      AppStoryGroup(
        id: 'yandex_gpt',
        title: 'Совёнок AI',
        authorName: 'Педконсилиум',
        avatarEmoji: '🦉',
        ringColors: const [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)],
        slides: [
          const AppStorySlide(
            id: 'yandex_1',
            badge: 'ПЕДАГОГИЧЕСКИЙ КОНСИЛИУМ',
            title: 'Мгновенная адаптация под ОВЗ и ЗПР',
            subtitle: 'Советы опытного завуча в 1 тап',
            description:
                'Если ученик испытывает трудности — Совёнок подскажет, как разбить задачу на 3 микрошага, использовать тактильный якорь и включить метод зелёного карандаша.',
            bulletPoints: [
              'Быстрая помощь при синдроме дефицита внимания',
              'Адаптация объема письма без потери стандартов',
              'Бережная поддержка без стресса и стигматизации',
            ],
            iconEmoji: '🌾',
            ctaLabel: 'Открыть диалог с Совёнком',
            ctaAction: StoryActionType.openNews,
            gradientColors: [Color(0xFF701A75), Color(0xFF4A044E)],
          ),
          const AppStorySlide(
            id: 'yandex_2',
            badge: 'РОДИТЕЛЬСКИЙ ЧАТ',
            title: 'Готовые посты для WhatsApp и Telegram',
            subtitle: 'Родители станут вашими союзниками',
            description:
                'Совёнок за секунду составит тёплый, ёмкий пост: чему научились дети, за что похвалить ребёнка сегодня и какой 5-минутный совет попробовать дома без перегрузок.',
            bulletPoints: [
              'Доброжелательный академический тон',
              '3 уровня домашнего задания (ФГОС, практика, ТРИЗ)',
              'Мгновенное копирование в буфер обмена',
            ],
            iconEmoji: '💬',
            ctaLabel: 'Попробовать посты',
            ctaAction: StoryActionType.openTemplates,
            gradientColors: [Color(0xFF581C87), Color(0xFF3B0764)],
          ),
        ],
      ),

      // 11. Telegram-боты экосистемы
      AppStoryGroup(
        id: 'tg_bots',
        title: 'TG Боты',
        authorName: 'Telegram Экосистема',
        avatarEmoji: '🤖',
        ringColors: const [Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFFA855F7)],
        slides: [
          const AppStorySlide(
            id: 'tg_bots_1',
            badge: 'ЭКОСИСТЕМА ТЕЛЕГРАМ',
            title: 'Два официальных бота в Telegram',
            subtitle: 'Работайте на телефоне прямо из мессенджера',
            description:
                'Мы разделили задачи на двух специализированных ботов для максимального удобства и надежности.',
            bulletPoints: [
              '🤖 @annmetodist_bot: Основной бот с Telegram Mini App и быстрым доступом',
              '🦉 @MetodistAIpro_bot: Отдельный AI-помощник с живым диалогом, генерацией ДЗ и PDF',
              'Синхронизация сохранённых материалов между веб-версией и Telegram',
            ],
            iconEmoji: '✈️',
            ctaLabel: 'Открыть меню ботов',
            ctaAction: StoryActionType.openBotsSheet,
            gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
          const AppStorySlide(
            id: 'tg_bots_2',
            badge: 'ИНТЕРАКТИВНЫЕ ВИКТОРИНЫ',
            title: 'Экспорт тестов в Telegram Quiz Poll',
            subtitle: 'Готовые викторины с подсветкой ответа',
            description:
                'Экспортируйте проверочные тесты урока прямо в опрос Telegram Quiz или Яндекс.Формы в 1 клик для дистанционной работы.',
            bulletPoints: [
              'Автоматическая подсветка правильного ответа',
              'Методический комментарий при ошибке ученика',
              'Мгновенная статистика усвоения темы классом',
            ],
            iconEmoji: '📊',
            ctaLabel: 'Подключить бота',
            ctaAction: StoryActionType.openBotsSheet,
            gradientColors: [Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ],
      ),

      // 12. Пакетный курс на четверть [Директор]
      AppStoryGroup(
        id: 'bulk_curriculum',
        title: 'Четверть ZIP',
        authorName: 'Тариф Директор',
        avatarEmoji: '📦',
        ringColors: const [Color(0xFFEC4899), Color(0xFFF43F5E), Color(0xFFE11D48)],
        slides: [
          const AppStorySlide(
            id: 'bulk_1',
            badge: '15–30 УРОКОВ В 1 КЛИК',
            title: 'Пакетная генерация на всю четверть',
            subtitle: 'Полный тематический курс в едином ZIP',
            description:
                'Сформируйте взаимосвязанную дидактическую цепочку уроков на четверть или полугодие. Все уроки объединены единым маскотом и прогрессией.',
            bulletPoints: [
              'Автоматический расчет логической спирали уроков',
              'Формирование DOCX и PDF для каждого занятия',
              'Сводная аттестационная ведомость и матрица ФГОС',
            ],
            iconEmoji: '📁',
            ctaLabel: 'Открыть генератор четверти',
            ctaAction: StoryActionType.openDirector,
            gradientColors: [Color(0xFF831843), Color(0xFF500724)],
          ),
          const AppStorySlide(
            id: 'bulk_2',
            badge: 'КОНСТРУКТОР ШКОЛЫ',
            title: 'Управление кафедрой и авторский стиль',
            subtitle: 'Единый цифровой стандарт лицея или гимназии',
            description:
                'Загрузите эмблему школы, сгенерируйте уникального маскота кафедры, настройте стоп-слова и раздайте доступы 3–5 учителям параллели.',
            bulletPoints: [
              'Собственная студия школьных миров и гербов',
              'Корпоративная матрица успеваемости и отчетность',
              'Единый архив уроков для взаимозаменяемости учителей',
            ],
            iconEmoji: '🏫',
            ctaLabel: 'Перейти в кабинет директора',
            ctaAction: StoryActionType.openDirector,
            gradientColors: [Color(0xFF701A75), Color(0xFF3B0764)],
          ),
        ],
      ),
    ];
  }
}
