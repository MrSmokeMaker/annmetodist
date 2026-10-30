import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/conspect.dart';
import '../models/lesson_stage.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';

class LessonRunScreen extends StatefulWidget {
  final Conspect conspect;

  const LessonRunScreen({
    super.key,
    required this.conspect,
  });

  @override
  State<LessonRunScreen> createState() => _LessonRunScreenState();
}

class _LessonRunScreenState extends State<LessonRunScreen> {
  late List<LessonStage> _stages;
  int _currentStageIndex = 0;

  Timer? _stageTimer;
  late int _remainingSeconds;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _stages = LessonStage.parseFromConspect(
      widget.conspect.content,
      widget.conspect.duration,
    );

    _initStageTimer();
  }

  void _initStageTimer() {
    _stageTimer?.cancel();
    if (_stages.isNotEmpty && _currentStageIndex < _stages.length) {
      _remainingSeconds = _stages[_currentStageIndex].durationSeconds;
      if (_isRunning) {
        _startTimer();
      }
    } else {
      _remainingSeconds = 0;
    }
  }

  void _startTimer() {
    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _pauseTimer();
      }
    });
  }

  void _pauseTimer() {
    _stageTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _startTimer();
  }

  void _togglePlayPause() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  void _nextStage() {
    if (_currentStageIndex < _stages.length - 1) {
      setState(() {
        _currentStageIndex++;
      });
      _initStageTimer();
    } else {
      _showCompletionDialog();
    }
  }

  void _prevStage() {
    if (_currentStageIndex > 0) {
      setState(() {
        _currentStageIndex--;
      });
      _initStageTimer();
    }
  }

  void _repeatStage() {
    setState(() {
      _remainingSeconds = _stages[_currentStageIndex].durationSeconds;
    });
    if (!_isRunning) {
      _resumeTimer();
    }
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _pauseTimer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber, size: 28),
            SizedBox(width: 10),
            Text('Урок успешно завершён!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          'Вы провели все запланированные этапы урока по теме «${widget.conspect.title}». Занятие прошло по плану!',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Вернуться к материалам', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSec) {
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStage = _stages.isNotEmpty
        ? _stages[_currentStageIndex]
        : LessonStage(
            stageNumber: 1,
            title: 'Урок',
            durationMinutes: 45,
            content: '',
          );
    final stageTotalSec = currentStage.durationSeconds;
    final double stageProgress = stageTotalSec > 0
        ? (1.0 - (_remainingSeconds / stageTotalSec)).clamp(0.0, 1.0)
        : 1.0;
    final double overallProgress = _stages.isNotEmpty ? (_currentStageIndex + 1) / _stages.length : 1.0;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): _togglePlayPause,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _nextStage,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevStage,
        const SingleActivator(LogicalKeyboardKey.keyR): _repeatStage,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Выйти из режима ведения',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Presenter Mode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cyan),
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.conspect.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Сбросить таймер этапа (R)',
                icon: const Icon(Icons.replay_rounded, size: 20),
                onPressed: _repeatStage,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: AmbientBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xs),

                        // 1. Верхний бар прогресса занятия
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          borderRadius: AppRadii.lg,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined, size: 16, color: AppColors.primaryIndigo),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Этап ${_currentStageIndex + 1} из ${_stages.length}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(overallProgress * 100).toInt()}% пройдено',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: overallProgress,
                                  minHeight: 6,
                                  backgroundColor: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.06),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // 2. Таймер текущего этапа и управление
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          borderRadius: AppRadii.xl,
                          child: Row(
                            children: [
                              // Glowing Circular Timer Ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: stageProgress,
                                      strokeWidth: 6,
                                      backgroundColor: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.06),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _remainingSeconds == 0
                                            ? AppColors.error
                                            : (_isRunning ? AppColors.cyan : AppColors.accentAmber),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTimer(_remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: _remainingSeconds == 0 ? AppColors.error : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 18),

                              // Stage Title & Remaining Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentStage.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'План: ${currentStage.durationMinutes} мин • ${_remainingSeconds > 0 ? "Идёт отсчёт" : "Время этапа вышло"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _remainingSeconds == 0
                                                ? AppColors.error
                                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Play / Pause Toggle Button
                              InkWell(
                                onTap: _togglePlayPause,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: _isRunning ? AppGradients.cyanBlue : AppGradients.amberOrange,
                                    shape: BoxShape.circle,
                                    boxShadow: _isRunning ? AppShadows.glowCyan : AppShadows.glowAmber,
                                  ),
                                  child: Icon(
                                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // 3. Главный контент этапа (крупная удобочитаемая карточка)
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final slideIn = Tween<Offset>(
                                begin: const Offset(0.04, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideIn,
                                  child: child,
                                ),
                              );
                            },
                            child: GlassCard(
                              key: ValueKey<int>(_currentStageIndex),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              borderRadius: AppRadii.xl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.indigoViolet,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ЭТАП ${_currentStageIndex + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          currentStage.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                    height: 1,
                                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: MarkdownBody(
                                        data: currentStage.content.isNotEmpty
                                            ? currentStage.content
                                            : 'Проведите запланированные активности этапа «${currentStage.title}» согласно сценарию урока.',
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            fontSize: 16.5, // Увеличенный шрифт для удобного чтения у доски
                                            height: 1.6,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                          strong: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          listBullet: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.cyan,
                                          ),
                                          h2: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                          h3: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 4. Нижняя плавающая панель навигации
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Row(
                            children: [
                              if (_currentStageIndex > 0)
                                Expanded(
                                  flex: 1,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadii.md),
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                    label: const Text('Назад (←)', style: TextStyle(fontWeight: FontWeight.w600)),
                                    onPressed: _prevStage,
                                  ),
                                ),
                              if (_currentStageIndex > 0) const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: _nextStage,
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.indigoViolet,
                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                      boxShadow: AppShadows.glowPrimary,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _currentStageIndex < _stages.length - 1
                                              ? 'Следующий этап (→)'
                                              : 'Завершить урок (✓)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _currentStageIndex < _stages.length - 1
                                              ? Icons.arrow_forward_rounded
                                              : Icons.check_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
