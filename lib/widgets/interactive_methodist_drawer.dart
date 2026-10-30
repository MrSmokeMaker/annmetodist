import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/conspect.dart';
import '../services/yandex_gpt_service.dart';
import '../theme.dart';

class InteractiveMethodistDrawer extends StatefulWidget {
  final Conspect conspect;
  final YandexGptService gptService;

  const InteractiveMethodistDrawer({
    super.key,
    required this.conspect,
    required this.gptService,
  });

  static Future<void> show(BuildContext context, {
    required Conspect conspect,
    required YandexGptService gptService,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141721) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: InteractiveMethodistDrawer(
            conspect: conspect,
            gptService: gptService,
          ),
        ),
      ),
    );
  }

  @override
  State<InteractiveMethodistDrawer> createState() => _InteractiveMethodistDrawerState();
}

class _InteractiveMethodistDrawerState extends State<InteractiveMethodistDrawer> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'text': 'Здравствуйте, коллега! Я ваш методический помощник по теме **«${widget.conspect.topic}»** (${widget.conspect.methodName}).\n\nЧем могу помочь прямо сейчас во время подготовки или урока?',
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': trimmed});
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final systemPrompt = '''
Ты — опытный методист-наставник высшей категории и академический консультант.
Текущий урок:
• Предмет: ${widget.conspect.subject}
• Тема: "${widget.conspect.topic}"
• Методическая школа: ${widget.conspect.methodName}
• Возраст/Класс: ${widget.conspect.ageGroup}

ТВОЙ СТИЛЬ:
- Доброжелательный, поддерживающий тон коллеги («наставник учителю»).
- Практичные, конкретные приёмы, которые можно применить прямо у доски за 1–2 минуты.
- Опора на психологию восприятия детей и наглядность советской/классической школы.
- Ответ структурируй четко, используй списки, жирный шрифт и эмодзи. Объем ответа: 70–150 слов.
''';

      final reply = await widget.gptService.generateConspect(
        systemPrompt: systemPrompt,
        userPrompt: trimmed,
        temperature: 0.5,
        maxTokens: 1000,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': reply.trim()});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': '⚠️ Произошла ошибка связи: $e. Пожалуйста, попробуйте ещё раз.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Top handle and header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.indigoViolet,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Методист на связи',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          widget.conspect.methodName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Quick action pills
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _buildPill(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Ученик не понимает',
                query: 'Ребёнок не понимает суть темы «${widget.conspect.topic}». Дай 2 наглядные тактильные метафоры или бытовых приёма, чтобы объяснить тему за 1 минуту.',
              ),
              _buildPill(
                icon: Icons.timer_outlined,
                label: 'Блиц перед звонком',
                query: 'Составь 4 быстрых устных вопроса для пятиминутки перед звонком по теме «${widget.conspect.topic}» для проверки усвоения.',
              ),
              _buildPill(
                icon: Icons.work_outline_rounded,
                label: 'Связь с реальной жизнью',
                query: 'Покажи, в каких современных профессиях и жизненных ситуациях реально применяется тема «${widget.conspect.topic}».',
              ),
              _buildPill(
                icon: Icons.self_improvement_rounded,
                label: 'Нейроминутка',
                query: 'Предложи 1-минутную кинезиологическую нейрогимнастику или двигательную разминку, снимающую утомление на уроке по этой теме.',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (ctx, idx) {
              final msg = _messages[idx];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryIndigo
                        : (isDark ? const Color(0xFF1F2432) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                      bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                    ),
                  ),
                  child: MarkdownBody(
                    data: msg['text'] ?? '',
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(
                        color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Методист думает...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181C28) : const Color(0xFFF8FAFC),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Задайте вопрос по уроку...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262C3E) : Colors.white,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _sendMessage(_inputController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required String query,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.primaryIndigo),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: isDark ? const Color(0xFF1E2333) : const Color(0xFFEEF2F6),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () => _sendMessage(query),
      ),
    );
  }
}
