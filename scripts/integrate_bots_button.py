import os

def update_home_screen():
    path = os.path.join('lib', 'screens', 'home_screen.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add import
    target_import = "import '../widgets/what_can_ai_do_widget.dart';"
    new_import = "import '../widgets/what_can_ai_do_widget.dart';\nimport '../widgets/telegram_bots_sheet.dart';"
    if "telegram_bots_sheet.dart" not in content:
        content = content.replace(target_import, new_import, 1)

    # 2. Add TelegramBotsMenuButton to _buildHeader
    # Find _buildHeader
    old_header = """  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ["""
    new_header = """  Widget _buildHeader(BuildContext context, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ["""
    if old_header in content:
        content = content.replace(old_header, new_header, 1)

    old_action_row = """          Row(
            children: [
              IconButton(
                tooltip: 'Что нового (Новости приложения)',"""
    new_action_row = """          Row(
            children: [
              TelegramBotsMenuButton(isCompact: !isDesktop),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Что нового (Новости приложения)',"""
    if old_action_row in content:
        content = content.replace(old_action_row, new_action_row, 1)

    # 3. Add Telegram Ecosystem banner to _buildBentoHero
    old_bento_end = """        // Sub Actions: Worksheets & Homework
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
      ],
    );"""

    new_bento_end = """        // Sub Actions: Worksheets & Homework
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
    );"""

    if old_bento_end in content:
        content = content.replace(old_bento_end, new_bento_end, 1)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated home_screen.dart successfully!")

def update_main_navigation_shell():
    path = os.path.join('lib', 'screens', 'main_navigation_shell.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add import
    target_import = "import '../widgets/metodist_assistant_dialog.dart';"
    new_import = "import '../widgets/metodist_assistant_dialog.dart';\nimport '../widgets/telegram_bots_sheet.dart';"
    if "telegram_bots_sheet.dart" not in content:
        content = content.replace(target_import, new_import, 1)

    # 2. Add Telegram Bots nav item to desktop sidebar (after Settings/Info)
    old_info = """                          Padding(
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
                          ),"""

    new_info_and_bots = """                          Padding(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: InkWell(
                              onTap: () => TelegramBotsSheet.show(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF24A1DE).withOpacity(isDark ? 0.12 : 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF24A1DE).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      color: Color(0xFF24A1DE),
                                      size: 20,
                                    ),
                                    if (_isSidebarExpanded) ...[
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Telegram боты (2)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF24A1DE),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),"""

    if old_info in content:
        content = content.replace(old_info, new_info_and_bots, 1)

    # 3. Add TelegramBotsMenuButton to Mobile AppBar
    old_mobile_appbar = """                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  tooltip: 'Расписание',"""

    new_mobile_appbar = """                const Spacer(),
                const TelegramBotsMenuButton(isCompact: true),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  tooltip: 'Расписание',"""

    if old_mobile_appbar in content:
        content = content.replace(old_mobile_appbar, new_mobile_appbar, 1)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated main_navigation_shell.dart successfully!")

if __name__ == '__main__':
    update_home_screen()
    update_main_navigation_shell()
