import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../models/topic.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import 'conspect_view_screen.dart';
import 'settings_screen.dart';

import 'new_conspect_screen.dart';
import '../screens/worksheet_screen.dart';
import '../screens/homework_screen.dart';
import '../widgets/generation_type_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGenerationTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GenerationTypeSheet(),
    );
  }

  List<Conspect> _filterConspects(List<Conspect> conspects) {
    if (_searchQuery.trim().isEmpty) return conspects;
    final query = _searchQuery.toLowerCase().trim();

    return conspects.where((c) {
      final titleMatch = c.title.toLowerCase().contains(query);
      final methodMatch = c.methodName.toLowerCase().contains(query);
      final subjectMatch = c.subject.toLowerCase().contains(query);
      final dateMatch = DateFormat('dd.MM.yyyy').format(c.createdAt).contains(query);
      return titleMatch || methodMatch || subjectMatch || dateMatch;
    }).toList();
  }

  Future<bool?> _confirmDelete(BuildContext context, Conspect conspect) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text('Удалить конспект?'),
        content: Text(
          'Вы действительно хотите удалить конспект по теме «${conspect.title}»? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = _filterConspects(provider.conspects);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Settings Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Методист',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Генератор конспектов занятий',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Настройки',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_outlined, size: 22),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          FadeSlidePageRoute(page: const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Action Card: "Новый конспект"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  borderRadius: AppRadii.lg,
                    onTap: () => _showGenerationTypeSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.indigoViolet,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryIndigo.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Новый конспект',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Выбрать методику, тему и сгенерировать',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Quick Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionBtn(
                        context: context,
                        icon: Icons.menu_book_rounded,
                        label: 'Конспект',
                        color: AppColors.primaryIndigo,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          FadeSlidePageRoute(page: const NewConspectScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionBtn(
                        context: context,
                        icon: Icons.description_rounded,
                        label: 'Раб. лист',
                        color: AppColors.cyan,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          FadeSlidePageRoute(page: const WorksheetScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionBtn(
                        context: context,
                        icon: Icons.assignment_turned_in_rounded,
                        label: 'Домашка',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          FadeSlidePageRoute(page: const HomeworkScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Мини-дашборд или компактный онбординг (Скрываем/сворачиваем при 0)
              if (provider.hasStatistics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      // Карточка 1: Сегодня
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          borderRadius: AppRadii.md,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.today_rounded, size: 14, color: AppColors.cyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Сегодня',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.todayConspectsCount}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'уроков',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Карточка 2: Методик (в базе)
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          borderRadius: AppRadii.md,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_stories_rounded, size: 14, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Методик',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.methods.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'в базе',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Карточка 3: Средняя длительность
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          borderRadius: AppRadii.md,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ср. время',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.averageDurationDisplay,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'на урок',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Компактный блок онбординга вместо пустой статистики
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    borderRadius: AppRadii.md,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded, size: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Выберите методику и создайте первый конспект занятия',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              // Недавние сгенерированные PDF (Лист заданий / Домашнее задание)
              if (provider.recentPdfs.isNotEmpty)
                _buildRecentPdfsSection(context, provider, isDark),

              // Унифицированный переключатель «Возрастная группа»
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: AppRadii.md,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 16,
                            color: provider.selectedAgeGroup == 'preschool' ? AppColors.cyan : AppColors.primaryIndigo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Возрастная группа',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAgeGroupTab(
                              title: 'Дошкольники',
                              isSelected: provider.selectedAgeGroup == 'preschool',
                              onTap: () => provider.setSelectedAgeGroup('preschool'),
                              isDark: isDark,
                            ),
                            _buildAgeGroupTab(
                              title: '1 класс',
                              isSelected: provider.selectedAgeGroup == 'grade_1',
                              onTap: () => provider.setSelectedAgeGroup('grade_1'),
                              isDark: isDark,
                            ),
                            _buildAgeGroupTab(
                              title: '2 класс',
                              isSelected: provider.selectedAgeGroup == 'grade_2',
                              onTap: () => provider.setSelectedAgeGroup('grade_2'),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: AppRadii.md,
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Поиск по теме, методике или дате...',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Library Section Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сохранённые конспекты',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${filteredList.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
              ),

              // Conspects List (Staggered animation)
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (dir) => _confirmDelete(context, item),
                              onDismissed: (dir) {
                                provider.deleteConspect(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Конспект «${item.title}» удалён.'),
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(AppRadii.lg),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Удалить',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.delete_outline, color: Colors.white),
                                  ],
                                ),
                              ),
                              child: GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                borderRadius: AppRadii.lg,
                                onTap: () {
                                  Navigator.of(context).push(
                                    FadeSlidePageRoute(
                                      page: ConspectViewScreen(
                                        existingConspect: item,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd.MM.yy').format(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.textMutedDark
                                                : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: AppGradients.indigoViolet,
                                            borderRadius:
                                                BorderRadius.circular(AppRadii.sm),
                                          ),
                                          child: Text(
                                            item.methodName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.08)
                                                : Colors.black.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(AppRadii.sm),
                                          ),
                                          child: Text(
                                            item.subject,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.08)
                                                : Colors.black.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(AppRadii.sm),
                                          ),
                                          child: Text(
                                            '${Topic.getAgeGroupLabel(item.ageGroup)} • ${item.duration}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                duration: 250.ms,
                                delay: (index * 50).ms, // Staggered 50ms delay
                              )
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 250.ms,
                                curve: Curves.easeOutCubic,
                              );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: 'Перейти к созданию: $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarterTemplateCard({
    required String title,
    required String subject,
    required String method,
    required String ageGroup,
    required String ageGroupId,
    required String methodId,
    required String duration,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.md,
      onTap: () {
        Navigator.of(context).push(
          FadeSlidePageRoute(
            page: NewConspectScreen(
              initialTopic: title,
              initialAgeGroup: ageGroupId,
              initialMethodId: methodId,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $ageGroup • $duration',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl * 1.5,
            ),
            borderRadius: AppRadii.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 52,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ничего не найдено',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Попробуйте изменить поисковый запрос.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            borderRadius: AppRadii.lg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.indigoViolet,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Быстрый старт с готовых образцов',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Выберите готовый шаблон для мгновенного создания:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStarterTemplateCard(
            title: 'Счёт предметов до 10: Сказка о цифрах',
            subject: 'Математика',
            method: 'Методика Пчелко и Поляка',
            ageGroup: '1 класс',
            ageGroupId: 'grade_1',
            methodId: 'pchelko_math',
            duration: '45 мин',
            icon: Icons.calculate_rounded,
            color: AppColors.cyan,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildStarterTemplateCard(
            title: 'Первый слог и звучащее слово',
            subject: 'Обучение чтению',
            method: 'Метод Редозубова',
            ageGroup: 'Дошкольники',
            ageGroupId: 'preschool',
            methodId: 'redozubov_reading',
            duration: '20 мин',
            icon: Icons.menu_book_rounded,
            color: AppColors.primaryIndigo,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildStarterTemplateCard(
            title: 'Красивая строчка и базовые элементы букв',
            subject: 'Чистописание',
            method: 'Нейро-подход Мазиной',
            ageGroup: '1 класс',
            ageGroupId: 'grade_1',
            methodId: 'mazina_penmanship',
            duration: '30 мин',
            icon: Icons.draw_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildAgeGroupTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.indigoViolet : null,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPdfsSection(BuildContext context, AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 15,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Недавние PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Text(
                '${provider.recentPdfs.length}/3',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...provider.recentPdfs.map((pdf) {
            final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(pdf.createdAt);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: AppRadii.md,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFFE11D48),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pdf.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 3),
                          Text(
                            'Скачан',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
