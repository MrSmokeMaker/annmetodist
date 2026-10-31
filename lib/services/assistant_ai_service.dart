import 'package:flutter/foundation.dart';
import 'yandex_gpt_service.dart';
import 'storage_service.dart';
import '../models/thematic_world.dart';

/// Тип сообщения в чате с Совёнком
enum AssistantSender {
  user,
  assistant,
  system,
}

/// Сообщение в чате AI-помощника
class AssistantMessage {
  final String id;
  final AssistantSender sender;
  final String text;
  final DateTime timestamp;
  final String? actionType; // 'insert_snippet', 'change_world', 'export_pdf'
  final String? actionPayload;

  AssistantMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.actionType,
    this.actionPayload,
  });
}

/// Быстрые подсказки / чипсы для учителя
class AssistantQuickPrompt {
  final String title;
  final String prompt;
  final String icon;

  const AssistantQuickPrompt({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}

/// Сервис AI-помощника «Совёнок-Методист»
class AssistantAiService {
  final StorageService _storageService;
  final YandexGptService _gptService;

  AssistantAiService({
    StorageService? storageService,
    YandexGptService? gptService,
  })  : _storageService = storageService ?? StorageService(),
        _gptService = gptService ??
            YandexGptService(
              storageService: storageService ?? StorageService(),
            );

  /// Доступные быстрые чипсы-запросы
  static const List<AssistantQuickPrompt> quickPrompts = [
    AssistantQuickPrompt(
      title: '🤸 Физкультминутка',
      prompt: 'Придумай тематическую разминку-физкультминутку для детей с движениями и стишком под текущую тему урока.',
      icon: '🤸',
    ),
    AssistantQuickPrompt(
      title: '🧩 Задача ТРИЗ',
      prompt: 'Предложи нестандартную проблемную ТРИЗ-задачу или противоречие по теме урока для развития смекалки.',
      icon: '🧩',
    ),
    AssistantQuickPrompt(
      title: '🪤 Ловушка Незнайки',
      prompt: 'Составь забавное задание-ловушку от лица Незнайки с типичной ошибкой по теме урока, чтобы дети её нашли и доказали правильный ответ.',
      icon: '🪤',
    ),
    AssistantQuickPrompt(
      title: '🎯 Упростить задание',
      prompt: 'Как адаптировать сложное задание урока для учеников с трудностями в обучении, чтобы сохранить дидактическую цель?',
      icon: '🎯',
    ),
    AssistantQuickPrompt(
      title: '🔍 Проверить по ФГОС',
      prompt: 'Проведи экспресс-аудит структуры урока: соответствие ФГОС, хронометраж и сменяемость видов деятельности.',
      icon: '🔍',
    ),
    AssistantQuickPrompt(
      title: '🎨 Идея для мира',
      prompt: 'Как органично вплести сюжет текущего игрового мира (персонажа и локацию) в тему урока?',
      icon: '🎨',
    ),
  ];

  /// Системный промпт Совёнка-Методиста
  String _buildSystemPrompt({
    String? currentTopic,
    ThematicWorld? currentWorld,
    String? currentMethod,
    String? ageGroup,
  }) {
    final worldContext = currentWorld != null
        ? 'Текущий игровой мир: "${currentWorld.title}" (Маскот: ${currentWorld.mascotName}).'
        : 'Текущий мир: Сказочный лес.';

    final topicContext = currentTopic != null && currentTopic.isNotEmpty
        ? 'Тема урока: "$currentTopic".'
        : 'Урок начальной школы / дошкольников.';

    final methodContext = currentMethod != null && currentMethod.isNotEmpty
        ? 'Базовая методика: $currentMethod.'
        : 'Классическая методика (Пчёлко / Костин).';

    return '''
Ты — «Совёнок-Методист» 🦉, мудрый, добрый, остроумный и академически безупречный персональный AI-помощник учителя начальных классов и воспитателя дошкольников в системе «Методист Pro».

Твоя миссия:
1. Помогать учителю проектировать идеальные, вдохновляющие уроки без педагогической шелухи и монотонности.
2. Использовать лучшие принципы классических советских методик (Пчёлко А.С., Костин Н.А., Редозубов С.П., Мазина В.Д., Боголюбов Н.Н., Чаплыгин Е.В., Косинова Е.М.) и современные ТРИЗ-технологии.
3. Соблюдать СанПиН нормы: смена деятельности каждые 7-10 минут, беречь зрение детей, включать двигательные разминки.
4. Отвечать кратко, ёмко, структурированно, с тёплым уважительным тоном («У-ху! Давайте сделаем этот урок незабываемым!»).

Контекст урока:
- $topicContext
- $worldContext
- $methodContext
- Возрастная группа: ${ageGroup ?? '1-2 класс (7-8 лет)'}.

Правила оформления ответов:
- Используй Markdown: жирный шрифт для ключевых понятий, списки, цитаты.
- Если предлагаешь задание или разминку — пиши готовый текст, который учитель может сразу зачитать классу.
- Будь готов предложить конкретную механику или готовый блок конспекта.
''';
  }

  /// Отправка запроса в YandexGPT Pro с педагогическим фоллбеком
  Future<String> askAssistant({
    required String question,
    List<AssistantMessage> history = const [],
    String? currentTopic,
    ThematicWorld? currentWorld,
    String? currentMethod,
    String? ageGroup,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      currentTopic: currentTopic,
      currentWorld: currentWorld,
      currentMethod: currentMethod,
      ageGroup: ageGroup,
    );

    try {
      final gptResponse = await _gptService.generateConspect(
        systemPrompt: systemPrompt,
        userPrompt: question,
      );
      if (gptResponse.trim().isNotEmpty) {
        return gptResponse.trim();
      }
    } catch (e) {
      debugPrint('AssistantAiService network call info: $e');
    }

    // Автономный эвристический педагогический генератор (fallback)
    return _generatePedagogicalFallback(
      question: question,
      topic: currentTopic ?? 'Счёт и письмо',
      world: currentWorld ?? ThematicWorld.allWorlds.first,
    );
  }

  /// Умный оффлайн-генератор ответов Совёнка
  String _generatePedagogicalFallback({
    required String question,
    required String topic,
    required ThematicWorld world,
  }) {
    final lower = question.toLowerCase();

    // 1. Физкультминутка
    if (lower.contains('физкульт') || lower.contains('разминк') || lower.contains('движен')) {
      return '''
🦉 **У-ху! Тематическая разминка для мира «${world.title}»**

*Тема урока:* **$topic**

*(Учитель просит детей встать около парт)*

> **1. «Достань до звёзд» (Потягивание, 30 сек):**  
> Мы потянемся на носочках высоко-высоко, пальчики растопырили, как лучики солнца. Вдох — носом, выдох — ртом!
>
> **2. «Хитрый маскот ${world.mascotName}» (Координация, 45 сек):**  
> Правая рука гладит животик по часовой стрелке, а левая рука аккуратно хлопает по макушке. А теперь поменяли ручки!
>
> **3. «Глазки-стрелочки» (Гимнастика для глаз по СанПиН):**  
> Посмотрели на кончик носа — перевели взгляд в окно на дальнее облако (повторить 4 раза).

*Совет Совёнка:* после такой разминки кора головного мозга насыщается кислородом, и дети готовы к сложным заданиям! ⭐
''';
    }

    // 2. Ловушка Незнайки
    if (lower.contains('ловушк') || lower.contains('незнайк') || lower.contains('ошибк')) {
      return '''
🦉 **Задание «Ловушка Незнайки» по теме «$topic»**

В наш мир «${world.title}» прибежал Незнайка и радостно кричит:  
> *«Я самый умный! Я знаю всё про тему "$topic" и утверждаю, что правила учить не надо — как слышится, так и пишется!»*

**Задание для ребят:**
1. Найдите ошибку в рассуждении Незнайки.
2. Назовите главное академическое правило нашей темы.
3. Помогите маскоту **${world.mascotName}** исправить карточку Незнайки и заработать победный кристалл! 💎
''';
    }

    // 3. ТРИЗ и игровая механика
    if (lower.contains('триз') || lower.contains('игр') || lower.contains('проблем')) {
      return '''
🦉 **ТРИЗ-задача: «Противоречие в мире ${world.title}»**

*Тема:* **$topic**

**Сюжетная завязка:**  
Маскот **${world.mascotName}** столкнулся с неожиданной задачей: предмет должен быть одновременно лёгким, чтобы его унести, но очень прочным, чтобы выдержать проверку на уроке!

**Вопросы для мозгового штурма детей:**
- Как решить эту задачу, используя свойства темы «$topic»?
- Что, если разделить предмет во времени или пространстве?
- Какое нестандартное применение мы можем предложить?

*Методическая ценность:* Развивает гибкость мышления по Г.С. Альтшуллеру и снимает страх неправильного ответа.
''';
    }

    // 4. Упрощение / адаптация
    if (lower.contains('упрост') || lower.contains('сложн') || lower.contains('адапт')) {
      return '''
🦉 **Методическая адаптация по принципу Пчёлко и Редозубова**

Чтобы помочь ученикам с трудностями в освоении темы **«$topic»**:

1. **Включите предметную наглядность:** перейдите от абстрактных символов к счётным палочкам, карточкам с рисунками YandexART или пуговицам.
2. **Разбейте алгоритм на 3 микро-шага:**  
   * Шаг 1: Вижу образец.  
   * Шаг 2: Проговариваю вслух шепотом.  
   * Шаг 3: Записываю в тетрадь.
3. **Парная работа:** посадите ученика с более уверенным соседом по парте для взаимного контроля по памятке.
''';
    }

    // 5. Общий педагогический ответ
    return '''
🦉 **Ответ Совёнка-Методиста**

По теме урока **«$topic»** в мире **«${world.title}»**:

* Рекомендую уделить 7–10 минут устному коллективному разбору с опорой на наглядность.
* Для закрепления используйте дидактические карточки с маскотом **${world.mascotName}**.
* На этапе рефлексии попросите ребят оценить свои силы с помощью 3 звёздочек ⭐⭐⭐.

Если нужно, я могу моментально составить разминку, карточку с ловушкой или скорректировать формулировку любого упражнения! Напишите, что именно добавить.
''';
  }
}
