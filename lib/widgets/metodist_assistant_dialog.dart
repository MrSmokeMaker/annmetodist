import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thematic_world.dart';
import '../services/assistant_ai_service.dart';
import '../services/telegram/telegram_web_app_service.dart';
import '../theme.dart';
import 'animated_owl_widget.dart';

class MetodistAssistantDialog extends StatefulWidget {
  final String? currentTopic;
  final ThematicWorld? currentWorld;
  final String? currentMethod;
  final String? ageGroup;
  final Function(String snippet)? onApplySnippet;

  const MetodistAssistantDialog({
    super.key,
    this.currentTopic,
    this.currentWorld,
    this.currentMethod,
    this.ageGroup,
    this.onApplySnippet,
  });

  /// Открытие модального окна ассистента
  static Future<void> show(
    BuildContext context, {
    String? currentTopic,
    ThematicWorld? currentWorld,
    String? currentMethod,
    String? ageGroup,
    Function(String snippet)? onApplySnippet,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: MetodistAssistantDialog(
            currentTopic: currentTopic,
            currentWorld: currentWorld,
            currentMethod: currentMethod,
            ageGroup: ageGroup,
            onApplySnippet: onApplySnippet,
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MetodistAssistantDialog(
          currentTopic: currentTopic,
          currentWorld: currentWorld,
          currentMethod: currentMethod,
          ageGroup: ageGroup,
          onApplySnippet: onApplySnippet,
        ),
      );
    }
  }

  @override
  State<MetodistAssistantDialog> createState() => _MetodistAssistantDialogState();
}

class _MetodistAssistantDialogState extends State<MetodistAssistantDialog> {
  final AssistantAiService _aiService = AssistantAiService();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<AssistantMessage> _messages = [];
  bool _isLoading = false;
  OwlState _owlState = OwlState.idle;
  AssistantMode _selectedMode = AssistantMode.academic;

  @override
  void initState() {
    super.initState();

    // Приветственное сообщение от Совёнка
    final initialWorld = widget.currentWorld?.title ?? 'Сказочный лес';
    final initialTopic = widget.currentTopic ?? 'Планирование занятия';
    _messages.add(
      AssistantMessage(
        id: 'msg_welcome',
        sender: AssistantSender.assistant,
        text: 'Здравствуйте! Я **Совёнок-Методист** 🦉\n\n'
            'Я подключён к вашему уроку: **"$initialTopic"** в мире **«$initialWorld»**.\n\n'
            '✨ **Чем помочь прямо сейчас?**\n'
            '• 🌟 **Улучшить с MetodistPro AI** (глубокое обогащение урока)\n'
            '• 💬 Составить готовый пост для родительского чата\n'
            '• 📚 Разбить домашку на 3 уровня (ФГОС, практика, ТРИЗ)\n'
            '• 🎮 Придумать 10-минутную сюжетную игру-квест\n'
            '• 📝 Сделать экспресс-тест с ключами проверки\n'
            '• ⚡ Добавить свои действия и быстрые команды!',
        timestamp: DateTime.now(),
      ),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isLoading) {
        setState(() => _owlState = OwlState.listening);
      } else if (!_isLoading) {
        setState(() => _owlState = OwlState.idle);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {AssistantMode? modeOverride}) async {
    final clean = text.trim();
    if (clean.isEmpty || _isLoading) return;

    TelegramWebAppService().hapticSelection();
    _textCtrl.clear();

    final activeMode = modeOverride ?? _selectedMode;

    final userMsg = AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: AssistantSender.user,
      text: clean,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _owlState = OwlState.thinking;
      if (modeOverride != null) _selectedMode = modeOverride;
    });
    _scrollToBottom();

    final reply = await _aiService.askAssistant(
      question: clean,
      history: _messages,
      currentTopic: widget.currentTopic,
      currentWorld: widget.currentWorld,
      currentMethod: widget.currentMethod,
      ageGroup: widget.ageGroup,
      mode: activeMode,
    );

    if (!mounted) return;

    TelegramWebAppService().hapticNotification('success');
    final assistantMsg = AssistantMessage(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      sender: AssistantSender.assistant,
      text: reply,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantMsg);
      _isLoading = false;
      _owlState = OwlState.speaking;
    });
    _scrollToBottom();

    // Возврат в idle через 3 секунды после завершения ответа
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isLoading) {
        setState(() => _owlState = OwlState.idle);
      }
    });
  }

  void _showAddCustomActionDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final promptCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Добавить своё действие', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Создайте собственную команду для Совёнка (например: «стишок», «опрос в кругу», «загадка»):',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Название кнопки/действия',
                hintText: 'например: 🎵 Стишок',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Промпт / Инструкция',
                hintText: 'например: Сочини забавное четверостишие по теме урока для быстрого запоминания правила',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final t = titleCtrl.text.trim();
              final p = promptCtrl.text.trim();
              if (t.isNotEmpty && p.isNotEmpty) {
                _aiService.addCustomPrompt(
                  title: t,
                  prompt: p,
                );
                Navigator.pop(ctx);
                setState(() {});
                TelegramWebAppService().hapticNotification('success');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Действие «$t» успешно добавлено!')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: isDesktop ? 700 : double.infinity,
          height: isDesktop ? 680 : MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.92)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
            border: Border.all(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildModeSelector(isDark),
              _buildQuickPromptsBar(isDark),
              const Divider(height: 1, color: Color(0x1A64748B)),
              Expanded(child: _buildMessagesList(isDark)),
              _buildInputBar(isDark),
            ],
          ),
        ),
      ),
    );

    if (isDesktop) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader(bool isDark) {
    String statusText = 'В сети';
    Color statusColor = const Color(0xFF10B981);

    if (_owlState == OwlState.thinking) {
      statusText = '✨ Размышляет над ответом...';
      statusColor = const Color(0xFFF59E0B);
    } else if (_owlState == OwlState.listening) {
      statusText = '🦉 Слушает вас...';
      statusColor = const Color(0xFF6366F1);
    } else if (_owlState == OwlState.speaking) {
      statusText = '⭐ Отвечает';
      statusColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : const Color(0xFFF8FAFC).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          // Анимированный Совёнок в шапке окна
          AnimatedOwlWidget(
            state: _owlState,
            size: 52,
            onTap: () {
              TelegramWebAppService().hapticSelection();
              setState(() => _owlState = OwlState.speaking);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && !_isLoading) setState(() => _owlState = OwlState.idle);
              });
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Совёнок-Методист',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AI PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.currentWorld != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${widget.currentWorld!.title}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }

  /// Селектор педагогического режима Совёнка
  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF1F5F9).withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AssistantMode.values.map((mode) {
            final isSelected = mode == _selectedMode;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ),
                ),
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 0.8,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    TelegramWebAppService().hapticSelection();
                    setState(() => _selectedMode = mode);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickPromptsBar(bool isDark) {
    final allPrompts = _aiService.getAllPrompts();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: [
          // Отдельная кнопка «✨ Улучшить с MetodistPro AI»
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.amber),
              label: const Text(
                'Улучшить с MetodistPro AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF818CF8), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {
                _sendMessage(
                  'Проведи глубокое педагогическое улучшение урока: добавь дословные диалоги учителя и детей с таймингом, проблемную ТРИЗ-задачу, ловушку Незнайки, разминку по СанПиН и 3 уровня ДЗ.',
                  modeOverride: AssistantMode.academic,
                );
              },
            ),
          ),

          // Все стандартные и пользовательские чипсы
          ...allPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  prompt.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.7)
                    : const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: prompt.isCustom
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  width: prompt.isCustom ? 1.2 : 0.8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () => _sendMessage(prompt.prompt, modeOverride: prompt.mode),
              ),
            );
          }),

          // Кнопка добавления кастомного действия
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF10B981)),
            label: const Text(
              'Своё действие',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
            ),
            backgroundColor: isDark
                ? const Color(0xFF064E3B).withOpacity(0.3)
                : const Color(0xFFECFDF5),
            side: const BorderSide(color: Color(0xFF10B981), width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => _showAddCustomActionDialog(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildLoadingBubble(isDark);
        }
        final msg = _messages[index];
        return _buildMessageItem(msg, isDark);
      },
    );
  }

  Widget _buildMessageItem(AssistantMessage msg, bool isDark) {
    final isUser = msg.sender == AssistantSender.user;
    final isParentChatPost = !isUser && msg.text.contains('родительского чата');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF064E3B)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD97706), width: 1.2),
              ),
              child: const Center(
                child: Text('🦉', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark
                        ? const Color(0xFF1E293B).withOpacity(0.85)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            TelegramWebAppService().hapticNotification('success');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isParentChatPost
                                    ? 'Пост для родителей скопирован! Можно вставлять в чат.'
                                    : 'Ответ скопирован в буфер обмена!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isParentChatPost ? Icons.chat_bubble_outline_rounded : Icons.copy_rounded,
                                  size: 13,
                                  color: isParentChatPost ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isParentChatPost ? 'Скопировать для родителей' : 'Скопировать',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isParentChatPost ? FontWeight.w600 : FontWeight.normal,
                                    color: isParentChatPost ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.onApplySnippet != null) ...[
                          InkWell(
                            onTap: () {
                              widget.onApplySnippet!(msg.text);
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_task_rounded, size: 13, color: Color(0xFF6366F1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Вставить в конспект',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF047857),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🦉', style: TextStyle(fontSize: 16))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Совёнок формулирует решение...',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Спросите Совёнка (разминка, пост родителям, ДЗ)...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
              onPressed: () => _sendMessage(_textCtrl.text),
              tooltip: 'Отправить',
            ),
          ),
        ],
      ),
    );
  }
}
