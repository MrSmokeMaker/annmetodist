import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/app_story.dart';
import '../theme.dart';
import 'telegram_bots_sheet.dart';
import 'app_news_modal.dart';
import '../screens/methodology_architect_screen.dart';

class StoriesPlayerModal extends StatefulWidget {
  final List<AppStoryGroup> stories;
  final int initialGroupIndex;
  final ValueChanged<int>? onStoryChanged;

  const StoriesPlayerModal({
    super.key,
    required this.stories,
    this.initialGroupIndex = 0,
    this.onStoryChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AppStoryGroup> stories,
    int initialGroupIndex = 0,
    ValueChanged<int>? onStoryChanged,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StoriesPlayer',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) {
        return StoriesPlayerModal(
          stories: stories,
          initialGroupIndex: initialGroupIndex,
          onStoryChanged: onStoryChanged,
        );
      },
    );
  }

  @override
  State<StoriesPlayerModal> createState() => _StoriesPlayerModalState();
}

class _StoriesPlayerModalState extends State<StoriesPlayerModal>
    with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  late int _currentSlideIndex;
  late AnimationController _progressController;

  static const Duration _slideDuration = Duration(milliseconds: 5500);

  AppStoryGroup get _currentGroup => widget.stories[_currentGroupIndex];
  AppStorySlide get _currentSlide => _currentGroup.slides[_currentSlideIndex];

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex.clamp(0, widget.stories.length - 1);
    _currentSlideIndex = 0;

    _progressController = AnimationController(
      vsync: this,
      duration: _slideDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNextSlide();
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onNextSlide() {
    if (_currentSlideIndex < _currentGroup.slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // Переход к следующей группе историй
      if (_currentGroupIndex < widget.stories.length - 1) {
        setState(() {
          _currentGroupIndex++;
          _currentSlideIndex = 0;
        });
        widget.onStoryChanged?.call(_currentGroupIndex);
        _progressController.reset();
        _progressController.forward();
      } else {
        // Все истории просмотрены — закрываем плеер
        Navigator.of(context).pop();
      }
    }
  }

  void _onPrevSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // Переход к предыдущей группе историй
      if (_currentGroupIndex > 0) {
        setState(() {
          _currentGroupIndex--;
          _currentSlideIndex = widget.stories[_currentGroupIndex].slides.length - 1;
        });
        widget.onStoryChanged?.call(_currentGroupIndex);
        _progressController.reset();
        _progressController.forward();
      } else {
        // Перезапускаем текущий первый слайд
        _progressController.reset();
        _progressController.forward();
      }
    }
  }

  void _pause() {
    _progressController.stop();
  }

  void _resume() {
    _progressController.forward();
  }

  void _handleCtaAction(BuildContext context, StoryActionType action) {
    Navigator.of(context).pop(); // Закрываем плеер

    switch (action) {
      case StoryActionType.openGenerator:
        // Пользователь переходит к генерации на главном экране
        break;
      case StoryActionType.openThematicWorlds:
        // Открытие информации о мирах
        AppNewsModal.show(context);
        break;
      case StoryActionType.openBotsSheet:
        TelegramBotsSheet.show(context);
        break;
      case StoryActionType.openNews:
        AppNewsModal.show(context);
        break;
      case StoryActionType.openSettings:
      case StoryActionType.openTemplates:
        break;
      case StoryActionType.openDirector:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MethodologyArchitectScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 700;

    final content = Material(
      color: Colors.transparent,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentSlide.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: isDesktop ? BorderRadius.circular(28) : BorderRadius.zero,
            boxShadow: isDesktop
                ? [
                    BoxShadow(
                      color: _currentSlide.gradientColors.first.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Фоновые светящиеся круги в стиле Apple/Instagram
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),

              // Интерактивные зоны тапа (Слева: назад, Справа: вперед, Удержание: пауза)
              Positioned.fill(
                child: Row(
                  children: [
                    // Левая треть: назад
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _pause(),
                        onTapUp: (_) {
                          _resume();
                          _onPrevSlide();
                        },
                        onTapCancel: () => _resume(),
                        onLongPressStart: (_) => _pause(),
                        onLongPressEnd: (_) => _resume(),
                      ),
                    ),
                    // Правые две трети: вперед
                    Expanded(
                      flex: 65,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _pause(),
                        onTapUp: (_) {
                          _resume();
                          _onNextSlide();
                        },
                        onTapCancel: () => _resume(),
                        onLongPressStart: (_) => _pause(),
                        onLongPressEnd: (_) => _resume(),
                      ),
                    ),
                  ],
                ),
              ),

              // Контент слайда (кнопки поверх зон тапа)
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 1. Сегментированный индикатор прогресса (Progress bars)
                    _buildProgressBars(),

                    const SizedBox(height: 12),

                    // 2. Шапка автора (Аватар, Имя, Бейдж и крестик)
                    _buildAuthorHeader(),

                    // 3. Центральное тело слайда
                    Expanded(
                      child: _buildSlideBody(),
                    ),

                    // 4. Нижняя кнопка действия (CTA)
                    _buildCtaButton(context),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: content,
      );
    }

    // Десктопное отображение: фрейм смартфона по центру с размытым фоном
    return Center(
      child: Container(
        width: 410,
        height: 740,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.92,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.5,
          ),
        ),
        child: content,
      ),
    );
  }

  // Сегментированный прогресс-бар вверху
  Widget _buildProgressBars() {
    final slidesCount = _currentGroup.slides.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: List.generate(slidesCount, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == slidesCount - 1 ? 0 : 4),
              height: 2.8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  double factor = 0.0;
                  if (index < _currentSlideIndex) {
                    factor = 1.0;
                  } else if (index == _currentSlideIndex) {
                    factor = _progressController.value;
                  }

                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: factor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  // Шапка автора
  Widget _buildAuthorHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Аватарка кружка
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _currentGroup.ringColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _currentGroup.avatarEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Имя и бейдж
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentGroup.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_currentSlideIndex + 1}/${_currentGroup.slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _currentGroup.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Кнопка закрытия (X)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Центральный контент слайда
  Widget _buildSlideBody() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Верхний бейдж
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Text(
                _currentSlide.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Центральный эмодзи/маскот
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _currentSlide.iconEmoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Заголовок
            Text(
              _currentSlide.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // 4. Подзаголовок
            Text(
              _currentSlide.subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            // 5. Описание
            Text(
              _currentSlide.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 12.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 6. Тезисы / Буллеты
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentSlide.bulletPoints.map((bp) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bp,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Кнопка действия (CTA) внизу
  Widget _buildCtaButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => _handleCtaAction(context, _currentSlide.ctaAction),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentSlide.ctaLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
