import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../widgets/generation_type_sheet.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isSidebarHovered = false;
  bool _isSidebarPinned = false;

  bool get _isSidebarExpanded => _isSidebarPinned || _isSidebarHovered;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
    SettingsScreen(),
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
                  width: _isSidebarExpanded ? 220 : 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F121C).withOpacity(0.92)
                        : Colors.white.withOpacity(0.95),
                    border: Border(
                      right: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
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
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryIndigo.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                            ),
                            if (_isSidebarExpanded) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Методист',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                      : (isDark ? Colors.white60 : AppColors.textMutedLight),
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

                      // Create Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Tooltip(
                          message: _isSidebarExpanded ? '' : 'Создать урок или задание',
                          child: InkWell(
                            onTap: () => _openCreateSheet(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: AppGradients.cyanBlue,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCyan.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: _isSidebarExpanded
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                                  if (_isSidebarExpanded) ...[
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Создать',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 12),

                      // Navigation Items
                      _buildDesktopNavItem(
                        index: 0,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Конспекты',
                        isDark: isDark,
                      ),
                      _buildDesktopNavItem(
                        index: 1,
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month_rounded,
                        label: 'Календарь',
                        isDark: isDark,
                      ),
                      _buildDesktopNavItem(
                        index: 2,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Тарифы & Профиль',
                        isDark: isDark,
                      ),
                      _buildDesktopNavItem(
                        index: 3,
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings_rounded,
                        label: 'Настройки',
                        isDark: isDark,
                      ),

                      const Spacer(),

                      // Model / status badge
                      if (_isSidebarExpanded)
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFB300)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'YandexGPT 5 Pro',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
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

    // Mobile layout with Bottom Navigation & floating center button
    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F121C).withOpacity(0.88) : Colors.white.withOpacity(0.92),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMobileNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Главная',
                  isDark: isDark,
                ),

                _buildMobileNavItem(
                  index: 1,
                  icon: Icons.calendar_month_rounded,
                  label: 'Календарь',
                  isDark: isDark,
                ),

                // Center Action Button
                Tooltip(
                  message: 'Создать',
                  child: Semantics(
                    button: true,
                    label: 'Создать новый конспект или задание',
                    child: GestureDetector(
                      onTap: () => _openCreateSheet(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          gradient: AppGradients.cyanBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

                _buildMobileNavItem(
                  index: 2,
                  icon: Icons.person_rounded,
                  label: 'Профиль',
                  isDark: isDark,
                ),

                _buildMobileNavItem(
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'Настройки',
                  isDark: isDark,
                ),
              ],
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
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primaryIndigo.withOpacity(0.25) : AppColors.primaryIndigo.withOpacity(0.12))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: isDark
                            ? AppColors.primaryIndigo.withOpacity(0.4)
                            : AppColors.primaryIndigo.withOpacity(0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? (isDark ? AppColors.accentCyan : AppColors.primaryIndigo)
                        : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                    size: 22,
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.primaryIndigo)
                              : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? (isDark ? AppColors.accentCyan : AppColors.primaryIndigo)
                    : (isDark ? Colors.white60 : AppColors.textMutedLight),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryIndigo)
                      : (isDark ? Colors.white60 : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
