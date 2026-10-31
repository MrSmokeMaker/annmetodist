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
import 'lesson_run_screen.dart';
import 'settings_screen.dart';
import 'new_conspect_screen.dart';
import '../screens/worksheet_screen.dart';
import '../screens/homework_screen.dart';
import '../widgets/generation_type_sheet.dart';
import '../widgets/app_news_modal.dart';
import '../widgets/what_can_ai_do_widget.dart';
import '../widgets/telegram_bots_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubjectFilter = 'all';

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
    var list = conspects;
    if (_selectedSubjectFilter != 'all') {
      list = list.where((c) => c.subject.toLowerCase().contains(_selectedSubjectFilter.toLowerCase())).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.toLowerCase().trim();

    return list.where((c) {
      final titleMatch = c.title.toLowerCase().contains(query);
      final methodMatch = c.methodName.toLowerCase().contains(query);
      final subjectMatch = c.subject.toLowerCase().contains(query);
      final dateMatch = DateFormat('dd.MM.yyyy').format(c.createdAt).contains(query);
      return titleMatch || methodMatch || subjectMatch || dateMatch;
    }).toList();
  }

  Future<bool?> _confirmDelete(BuildContext context, Conspect conspect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text('Удалить конспект?'),
        content: Text(
          'Вы действительно хотите удалить конспект «${conspect.title}»? Это действие нельзя отменить.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final filteredList = _filterConspects(provider.conspects);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: isDesktop
                  ? _buildDesktopLayout(context, provider, filteredList, isDark)
                  : _buildMobileLayout(context, provider, filteredList, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppProvider provider,
    List<Conspect> filteredList,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Feed: Header, Bento Actions, Conspects List
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),
                const SizedBox(height: AppSpacing.md),
                _buildBentoHero(context, isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildSearchBar(isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildSubjectFilterBar(isDark),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: filteredList.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildConspectsList(context, provider, filteredList, isDark),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xl),

          // Right Sidebar: Metrics, Age Switcher, Recent PDFs, Quick Templates
          Expanded(
            flex: 35,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const WhatCanAiDoWidget(isCompact: false),
                  const SizedBox(height: AppSpacing.md),
                  _buildAnalyticsMetrics(provider, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildAgeGroupSelector(provider, isDark),
                  const SizedBox(height: AppSpacing.md),
                  if (provider.recentPdfs.isNotEmpty) ...[
                    _buildRecentPdfsSection(context, provider, isDark),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _buildStarterTemplatesSection(context, isDark),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppProvider provider,
    List<Conspect> filteredList,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBentoHero(context, isDark),
                      const SizedBox(height: AppSpacing.md),
                      const WhatCanAiDoWidget(isCompact: true),
                      const SizedBox(height: AppSpacing.md),
                      _buildAnalyticsMetrics(provider, isDark),
                      const SizedBox(height: AppSpacing.md),
                      _buildAgeGroupSelector(provider, isDark),
                      if (provider.recentPdfs.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildRecentPdfsSection(context, provider, isDark),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _buildSearchBar(isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSubjectFilterBar(isDark),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Сохранённые уроки',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filteredList.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
              if (filteredList.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(isDark))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    90, // Room for mobile bottom bar
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredList[index];
                        return _buildConspectCard(context, provider, item, index, isDark);
                      },
                      childCount: filteredList.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppGradients.indigoViolet,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.glowPrimary,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Методист',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppGradients.cyanBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Умный генератор уроков и материалов',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              TelegramBotsMenuButton(isCompact: !isDesktop),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Что нового (Новости приложения)',
                icon: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.accentCyan,
                  ),
                ),
                onPressed: () => AppNewsModal.show(context),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Настройки',
                icon: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(FadeSlidePageRoute(page: const SettingsScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Linear / Apple Bento Hero Grid
  Widget _buildBentoHero(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Main Primary Card: Conspect
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadii.xl,
          onTap: () => _showGenerationTypeSheet(context),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.indigoViolet,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.glowPrimary,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Сгенерировать урок',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryIndigo.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ФГОС',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryIndigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Конспект, карточки, интерактив и план занятия за секунды',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark ? Colors.white : AppColors.primaryIndigo,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Sub Actions: Worksheets & Homework
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: AppRadii.lg,
                onTap: () => Navigator.of(context).push(FadeSlidePageRoute(page: const WorksheetScreen())),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cyanBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppShadows.glowCyan,
                      ),
                      child: const Icon(Icons.description_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Рабочий лист',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Печать & PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: AppRadii.lg,
                onTap: () => Navigator.of(context).push(FadeSlidePageRoute(page: const HomeworkScreen())),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.amberOrange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppShadows.glowAmber,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Домашка',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Интерактив',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Telegram Bots Quick Banner
        InkWell(
          onTap: () => TelegramBotsSheet.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF131B2E), const Color(0xFF0F172A)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFEEF2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF24A1DE).withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 30,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/pdf_icons/bot_main_miniapp.png', width: 28, height: 28),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/pdf_icons/bot_ai_director.png', width: 28, height: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Telegram боты',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF24A1DE).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '2 БОТА ▾',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Mini App (@annmetodist) • AI Чат (@MetodistAI)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF24A1DE)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsMetrics(AppProvider provider, bool isDark) {
    if (!provider.hasStatistics) {
      return GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppRadii.lg,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.indigoViolet,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Создайте свой первый конспект урока прямо сейчас',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Сегодня',
            value: '${provider.todayConspectsCount}',
            subtitle: 'уроков',
            icon: Icons.today_rounded,
            color: AppColors.cyan,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Методик',
            value: '${provider.methods.length}',
            subtitle: 'в базе',
            icon: Icons.auto_stories_rounded,
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Ср. время',
            value: provider.averageDurationDisplay,
            subtitle: 'на урок',
            icon: Icons.timer_outlined,
            color: AppColors.accentAmber,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: AppRadii.md,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupSelector(AppProvider provider, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: AppRadii.lg,
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
              color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.indigoViolet : null,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          boxShadow: isSelected ? AppShadows.glowPrimary : null,
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

  Widget _buildSearchBar(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      borderRadius: AppRadii.lg,
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 19,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Поиск по теме, предмету, методике...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilterBar(bool isDark) {
    final filters = [
      {'id': 'all', 'label': 'Все'},
      {'id': 'математика', 'label': 'Математика'},
      {'id': 'чтение', 'label': 'Чтение / Грамота'},
      {'id': 'окружающий', 'label': 'Окружающий мир'},
      {'id': 'чистописание', 'label': 'Письмо'},
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedSubjectFilter == filter['id'];
          return InkWell(
            onTap: () => setState(() => _selectedSubjectFilter = filter['id']!),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primaryIndigo : AppColors.primaryIndigo)
                    : (isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConspectsList(
    BuildContext context,
    AppProvider provider,
    List<Conspect> list,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildConspectCard(context, provider, item, index, isDark);
      },
    );
  }

  Widget _buildConspectCard(
    BuildContext context,
    AppProvider provider,
    Conspect item,
    int index,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (dir) => _confirmDelete(context, item),
        onDismissed: (dir) {
          provider.deleteConspect(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Конспект «${item.title}» удалён.')),
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
              Text('Удалить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
              FadeSlidePageRoute(page: ConspectViewScreen(existingConspect: item)),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd.MM.yy').format(item.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Badges
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppGradients.indigoViolet,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.methodName,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.subject,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${Topic.getAgeGroupLabel(item.ageGroup)} • ${item.duration}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action: Launch Lesson
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Вести урок',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryIndigo.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryIndigo, size: 18),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        FadeSlidePageRoute(page: LessonRunScreen(conspect: item)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms, delay: (index * 40).ms)
        .slideY(begin: 0.05, end: 0, duration: 220.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyState(bool isDark) {
    if (_searchQuery.isNotEmpty || _selectedSubjectFilter != 'all') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(height: AppSpacing.sm),
              const Text('Ничего не найдено', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Попробуйте сбросить фильтры или изменить поисковый запрос.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    return _buildStarterTemplatesSection(context, isDark);
  }

  Widget _buildStarterTemplatesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.primaryIndigo),
            const SizedBox(width: 6),
            const Text('Готовые шаблоны уроков', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
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
          title: 'Красивая строчка и базовые элементы',
          subject: 'Чистописание',
          method: 'Нейро-подход Мазиной',
          ageGroup: '1 класс',
          ageGroupId: 'grade_1',
          methodId: 'mazina_penmanship',
          duration: '30 мин',
          icon: Icons.draw_rounded,
          color: AppColors.accentAmber,
          isDark: isDark,
        ),
      ],
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
      borderRadius: AppRadii.lg,
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
            child: Icon(icon, size: 20, color: color),
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
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $ageGroup • $duration',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ],
      ),
    );
  }

  Widget _buildRecentPdfsSection(BuildContext context, AppProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFFE11D48)),
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryIndigo),
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
                    child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFE11D48), size: 16),
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Text('Готов', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
