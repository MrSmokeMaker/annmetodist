import 'package:flutter/material.dart';
import '../theme.dart';
import 'glass_card.dart';

class ThinkingIndicator extends StatefulWidget {
  final String message;

  const ThinkingIndicator({
    super.key,
    this.message = 'Методист собирает конспект…',
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Цель и задачи',
      'desc': 'Формулируем обучающие, развивающие и воспитательные цели',
      'icon': Icons.flag_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Материалы и пособия',
      'desc': 'Подбираем раздаточные карточки и наглядный ряд по методике',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xFF06B6D4),
    },
    {
      'title': 'Ход занятия',
      'desc': 'Выстраиваем пошаговый сценарий, тайминг и реплики учителя',
      'icon': Icons.schema_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Дифференциация',
      'desc': 'Адаптируем упражнения: вариант "проще" и вариант "сложнее"',
      'icon': Icons.tune_rounded,
      'color': const Color(0xFFA855F7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: AppColors.cyan.withValues(alpha: 0.3),
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
                      'YandexGPT генерирует поурочный план',
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

              Text(
                'Собираю конспект, ~30 сек',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Формируем цели, этапы, приёмы и методические указания',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Шаг 5: Staggered-анимация появления карточек сборки
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    children: List.generate(_steps.length, (index) {
                      final step = _steps[index];
                      // Интервалы для каждой карточки: [0.0..0.25], [0.25..0.5], [0.5..0.75], [0.75..1.0]
                      final startInterval = (index * 0.22).clamp(0.0, 1.0);
                      final endInterval = (startInterval + 0.28).clamp(0.0, 1.0);

                      final curve = CurvedAnimation(
                        parent: _controller,
                        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
                      );

                      final isCompleted = _controller.value >= endInterval;
                      final isActive = _controller.value >= startInterval && !isCompleted;

                      return Opacity(
                        opacity: curve.value,
                        child: Transform.translate(
                          offset: Offset(0, (1.0 - curve.value) * 16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(isCompleted ? 0.06 : (isActive ? 0.08 : 0.03))
                                  : Colors.white.withOpacity(isCompleted ? 0.7 : (isActive ? 0.9 : 0.4)),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: isActive
                                    ? (step['color'] as Color).withOpacity(0.6)
                                    : (isCompleted
                                        ? AppColors.success.withOpacity(0.5)
                                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                                width: isActive ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: (step['color'] as Color).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(AppRadii.sm),
                                  ),
                                  child: Icon(
                                    step['icon'] as IconData,
                                    size: 17,
                                    color: step['color'] as Color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        step['desc'] as String,
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
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
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
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // Бегущий прогресс-бар внизу
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
