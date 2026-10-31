import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_story.dart';
import '../theme.dart';
import 'stories_player_modal.dart';

class StoriesTrayWidget extends StatefulWidget {
  final VoidCallback? onStoryClosed;

  const StoriesTrayWidget({
    super.key,
    this.onStoryClosed,
  });

  @override
  State<StoriesTrayWidget> createState() => _StoriesTrayWidgetState();
}

class _StoriesTrayWidgetState extends State<StoriesTrayWidget> {
  late List<AppStoryGroup> _stories;
  Set<String> _viewedStoryIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stories = AppStoriesData.getSampleStories();
    _loadViewedState();
  }

  Future<void> _loadViewedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('viewed_stories_ids') ?? [];
      _viewedStoryIds = list.toSet();
      for (final s in _stories) {
        if (_viewedStoryIds.contains(s.id)) {
          s.isViewed = true;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markStoryAsViewed(String storyId) async {
    setState(() {
      _viewedStoryIds.add(storyId);
      final story = _stories.firstWhere((s) => s.id == storyId, orElse: () => _stories.first);
      story.isViewed = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('viewed_stories_ids', _viewedStoryIds.toList());
    } catch (_) {}
  }

  void _openStory(int index) {
    _markStoryAsViewed(_stories[index].id);
    StoriesPlayerModal.show(
      context,
      stories: _stories,
      initialGroupIndex: index,
      onStoryChanged: (newIndex) {
        if (newIndex >= 0 && newIndex < _stories.length) {
          _markStoryAsViewed(_stories[newIndex].id);
        }
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
      widget.onStoryClosed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = _stories[index];
          final isViewed = story.isViewed;

          return _StoryAvatarItem(
            story: story,
            isViewed: isViewed,
            isDark: isDark,
            onTap: () => _openStory(index),
          );
        },
      ),
    );
  }
}

class _StoryAvatarItem extends StatefulWidget {
  final AppStoryGroup story;
  final bool isViewed;
  final bool isDark;
  final VoidCallback onTap;

  const _StoryAvatarItem({
    required this.story,
    required this.isViewed,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StoryAvatarItem> createState() => _StoryAvatarItemState();
}

class _StoryAvatarItemState extends State<_StoryAvatarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isViewed = widget.isViewed;
    final ringColors = isViewed
        ? [
            widget.isDark ? Colors.white24 : Colors.black26,
            widget.isDark ? Colors.white12 : Colors.black12,
          ]
        : widget.story.ringColors;

    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outer Instagram Ring
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: ringColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: isViewed
                      ? null
                      : [
                          BoxShadow(
                            color: ringColors.first.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.story.slides.first.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.story.avatarEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // Title label under avatar
              Text(
                widget.story.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isViewed ? FontWeight.w500 : FontWeight.w700,
                  color: isViewed
                      ? (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                      : (widget.isDark ? Colors.white : AppColors.textPrimaryLight),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
