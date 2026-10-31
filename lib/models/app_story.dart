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
      // 1. Добро пожаловать
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
            title: '7 легендарных методик образования',
            subtitle: 'От А. С. Пчёлко до ТРИЗ и нейропсихологии',
            description:
                'Генерируйте материалы по классическим проверенным системам: арифметика Пчёлко, грамматика Костина, чистописание Боголюбова и Мазиной, кубики Чаплыгина.',
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

      // 2. Игровые миры и маскоты
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

      // 3. Раздаточные листы без подсказок
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
            badge: 'МЕТОДИКА ПРОВЕРКИ',
            title: 'Ключи и критерии оценивания',
            subtitle: 'Экономьте до 2 часов на проверке',
            description:
                'В конце каждого методического комплекса формируется лист экспресс-проверки для педагога с готовыми эталонами ответов и дескрипторами баллов ФГОС.',
            bulletPoints: [
              'Ключи ко всем номерам и шифровкам',
              'Критериальная шкала перевода баллов в отметку',
              'Памятка для родителей с наводящими вопросами',
            ],
            iconEmoji: '🔑',
            ctaLabel: 'Посмотреть образец',
            ctaAction: StoryActionType.openGenerator,
            gradientColors: [Color(0xFF14532D), Color(0xFF052E16)],
          ),
        ],
      ),

      // 4. ИИ и YandexGPT Pro
      AppStoryGroup(
        id: 'yandex_gpt',
        title: 'YandexGPT',
        authorName: 'AI Лаборатория',
        avatarEmoji: '⚡',
        ringColors: const [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)],
        slides: [
          const AppStorySlide(
            id: 'yandex_1',
            badge: 'ДВУХПРОХОДНАЯ НЕЙРОСЕТЬ',
            title: 'YandexGPT Pro на страже педагогики',
            subtitle: 'Глубокий контекст и живая драматургия',
            description:
                'Внутренний ИИ использует двухэтапный конвейер: сначала выстраивает дидактическую спираль темы, затем насыщает её живой речью и мнемониками.',
            bulletPoints: [
              'Анти-заблуждение: выявление типичной детской ошибки',
              'Яркие предметные метафоры из реального быта',
              'ТРИЗ-задачи открытого типа с несколькими решениями',
            ],
            iconEmoji: '💡',
            ctaLabel: 'Что умеет наш ИИ',
            ctaAction: StoryActionType.openNews,
            gradientColors: [Color(0xFF701A75), Color(0xFF4A044E)],
          ),
          const AppStorySlide(
            id: 'yandex_2',
            badge: 'УМНЫЕ ПОДСКАЗКИ',
            title: 'Виджет «Что я могу» прямо на главной',
            subtitle: 'Готовые шаблоны и идеи уроков в 1 тап',
            description:
                'Используйте интерактивные кнопки быстрого запроса: карточки-помощницы, сценарий открытого урока, ТРИЗ-разминки и дифференциацию.',
            bulletPoints: [
              'Подсказки адаптируются под выбранную тему',
              'Мгновенная вставка в поле генерации',
              'Рекомендации от ведущих методистов РФ',
            ],
            iconEmoji: '✨',
            ctaLabel: 'Открыть подсказки',
            ctaAction: StoryActionType.openTemplates,
            gradientColors: [Color(0xFF581C87), Color(0xFF3B0764)],
          ),
        ],
      ),

      // 5. Telegram-боты экосистемы
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
            badge: 'СВОИ КОМАНДЫ',
            title: 'Команда /addaction в MetodistAI',
            subtitle: 'Создавайте свои уникальные педагогические функции',
            description:
                'Настройте собственные кнопки в боте: генерацию тестов за 5 минут, сценарий родительского собрания или календарный план на 10 уроков.',
            bulletPoints: [
              'Команда /addaction сохраняет любой ваш промпт',
              'Быстрый вызов сохраненного шаблона в 1 клик',
              'Прямой экспорт сгенерированного файла в PDF',
            ],
            iconEmoji: '⚙️',
            ctaLabel: 'Подключить бота',
            ctaAction: StoryActionType.openBotsSheet,
            gradientColors: [Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ],
      ),

      // 6. Пакетный курс на четверть
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
        ],
      ),
    ];
  }
}
