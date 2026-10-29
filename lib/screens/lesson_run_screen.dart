import 'dart:async';
import 'package:flutter/material.dart';
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
        // Когда время этапа истекло — авто-пауза или звуковой отклик
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
    _pauseTimer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E222D)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 10),
            Text('Урок завершён!'),
          ],
        ),
        content: Text(
          'Вы успешно провели занятие по теме «${widget.conspect.title}». Не забудьте отметить обратную связь!',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Возврат к конспекту
            },
            child: const Text('Вернуться к конспекту'),
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
    final currentStage = _stages[_currentStageIndex];
    final stageTotalSec = currentStage.durationSeconds;
    final double stageProgress = stageTotalSec > 0
        ? (1.0 - (_remainingSeconds / stageTotalSec)).clamp(0.0, 1.0)
        : 1.0;
    final double overallProgress = (_currentStageIndex + 1) / _stages.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вести урок',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
            tooltip: 'Повторить текущий этап',
            icon: const Icon(Icons.replay_rounded),
            onPressed: _repeatStage,
          ),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Верхняя панель: Общий прогресс урока и текущий этап
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Этап ${_currentStageIndex + 1} из ${_stages.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan,
                            ),
                          ),
                          Text(
                            '${(overallProgress * 100).toInt()}% пройдено',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Карточка таймера этапа
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Круговой индикатор с таймером
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: stageProgress,
                              strokeWidth: 5,
                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remainingSeconds == 0
                                    ? AppColors.error
                                    : AppColors.primaryIndigo,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimer(_remainingSeconds),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Название этапа
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStage.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'План: ${currentStage.durationMinutes} мин | ${_remainingSeconds > 0 ? "Осталось" : "Время истекло"}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _remainingSeconds == 0
                                    ? AppColors.error
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Кнопка Пауза / Плей
                      InkWell(
                        onTap: _togglePlayPause,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: _isRunning ? AppGradients.cyanBlue : AppGradients.amberOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Основной контент этапа с анимацией fade + slide
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final slideIn = Tween<Offset>(
                        begin: const Offset(0.06, 0.0),
                        end: Offset.zero,
                      ).animate(animation);

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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      borderRadius: AppRadii.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryIndigo.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Text(
                                  'Этап ${_currentStageIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryIndigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentStage.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: MarkdownBody(
                                data: currentStage.content.isNotEmpty
                                    ? currentStage.content
                                    : 'Выполните задания этапа «${currentStage.title}» согласно общему сценарию занятия.',
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    fontSize: 15.5,
                                    height: 1.6,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  strong: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  listBullet: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.cyan,
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
              ),

              // 4. Нижняя панель навигации по этапам
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.md),
                child: Row(
                  children: [
                    if (_currentStageIndex > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Назад'),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStageIndex < _stages.length - 1
                                    ? 'Следующий этап'
                                    : 'Завершить урок',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
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
    );
  }
}
