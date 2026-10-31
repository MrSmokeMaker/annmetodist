import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/telegram/telegram_web_app_service.dart';
import '../screens/profile_screen.dart';

class TelegramBotsSheet extends StatefulWidget {
  const TelegramBotsSheet({super.key});

  /// Открыть окно выбора Telegram-ботов
  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    TelegramWebAppService().hapticSelection();

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: TelegramBotsSheet(),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const TelegramBotsSheet(),
      );
    }
  }

  @override
  State<TelegramBotsSheet> createState() => _TelegramBotsSheetState();
}

class _TelegramBotsSheetState extends State<TelegramBotsSheet> {
  int _activeTab = 0; // 0 = Боты, 1 = Команды и фичи
  String? _copiedBotHandle;
  String? _copiedCommand;

  final String _mainBotUrl = 'https://t.me/annmetodist_bot?start=miniapp';
  final String _aiBotUrl = 'https://t.me/MetodistAIpro_bot';

  void _openUrl(String url) {
    TelegramWebAppService().hapticImpact('medium');
    TelegramWebAppService().openTelegramLink(url);
  }

  void _copyToClipboard(String text, {bool isBot = true}) {
    Clipboard.setData(ClipboardData(text: text));
    TelegramWebAppService().hapticNotification('success');
    setState(() {
      if (isBot) {
        _copiedBotHandle = text;
      } else {
        _copiedCommand = text;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBot
                    ? 'Логин $text скопирован в буфер!'
                    : 'Команда скопирована! Вставьте в чат бота.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (isBot && _copiedBotHandle == text) _copiedBotHandle = null;
          if (!isBot && _copiedCommand == text) _copiedCommand = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 860 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F121E) : Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 28),
            border: Border.all(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.18),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDesktop) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  _buildHeader(context, isDark, isDesktop),
                  _buildTabs(isDark),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _activeTab == 0
                          ? _buildBotsComparisonView(context, isDark, isDesktop)
                          : _buildCommandsPlaygroundView(context, isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isDesktop ? 20 : 14, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF24A1DE), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF24A1DE).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Экосистема Telegram',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cyanBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '2 БОТА',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Выберите бота для запуска Mini App или отдельного ИИ-диалога',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0x18FFFFFF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  TelegramWebAppService().hapticSelection();
                  setState(() => _activeTab = 0);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeTab == 0
                        ? (isDark ? const Color(0xFF24A1DE) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        size: 16,
                        color: _activeTab == 0
                            ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF24A1DE))
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Выбор бота (2)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _activeTab == 0
                              ? (_activeTab == 0 && isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  TelegramWebAppService().hapticSelection();
                  setState(() => _activeTab = 1);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeTab == 1
                        ? (isDark ? const Color(0xFF4F46E5) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 16,
                        color: _activeTab == 1
                            ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF4F46E5))
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Команды и фичи ⚡',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _activeTab == 1
                              ? (_activeTab == 1 && isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotsComparisonView(BuildContext context, bool isDark, bool isDesktop) {
    if (isDesktop) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBotCard(
                  title: 'Методист Pro | Mini App',
                  username: '@annmetodist_bot',
                  roleTag: 'Основной бот',
                  imageAsset: 'assets/images/pdf_icons/bot_main_miniapp.png',
                  accentColor: const Color(0xFF24A1DE),
                  gradient: const [Color(0xFF24A1DE), Color(0xFF0284C7)],
                  statusText: '🟢 В сети • Все тарифы',
                  badgeLabel: 'Mini App 🚀',
                  features: [
                    '📱 Запуск полноценного веб-приложения внутри Telegram',
                    '📅 Интерактивное расписание, календарь и таймер урока',
                    '📄 Мгновенный экспорт готовых PDF конспектов в чат',
                    '🔔 Уведомления и напоминания о запланированных уроках',
                  ],
                  primaryButtonText: 'Запустить Mini App 🚀',
                  onPrimaryTap: () => _openUrl(_mainBotUrl),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBotCard(
                  title: 'Metodist AI Pro | Ассистент',
                  username: '@MetodistAIpro_bot',
                  roleTag: 'AI-Ассистент',
                  imageAsset: 'assets/images/pdf_icons/bot_ai_director.png',
                  accentColor: const Color(0xFF8B5CF6),
                  gradient: const [Color(0xFF8B5CF6), Color(0xFFF59E0B)],
                  statusText: '✨ YandexGPT Pro • 8k контекст',
                  badgeLabel: '👑 Директор',
                  features: [
                    '🧠 Живой диалог с нейросетью YandexGPT Pro в Telegram',
                    '⚡ Пользовательские команды (/addaction <название>)',
                    '📢 Генератор постов для родительских чатов в 1 клик',
                    '🎯 3 уровня ДЗ, тесты, физминутки и ловушки внимания',
                  ],
                  primaryButtonText: 'Чат с ИИ-Ассистентом ✨',
                  onPrimaryTap: () => _openUrl(_aiBotUrl),
                  isDark: isDark,
                  isDirectorOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoBanner(context, isDark),
        ],
      );
    }

    // Mobile layout: stacked
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildBotCard(
          title: 'Методист Pro | Mini App',
          username: '@annmetodist_bot',
          roleTag: 'Основной бот',
          imageAsset: 'assets/images/pdf_icons/bot_main_miniapp.png',
          accentColor: const Color(0xFF24A1DE),
          gradient: const [Color(0xFF24A1DE), Color(0xFF0284C7)],
          statusText: '🟢 В сети • Все тарифы',
          badgeLabel: 'Mini App 🚀',
          features: [
            '📱 Запуск веб-приложения прямо внутри Telegram',
            '📅 Интерактивное расписание, календарь и таймер',
            '📄 Мгновенный экспорт PDF конспектов в чат',
            '🔔 Напоминания перед началом уроков',
          ],
          primaryButtonText: 'Запустить Mini App 🚀',
          onPrimaryTap: () => _openUrl(_mainBotUrl),
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildBotCard(
          title: 'Metodist AI Pro | Ассистент',
          username: '@MetodistAIpro_bot',
          roleTag: 'AI-Ассистент',
          imageAsset: 'assets/images/pdf_icons/bot_ai_director.png',
          accentColor: const Color(0xFF8B5CF6),
          gradient: const [Color(0xFF8B5CF6), Color(0xFFF59E0B)],
          statusText: '✨ YandexGPT Pro • 8k контекст',
          badgeLabel: '👑 Директор',
          features: [
            '🧠 Чат с нейросетью YandexGPT Pro в Telegram',
            '⚡ Создание своих команд (/addaction <команда>)',
            '📢 Посты для родителей и 3 уровня ДЗ за 5 сек',
            '🎯 Экспресс-тесты и ловушки внимания Незнайки',
          ],
          primaryButtonText: 'Чат с ИИ-Ассистентом ✨',
          onPrimaryTap: () => _openUrl(_aiBotUrl),
          isDark: isDark,
          isDirectorOnly: true,
        ),
        const SizedBox(height: 16),
        _buildInfoBanner(context, isDark),
      ],
    );
  }

  Widget _buildBotCard({
    required String title,
    required String username,
    required String roleTag,
    required String imageAsset,
    required Color accentColor,
    required List<Color> gradient,
    required String statusText,
    required String badgeLabel,
    required List<String> features,
    required String primaryButtonText,
    required VoidCallback onPrimaryTap,
    required bool isDark,
    bool isDirectorOnly = false,
  }) {
    final isCopied = _copiedBotHandle == username;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151928) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDirectorOnly
              ? const Color(0xFFF59E0B).withOpacity(0.4)
              : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
          width: isDirectorOnly ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top avatar + title + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imageAsset,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: accentColor.withOpacity(0.2),
                      child: Icon(Icons.smart_toy_rounded, color: accentColor, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            username,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(username, isBot: true),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCopied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 13,
                          color: isCopied ? AppColors.success : accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCopied ? 'Скопирован' : 'Копировать',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCopied ? AppColors.success : accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Feature bullets
          ...features.map((feat) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feat.substring(0, 2),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat.substring(2).trim(),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    primaryButtonText,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x18FFFFFF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Оба бота работают в тандеме: основной бот запускает интерфейс приложения, а MetodistAI генерирует материалы в чате Telegram.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Тарифы',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryIndigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandsPlaygroundView(BuildContext context, bool isDark) {
    final commands = [
      {
        'cmd': '/start',
        'bot': '@annmetodist_bot & @MetodistAIpro_bot',
        'desc': 'Перезапуск бота, главное интерактивное меню и выбор режима работы',
        'badge': 'Базовый',
      },
      {
        'cmd': '/addaction родителям | Составь доброжелательный пост для родительского чата о результатах урока: {тема}',
        'bot': '@MetodistAIpro_bot',
        'desc': 'Создать команду генерации отчета для родителей по теме урока',
        'badge': '👑 Директор',
      },
      {
        'cmd': '/addaction дз3уровня | Составь 3 уровня домашнего задания (базовый, продвинутый, олимпиадный) по теме: {тема}',
        'bot': '@MetodistAIpro_bot',
        'desc': 'Создать команду дифференцированного ДЗ в 3 уровня',
        'badge': '👑 Директор',
      },
      {
        'cmd': '/addaction квиз | Придумай экспресс-квиз из 4 вопросов с выбором ответов по теме: {тема}',
        'bot': '@MetodistAIpro_bot',
        'desc': 'Создать быструю команду проверки знаний на уроке',
        'badge': '👑 Директор',
      },
      {
        'cmd': '/actions',
        'bot': '@MetodistAIpro_bot',
        'desc': 'Посмотреть список всех ваших созданных команд',
        'badge': '👑 Директор',
      },
      {
        'cmd': '/pdf',
        'bot': '@annmetodist_bot',
        'desc': 'Быстро получить готовый PDF конспект урока прямо в диалог Telegram',
        'badge': 'Методист Pro',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Нажмите на любую команду, чтобы мгновенно скопировать её и отправить в чат бота:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...commands.map((c) {
          final cmdText = c['cmd']!;
          final isCopied = _copiedCommand == cmdText;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _copyToClipboard(cmdText, isBot: false),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151928) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCopied
                        ? AppColors.success
                        : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                    width: isCopied ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c['badge']!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c['bot']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                          size: 16,
                          color: isCopied ? AppColors.success : const Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C0E17) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cmdText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c['desc']!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Кнопка вызова вылезающего меню выбора Telegram-ботов
class TelegramBotsMenuButton extends StatelessWidget {
  final bool isCompact;

  const TelegramBotsMenuButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => TelegramBotsSheet.show(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF24A1DE), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF24A1DE).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'Боты',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TelegramBotsSheet.show(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151928) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF24A1DE).withOpacity(0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF24A1DE).withOpacity(isDark ? 0.25 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF24A1DE), Color(0xFF4F46E5)],
                  ),
                ),
                child: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Telegram боты',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24A1DE).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF24A1DE),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '@annmetodist & @MetodistAI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF24A1DE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
