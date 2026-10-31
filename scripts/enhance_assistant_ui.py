import os

def update_assistant_dialog():
    path = 'lib/widgets/metodist_assistant_dialog.dart'
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Import
    if "import 'what_can_ai_do_widget.dart';" not in c:
        c = c.replace(
            "import 'animated_owl_widget.dart';",
            "import 'animated_owl_widget.dart';\nimport 'what_can_ai_do_widget.dart';"
        )

    # 2. Add 'Что я могу' in header
    close_btn = "          IconButton(\n            icon: const Icon(Icons.close_rounded, size: 20),"
    header_btn = """          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              WhatCanAiDoWidget.showModal(
                context,
                currentTopic: widget.currentTopic,
                currentWorld: widget.currentWorld,
                currentMethod: widget.currentMethod,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🦉', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 4),
                  Text(
                    'Что я могу',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),"""

    if close_btn in c:
        c = c.replace(close_btn, header_btn)
        print("Added 'Что я могу' button to header")
    else:
        # Try with CRLF
        close_btn_crlf = close_btn.replace('\n', '\r\n')
        if close_btn_crlf in c:
            c = c.replace(close_btn_crlf, header_btn.replace('\n', '\r\n'))
            print("Added 'Что я могу' button to header (CRLF)")

    # 3. Add suggestions in _buildMessageItem
    target_snippet = "if (widget.onApplySnippet != null) ...["
    if target_snippet in c:
        pass

    target_wrap_end = """                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),"""

    replacement_wrap = """                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSmartActionSuggestions(msg, isDark),
                  ],
                ],
              ),
            ),"""

    if target_wrap_end in c:
        c = c.replace(target_wrap_end, replacement_wrap)
        print("Added _buildSmartActionSuggestions call in _buildMessageItem")
    else:
        target_wrap_end_crlf = target_wrap_end.replace('\n', '\r\n')
        if target_wrap_end_crlf in c:
            c = c.replace(target_wrap_end_crlf, replacement_wrap.replace('\n', '\r\n'))
            print("Added _buildSmartActionSuggestions call in _buildMessageItem (CRLF)")

    # 4. Add _buildSmartActionSuggestions method before _buildLoadingBubble
    loading_target = "  Widget _buildLoadingBubble(bool isDark) {"
    suggestions_method = """  /// Ненавязчивые подсказки по вариантам дальнейших действий
  Widget _buildSmartActionSuggestions(AssistantMessage msg, bool isDark) {
    final topic = widget.currentTopic ?? 'этой теме';
    final suggestions = [
      {
        'label': '💬 Пост родителям',
        'prompt': 'Составь готовый доброжелательный пост для родительского чата по теме «$topic»',
        'mode': AssistantMode.parentChat,
      },
      {
        'label': '📚 3 уровня ДЗ',
        'prompt': 'Сформируй 3-уровневое домашнее задание (базовый, продвинутый, ТРИЗ) по теме «$topic»',
        'mode': AssistantMode.homework,
      },
      {
        'label': '🪤 Ловушка Незнайки',
        'prompt': 'Придумай задание «Ловушка Незнайки» с типичной детской ошибкой по теме «$topic»',
        'mode': AssistantMode.triz,
      },
      {
        'label': '🤸 Разминка СанПиН',
        'prompt': 'Предложи быструю 2-минутную физкультминутку для осанки и глаз к уроку «$topic»',
        'mode': AssistantMode.academic,
      },
      {
        'label': '🎮 Сюжетная игра',
        'prompt': 'Придумай 10-минутную обучающую игру-квест с маскотом по теме «$topic»',
        'mode': AssistantMode.gamification,
      },
      {
        'label': '📝 Экспресс-тест',
        'prompt': 'Составь экспресс-тест из 3 вопросов с ключами проверки по теме «$topic»',
        'mode': AssistantMode.academic,
      },
      {
        'label': '✨ Улучшить урок',
        'prompt': 'Проведи 6-модульное педагогическое улучшение урока по теме «$topic»',
        'mode': AssistantMode.academic,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.6) : const Color(0xFFF1F5F9).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withOpacity(0.6) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                'Варианты дальнейших действий:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((s) {
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _sendMessage(s['prompt'] as String, modeOverride: s['mode'] as AssistantMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {"""

    if loading_target in c:
        c = c.replace(loading_target, suggestions_method)
        print("Added _buildSmartActionSuggestions method")
    else:
        loading_target_crlf = loading_target.replace('\n', '\r\n')
        if loading_target_crlf in c:
            c = c.replace(loading_target_crlf, suggestions_method.replace('\n', '\r\n'))
            print("Added _buildSmartActionSuggestions method (CRLF)")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Updated metodist_assistant_dialog.dart")


def update_home_screen():
    path = 'lib/screens/home_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Import
    if "import '../widgets/what_can_ai_do_widget.dart';" not in c:
        c = c.replace(
            "import '../widgets/metodist_assistant_dialog.dart';",
            "import '../widgets/metodist_assistant_dialog.dart';\nimport '../widgets/what_can_ai_do_widget.dart';"
        )

    # In desktop layout, add WhatCanAiDoWidget at the top of the right sidebar
    desktop_target = """                  const SizedBox(height: 8),
                  _buildAnalyticsMetrics(provider, isDark),"""

    desktop_replacement = """                  const SizedBox(height: 8),
                  const WhatCanAiDoWidget(isCompact: false),
                  const SizedBox(height: AppSpacing.md),
                  _buildAnalyticsMetrics(provider, isDark),"""

    if desktop_target in c:
        c = c.replace(desktop_target, desktop_replacement)
        print("Added WhatCanAiDoWidget to Desktop Layout")
    else:
        desktop_target_crlf = desktop_target.replace('\n', '\r\n')
        if desktop_target_crlf in c:
            c = c.replace(desktop_target_crlf, desktop_replacement.replace('\n', '\r\n'))
            print("Added WhatCanAiDoWidget to Desktop Layout (CRLF)")

    # In mobile layout, add compact WhatCanAiDoWidget after BentoHero
    mobile_target = """                      _buildBentoHero(context, isDark),
                      const SizedBox(height: AppSpacing.md),
                      _buildAnalyticsMetrics(provider, isDark),"""

    mobile_replacement = """                      _buildBentoHero(context, isDark),
                      const SizedBox(height: AppSpacing.md),
                      const WhatCanAiDoWidget(isCompact: true),
                      const SizedBox(height: AppSpacing.md),
                      _buildAnalyticsMetrics(provider, isDark),"""

    if mobile_target in c:
        c = c.replace(mobile_target, mobile_replacement)
        print("Added WhatCanAiDoWidget to Mobile Layout")
    else:
        mobile_target_crlf = mobile_target.replace('\n', '\r\n')
        if mobile_target_crlf in c:
            c = c.replace(mobile_target_crlf, mobile_replacement.replace('\n', '\r\n'))
            print("Added WhatCanAiDoWidget to Mobile Layout (CRLF)")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Updated home_screen.dart")


if __name__ == '__main__':
    update_assistant_dialog()
    update_home_screen()
