/// Профиль регламента, объема и драматургии урока в строгой зависимости от его длительности.
class LessonDurationProfile {
  final int totalMinutes;
  final String label;
  final String targetCharactersRange;
  final int minCharacters;
  final int maxCharacters;
  final int targetStagesCount;
  final String stageStructureGuidelines;
  final int worksheetTasksCount;
  final String worksheetScopeGuideline;
  final String pacingGuideline;

  const LessonDurationProfile({
    required this.totalMinutes,
    required this.label,
    required this.targetCharactersRange,
    required this.minCharacters,
    required this.maxCharacters,
    required this.targetStagesCount,
    required this.stageStructureGuidelines,
    required this.worksheetTasksCount,
    required this.worksheetScopeGuideline,
    required this.pacingGuideline,
  });

  /// Создать профиль на основе текстовой строки длительности ("15 мин", "20 мин", "45 мин", "60 мин")
  static LessonDurationProfile fromDurationString(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    final mins = match != null ? (int.tryParse(match.group(1)!) ?? 45) : 45;

    if (mins <= 20) {
      // 15–20 минут: Мини-занятие / Дошкольники / СанПиН норма для малышей
      return LessonDurationProfile(
        totalMinutes: mins,
        label: '$mins минут (Мини-занятие / Дошкольный формат)',
        targetCharactersRange: '1800–2800 знаков живого диалога',
        minCharacters: 1800,
        maxCharacters: 2800,
        targetStagesCount: 4,
        stageStructureGuidelines: '''
СТРУКТУРА НА $mins МИНУТ (СТРОГО 3-4 КОМПАКТНЫХ ЭТАПА, БЕЗ ЗАТЯГИВАНИЯ):
- Этап 1: Эмоциональный вход, приветствие и завязка сюжета [2-3 мин]
- Этап 2: Игровое открытие одного ключевого понятия с наглядными предметами [7-9 мин]
- Этап 3: Пальчиковая нейроразминка или весёлая двигательная пауза [2-3 мин]
- Этап 4: Простое игровое микро-закрепление и похвала [3-4 мин]
(КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО раздувать конспект! Для $mins минут диалоги должны быть короткими и динамичными!)''',
        worksheetTasksCount: 3,
        worksheetScopeGuideline: 'Ровно 2–3 простых наглядных игровых задания (обвести, соединить стрелочками, одно простое действие). Не перегружать лист!',
        pacingGuideline: 'Компактные реплики учителя (до 15–20 слов), простые и живые реакции детей, быстрый темп смены зрительных опор, никакой длинной теории.',
      );
    } else if (mins <= 30) {
      // 25–30 минут: Сокращённый урок / 1 класс адаптационный период
      return LessonDurationProfile(
        totalMinutes: mins,
        label: '$mins минут (Сокращённый урок / 1 класс)',
        targetCharactersRange: '2800–3900 знаков живого диалога',
        minCharacters: 2800,
        maxCharacters: 3900,
        targetStagesCount: 5,
        stageStructureGuidelines: '''
СТРУКТУРА НА $mins МИНУТ (СТРОГО 4-5 ЭТАПОВ):
- Этап 1: Завязка сюжета и вводное погружение [3 мин]
- Этап 2: Актуализация знаний + нейроразминка [4-5 мин]
- Этап 3: Проблемная ситуация и вывод главного правила [9-11 мин]
- Этап 4: Кинезиологическая двигательная пауза [3 мин]
- Этап 5: Первичное закрепление с самопроверкой и итог [5-7 мин]''',
        worksheetTasksCount: 4,
        worksheetScopeGuideline: '3–4 задания базового и практического уровня (образец, таблица/сортировка, ловушка Незнайки).',
        pacingGuideline: 'Динамичный урок: лаконичные четкие объяснения, 1 яркая метафора, фокус на главном действии.',
      );
    } else if (mins <= 45) {
      // 35–45 минут: Классический академический урок
      return LessonDurationProfile(
        totalMinutes: mins,
        label: '$mins минут (Классический школьный урок)',
        targetCharactersRange: '4500–6500 знаков живого диалога',
        minCharacters: 4500,
        maxCharacters: 6500,
        targetStagesCount: 6,
        stageStructureGuidelines: '''
СТРУКТУРА НА $mins МИНУТ (КЛАССИЧЕСКИЕ 6 ЭТАПОВ):
- Этап 1: Организационный момент и сюжетная интрига [3-4 мин]
- Этап 2: Актуализация и пальчиковая нейрогимнастика [5-6 мин]
- Этап 3: Сократовский диалог и открытие нового знания [12-14 мин]
- Этап 4: Динамическая двигательная пауза [3-4 мин]
- Этап 5: Разноуровневое первичное закрепление и разбор ловушки [12-14 мин]
- Этап 6: Рефлексия успеха и открытий [3-4 мин]''',
        worksheetTasksCount: 6,
        worksheetScopeGuideline: '5–6 разноуровневых заданий (Уровень 1: Старт, Уровень 2: Практик, Уровень 3: Детектив Pro, шифровка).',
        pacingGuideline: 'Развернутая живая драматургия, детальные диалоги, перехват детских сомнений, глубокая проработка.',
      );
    } else {
      // 50–60+ минут: Углубленный интенсив / репетиторское занятие / кружок
      return LessonDurationProfile(
        totalMinutes: mins,
        label: '$mins минут (Углублённый урок / Интенсив)',
        targetCharactersRange: '7000–9800 знаков живого диалога',
        minCharacters: 7000,
        maxCharacters: 9800,
        targetStagesCount: 7,
        stageStructureGuidelines: '''
СТРУКТУРА НА $mins МИНУТ (УГЛУБЛЁННЫЕ 7 ЭТАПОВ ДЛЯ ИНТЕНСИВА):
- Этап 1: Мотивационный вызов и полное погружение в сюжет [5 мин]
- Этап 2: Актуализация с экспресс-диагностикой понятий [7-8 мин]
- Этап 3: Исследовательская лаборатория и эвристическое открытие [15-18 мин]
- Этап 4: Двухфазная нейропауза (дыхательная + кинезиологическая) [4-5 мин]
- Этап 5: Практикум-мастерская по 3 уровням с ловушками мышления [18-20 мин]
- Этап 6: Жизненный кейс функциональной грамотности (PISA/практика) [6-8 мин]
- Этап 7: Метакогнитивная рефлексия и дневник открытий [4-5 мин]''',
        worksheetTasksCount: 8,
        worksheetScopeGuideline: '7–8 разноуровневых заданий включая олимпиадный уровень, логическую шифровку и ТРИЗ-задачу.',
        pacingGuideline: 'Максимальная глубина погружения: развернутые сократовские диалоги, подробный разбор 2-3 гипотез детей, лабораторный опыт, парная и индивидуальная работа.',
      );
    }
  }
}
