import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'world_studio_screen.dart';
import 'methodology_architect_screen.dart';
import '../widgets/generation_type_sheet.dart';
import '../widgets/app_news_modal.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isSidebarHovered = false;
  bool _isSidebarPinned = false;

  @override
  void initState() {
    super.initState();
    final tg = TelegramWebAppService();
    if (tg.isInsideTelegram) {
      final param = tg.startParam;
      if (param == 'studio' || param == 'worlds') {
        _currentIndex = 3;
      } else if (param == 'architect' || param == 'director') {
        _currentIndex = 2;
      } else if (param == 'calendar') {
        _currentIndex = 1;
      } else if (param == 'profile') {
        _currentIndex = 4;
      }
    }
  }

  bool get _isSidebarExpanded => _isSidebarPinned || _isSidebarHovered;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    MethodologyArchitectScreen(),
    WorldStudioScreen(),
    ProfileScreen(),
  ];

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GenerationTypeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop) {
      return Scaffold(
        body: AmbientBackground(
          child: Row(
            children: [
              // Animated Sidebar on Desktop
              MouseRegion(
                onEnter: (_) => setState(() => _isSidebarHovered = true),
                onExit: (_) => setState(() => _isSidebarHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: _isSidebarExpanded ? 240 : 76,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0C0E17).withOpacity(0.92)
                        : Colors.white.withOpacity(0.94),
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                        blurRadius: 24,
                        offset: const Offset(4, 0),
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 22),
                          // App Logo / Title & Pin Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.indigoViolet,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppShadows.glowPrimary,
                                  ),
                                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                                ),
                                if (_isSidebarExpanded) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Методист',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'AI Assistant Pro',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 18,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    tooltip: _isSidebarPinned ? 'Открепить панель' : 'Закрепить панель',
                                    icon: Icon(
                                      _isSidebarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                      color: _isSidebarPinned
                                          ? AppColors.primaryIndigo
                                          : (isDark ? Colors.white54 : AppColors.textMutedLight),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSidebarPinned = !_isSidebarPinned;
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Create Button (Linear / Raycast Action Button)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Tooltip(
                              message: _isSidebarExpanded ? '' : 'Создать урок или задание',
                              child: InkWell(
                                onTap: () => _openCreateSheet(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.indigoViolet,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                    boxShadow: AppShadows.glowPrimary,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: _isSidebarExpanded
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                      if (_isSidebarExpanded) ...[
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Создать урок',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Navigation Items
                          _buildDesktopNavItem(
                            index: 0,
                            icon: Icons.dashboard_outlined,
                            activeIcon: Icons.dashboard_rounded,
                            label: 'Конспекты & Уроки',
                            isDark: isDark,
                          ),
                          _buildDesktopNavItem(
                            index: 1,
                            icon: Icons.calendar_today_outlined,
                            activeIcon: Icons.calendar_month_rounded,
                            label: 'Расписание',
                            isDark: isDark,
                          ),
                          _buildDesktopNavItem(
                            index: 2,
                            icon: Icons.psychology_outlined,
                            activeIcon: Icons.psychology_rounded,
                            label: '👑 Конструктор методик [ДИРЕКТОР]',
                            isDark: isDark,
                          ),
                          _buildDesktopNavItem(
                            index: 3,
                            icon: Icons.palette_outlined,
                            activeIcon: Icons.palette_rounded,
                            label: '🎨 Студия миров [ДИРЕКТОР]',
                            isDark: isDark,
                          ),
                          _buildDesktopNavItem(
                            index: 4,
                            icon: Icons.badge_outlined,
                            activeIcon: Icons.badge_rounded,
                            label: 'Тарифы & Квоты',
                            isDark: isDark,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      size: 20,
                                    ),
                                    if (_isSidebarExpanded) ...[
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Настройки',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: InkWell(
                              onTap: () => AppNewsModal.show(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.accentCyan,
                                      size: 20,
                                    ),
                                    if (_isSidebarExpanded) ...[
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Что нового (i)',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Model / status badge
                          if (_isSidebarExpanded)
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.success,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'YandexGPT 5 Pro',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main Page View
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile layout with Floating Glass Bottom Navigation
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                if (TelegramWebAppService().isInsideTelegram)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24A1DE).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF24A1DE).withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.send_rounded, size: 12, color: Color(0xFF24A1DE)),
                        const SizedBox(width: 5),
                        Text(
                          TelegramWebAppService().user != null
                              ? TelegramWebAppService().user!.displayName
                              : '@annmetodist_bot',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24A1DE),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  tooltip: 'Расписание',
                  onPressed: () {
                    TelegramWebAppService().hapticSelection();
                    setState(() => _currentIndex = 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  tooltip: 'Настройки',
                  onPressed: () {
                    TelegramWebAppService().hapticImpact('light');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: AmbientBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F121C).withOpacity(0.85)
                    : Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? AppColors.specularHighlight : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: AppShadows.cardLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Уроки',
                    isDark: isDark,
                  ),

                  _buildMobileNavItem(
                    index: 2,
                    icon: Icons.psychology_outlined,
                    activeIcon: Icons.psychology_rounded,
                    label: 'Методики 👑',
                    isDark: isDark,
                  ),

                  // Floating Center Quick Action
                  GestureDetector(
                    onTap: () => _openCreateSheet(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppGradients.indigoViolet,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: AppShadows.glowPrimary,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  _buildMobileNavItem(
                    index: 3,
                    icon: Icons.palette_outlined,
                    activeIcon: Icons.palette_rounded,
                    label: 'Студия',
                    isDark: isDark,
                  ),

                  _buildMobileNavItem(
                    index: 4,
                    icon: Icons.badge_outlined,
                    activeIcon: Icons.badge_rounded,
                    label: 'Профиль',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Tooltip(
        message: _isSidebarExpanded ? '' : label,
        preferBelow: false,
        child: Semantics(
          label: label,
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _currentIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primaryIndigo.withOpacity(0.18) : AppColors.primaryIndigo.withOpacity(0.10))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: isDark
                            ? AppColors.primaryIndigo.withOpacity(0.35)
                            : AppColors.primaryIndigo.withOpacity(0.25),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.primaryIndigo)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    size: 20,
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? (isDark ? AppColors.primaryIndigo : AppColors.primaryIndigo)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryIndigo)
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
