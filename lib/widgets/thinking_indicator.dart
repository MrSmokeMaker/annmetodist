import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../constants.dart';
import 'glass_card.dart';

class ThinkingStep {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const ThinkingStep({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });
}

class ThinkingIndicator extends StatefulWidget {
  final Set<GenerationType>? materials;
  final bool isDeepLesson;
  final String? topic;
  final String message;

  const ThinkingIndicator({
    super.key,
    this.materials,
    this.isDeepLesson = false,
    this.topic,
    this.message = 'Методист формирует материалы…',
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<ThinkingStep> _steps;
  late int _targetSeconds;
  late String _expectedTimeRange;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initStepsAndTiming();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _initStepsAndTiming() {
    final hasConspect = widget.materials == null ||
        widget.materials!.isEmpty ||
        widget.materials!.contains(GenerationType.conspect);
    final hasWorksheet = widget.materials == null ||
        widget.materials!.isEmpty ||
        widget.materials!.contains(GenerationType.worksheet);
    final hasHomework = widget.materials == null ||
        widget.materials!.isEmpty ||
        widget.materials!.contains(GenerationType.homework);

    if (hasConspect && hasWorksheet && hasHomework) {
      // Полный комплект из 3 материалов
      _targetSeconds = 80;
      _expectedTimeRange = '~60–90 сек';
      _steps = const [
        ThinkingStep(
          title: 'Конспект занятия',
          desc: 'Цели, триединые задачи, пошаговый тайминг и реплики педагога',
          icon: Icons.article_rounded,
          color: Color(0xFF6366F1),
        ),
        ThinkingStep(
          title: 'Рабочий лист (3 уровня)',
          desc: 'Дидактические поля, эталоны решений и косая линовка 65°',
          icon: Icons.assignment_rounded,
          color: Color(0xFF06B6D4),
        ),
        ThinkingStep(
          title: 'Домашняя работа',
          desc: 'Закрепляющие упражнения и наглядная памятка для ученика',
          icon: Icons.home_work_rounded,
          color: Color(0xFF10B981),
        ),
        ThinkingStep(
          title: 'Подсказка родителям & Аудит',
          desc: '30-секундный аудио-скрипт и строгая проверка по нормам ФГОС',
          icon: Icons.verified_rounded,
          color: Color(0xFFA855F7),
        ),
      ];
    } else if (hasConspect && hasWorksheet) {
      // Конспект + Рабочий лист
      _targetSeconds = 55;
      _expectedTimeRange = '~45–60 сек';
      _steps = const [
        ThinkingStep(
          title: 'Поурочный сценарий',
          desc: 'Цели, драматургия урока, проблемные ситуации и методические указания',
          icon: Icons.timeline_rounded,
          color: Color(0xFF6366F1),
        ),
        ThinkingStep(
          title: 'Рабочий лист: Уровень 1 (Старт)',
          desc: 'Базовые упражнения, наглядный образец и косая линовка 65°',
          icon: Icons.looks_one_rounded,
          color: Color(0xFF06B6D4),
        ),
        ThinkingStep(
          title: 'Рабочий лист: Уровни 2 и 3',
          desc: 'Практикум, ловушки Незнайки, схемы и таблицы для распределения',
          icon: Icons.looks_3_rounded,
          color: Color(0xFF10B981),
        ),
        ThinkingStep(
          title: 'Методический аудит логики',
          desc: 'Проверка отсутствия дублей полей и соответствия программе',
          icon: Icons.verified_user_rounded,
          color: Color(0xFFA855F7),
        ),
      ];
    } else if (hasWorksheet) {
      // Только Рабочий лист
      _targetSeconds = 45;
      _expectedTimeRange = '~35–50 сек';
      _steps = const [
        ThinkingStep(
          title: 'Анализ темы и методики',
          desc: 'Определение ключевых понятий и правил для отработки',
          icon: Icons.psychology_rounded,
          color: Color(0xFF6366F1),
        ),
        ThinkingStep(
          title: 'Генерация упражнений',
          desc: '3 уровня сложности от репродуктивного к творческому поиску',
          icon: Icons.assignment_rounded,
          color: Color(0xFF06B6D4),
        ),
        ThinkingStep(
          title: 'Дидактические поля',
          desc: 'Каллиграфическая сетка 65°, таблицы и боксы для ответов',
          icon: Icons.grid_on_rounded,
          color: Color(0xFF10B981),
        ),
        ThinkingStep(
          title: 'Финальная верификация',
          desc: 'Проверка ключей решений и читаемости материалов для печати',
          icon: Icons.check_circle_outline_rounded,
          color: Color(0xFFA855F7),
        ),
      ];
    } else if (hasHomework) {
      // Только Домашняя работа
      _targetSeconds = 35;
      _expectedTimeRange = '~25–40 сек';
      _steps = const [
        ThinkingStep(
          title: 'Отбор учебных задач',
          desc: 'Фокус на ключевых навыках для домашнего закрепления',
          icon: Icons.home_work_rounded,
          color: Color(0xFF6366F1),
        ),
        ThinkingStep(
          title: 'Дифференцированные задания',
          desc: 'Задания уровней Старт, Практик и Про для самостоятельной работы',
          icon: Icons.tune_rounded,
          color: Color(0xFF06B6D4),
        ),
        ThinkingStep(
          title: 'Памятка для ученика',
          desc: 'Краткий опорный конспект с правилом и разобранным примером',
          icon: Icons.sticky_note_2_rounded,
          color: Color(0xFF10B981),
        ),
        ThinkingStep(
          title: 'Подсказка для родителей',
          desc: 'Текст аудио-заготовки с простым объяснением сути урока',
          icon: Icons.record_voice_over_rounded,
          color: Color(0xFFA855F7),
        ),
      ];
    } else {
      // Только Конспект
      _targetSeconds = 40;
      _expectedTimeRange = '~30–45 сек';
      _steps = const [
        ThinkingStep(
          title: 'Цель и триединые задачи',
          desc: 'Обучающие, развивающие и воспитательные результаты урока',
          icon: Icons.flag_rounded,
          color: Color(0xFF6366F1),
        ),
        ThinkingStep(
          title: 'Материалы и наглядность',
          desc: 'Спецификация раздаточных пособий и опорных схем по методике',
          icon: Icons.auto_stories_rounded,
          color: Color(0xFF06B6D4),
        ),
        ThinkingStep(
          title: 'Ход занятия и драматургия',
          desc: 'Пошаговый сценарий, тайминг и живые диалоги учителя с классом',
          icon: Icons.schema_rounded,
          color: Color(0xFF10B981),
        ),
        ThinkingStep(
          title: 'Дифференциация и рефлексия',
          desc: 'Адаптация упражнений («проще» и «сложнее») и подведение итогов',
          icon: Icons.tune_rounded,
          color: Color(0xFFA855F7),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int _getActiveStepIndex() {
    if (_steps.isEmpty) return 0;
    final total = _steps.length;
    // Порог перехода между шагами (0..total-1)
    final stepDuration = _targetSeconds / total;
    final calculated = (_elapsedSeconds / stepDuration).floor();
    return calculated.clamp(0, total - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeIndex = _getActiveStepIndex();
    final activeStep = _steps[activeIndex];

    // Форматирование времени: mm:ss
    final minutes = (_elapsedSeconds ~/ 60).toString();
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');

    // Прогресс с асимптотическим замедлением, чтобы полоса никогда не застревала на 100% до ответа сервера
    final progress = (_elapsedSeconds / (_targetSeconds * 1.25)).clamp(0.06, 0.94);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          borderRadius: AppRadii.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Верхний бейдж
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanBlue,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'MetodistPRO генерирует поурочный план',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Честный динамический таймер
              Text(
                'Формирую материалы • $minutes:$seconds',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ожидание: $_expectedTimeRange • Лимит до 4 мин с запасом',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Карточки этапов с честным отображением прогресса
              Column(
                children: List.generate(_steps.length, (index) {
                  final step = _steps[index];
                  final isCompleted = index < activeIndex;
                  final isActive = index == activeIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(isCompleted ? 0.05 : (isActive ? 0.09 : 0.02))
                          : Colors.white.withOpacity(isCompleted ? 0.65 : (isActive ? 0.95 : 0.35)),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isActive
                            ? step.color.withOpacity(0.8)
                            : (isCompleted
                                ? AppColors.success.withOpacity(0.6)
                                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                        width: isActive ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Icon(
                            step.icon,
                            size: 17,
                            color: step.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? step.color
                                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: step.color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ГЕНЕРИРУЕТСЯ',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: step.color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.desc,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          )
                        else if (isActive)
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(step.color),
                            ),
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 6),

              // Индикатор текущей фазы
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: activeStep.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Сейчас создается: ${activeStep.title}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Плавный честный прогресс-бар внизу
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: progress,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(activeStep.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
