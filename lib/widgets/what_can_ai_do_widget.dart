import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/thematic_world.dart';
import '../services/telegram/telegram_web_app_service.dart';
import 'animated_owl_widget.dart';
import 'metodist_assistant_dialog.dart';

/// Виджет-витрина способностей AI-помощника «Что я могу 🦉»
/// Без горизонтального скролла: интуитивная сетка 2x2 для быстрого доступа + раскрытие полного списка
class WhatCanAiDoWidget extends StatefulWidget {
  final String? currentTopic;
  final ThematicWorld? currentWorld;
  final String? currentMethod;
  final bool isCompact;

  const WhatCanAiDoWidget({
    super.key,
    this.currentTopic,
    this.currentWorld,
    this.currentMethod,
    this.isCompact = false,
  });

  /// Открытие модального окна «Что я могу»
  static Future<void> showModal(
    BuildContext context, {
    String? currentTopic,
    ThematicWorld? currentWorld,
    String? currentMethod,
  }) {
    TelegramWebAppService().hapticSelection();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 8),
        child: WhatCanAiDoWidget(
          currentTopic: currentTopic,
          currentWorld: currentWorld,
          currentMethod: currentMethod,
          isCompact: false,
        ),
      ),
    );
  }

  @override
  State<WhatCanAiDoWidget> createState() => _WhatCanAiDoWidgetState();
}

class _WhatCanAiDoWidgetState extends State<WhatCanAiDoWidget> {
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _capabilities = [
    {
      'icon': '✨',
      'title': 'Улучшить с MetodistPro',
      'tag': '6 в 1',
      'color': const Color(0xFFF59E0B),
      'desc': 'Глубокое 6-модульное педагогическое обогащение урока: пошаговый диалог учителя и детей, ТРИЗ-проблема, поминутный тайм-план по СанПиН, ловушка Незнайки, дифференцированное ДЗ и пост в чат родителей.',
      'actionPrompt': 'Проведи комплексное улучшение урока с MetodistPro AI: диалог учителя, тайм-план, ТРИЗ-задача, ловушка Незнайки, 3 уровня ДЗ и пост для родителей.',
    },
    {
      'icon': '💬',
      'title': 'В родительский чат',
      'tag': 'WhatsApp / TG',
      'color': const Color(0xFF10B981),
      'desc': 'Готовый доброжелательный и тактичный текст для родительского чата: чему научились, похвала ребятам за активность и короткий 5-минутный совет без стресса.',
      'actionPrompt': 'Составь готовый доброжелательный пост для родительского чата: успехи детей, чему научились и совет на 5 минут дома.',
    },
    {
      'icon': '📚',
      'title': '3 Уровня домашки',
      'tag': 'ФГОС Дифференциация',
      'color': const Color(0xFF6366F1),
      'desc': 'Разбивка ДЗ на три ясных уровня: 1) Базовый обязательный (ФГОС, 7-10 мин), 2) Продвинутый (практика с подвохом), 3) ТРИЗ-вызов (олимпиадная эвристика со звёздочкой).',
      'actionPrompt': 'Сформируй дифференцированное домашнее задание на 3 уровня: Базовый (ФГОС), Продвинутый и ТРИЗ-вызов со звёздочкой.',
    },
    {
      'icon': '🎮',
      'title': 'Сюжетная игра-квест',
      'tag': '10 мин с маскотом',
      'color': const Color(0xFFEC4899),
      'desc': '10-минутная динамическая обучающая игра или сюжетный квест по теме урока с участием маскотов (Лисёнок Астро, Совёнок Архип, Енот Шерлок, Бобёр Винтик, Медвежонок Барни).',
      'actionPrompt': 'Придумай 10-минутную сюжетную обучающую игру-квест с маскотом нашего игрового мира для закрепления темы урока.',
    },
    {
      'icon': '📝',
      'title': 'Экспресс-тест',
      'tag': '3 вопроса + эталоны',
      'color': const Color(0xFF8B5CF6),
      'desc': 'Быстрый контрольный срез из 3 вопросов с вариантами ответов, эталонными ключами для быстрой проверки учителем и критериями оценивания (⭐⭐⭐).',
      'actionPrompt': 'Составь экспресс-тест среза знаний из 3 вопросов с 4 вариантами ответов, ключами проверки и критериями оценивания.',
    },
    {
      'icon': '🪤',
      'title': 'Ловушка Незнайки',
      'tag': 'Критическое мышление',
      'color': const Color(0xFFEF4444),
      'desc': 'Забавное дидактическое задание с типичной детской ошибкой. Дети выступают в роли строгих экспертов, находят подвох и формулируют истинное правило.',
      'actionPrompt': 'Придумай задание «Ловушка Незнайки» с типичной детской ошибкой по теме урока для развития критического мышления.',
    },
    {
      'icon': '🤸',
      'title': 'Физкультминутка',
      'tag': 'СанПиН разминка',
      'color': const Color(0xFF06B6D4),
      'desc': 'Тематическая разминка для осанки, координации и гимнастика для снятия зрительного напряжения с экрана и тетради (2 минуты).',
      'actionPrompt': 'Предложи быструю 2-минутную физкультминутку по нормам СанПиН с упражнениями для осанки и гимнастикой для глаз.',
    },
    {
      'icon': '⚡',
      'title': 'Свои команды',
      'tag': 'Кастомные промпты',
      'color': const Color(0xFFEAB308),
      'desc': 'Создание собственных кнопок-команд (например, «стишок-запоминалка», «круг рефлексии», «карточка за 3 минуты») со своими шаблонами инструкций.',
      'actionPrompt': 'Покажи, как работают кастомные действия учителя, и помоги создать первое персональное действие.',
    },
  ];

  void _triggerCapability(BuildContext context, String prompt) {
    TelegramWebAppService().hapticSelection();
    MetodistAssistantDialog.show(
      context,
      currentTopic: widget.currentTopic,
      currentWorld: widget.currentWorld,
      currentMethod: widget.currentMethod,
      initialPrompt: prompt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomTopic = widget.currentTopic != null && widget.currentTopic!.trim().isNotEmpty && widget.currentTopic != 'Тема урока';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка с анимированным Совёнком
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        TelegramWebAppService().hapticSelection();
                        MetodistAssistantDialog.show(
                          context,
                          currentTopic: widget.currentTopic,
                          currentWorld: widget.currentWorld,
                          currentMethod: widget.currentMethod,
                        );
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF047857), Color(0xFF064E3B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
                        ),
                        child: const Center(
                          child: AnimatedOwlWidget(
                            state: OwlState.speaking,
                            size: 42,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✨', style: TextStyle(fontSize: 11)),
                                    SizedBox(width: 4),
                                    Text(
                                      'MetodistPRO',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFF59E0B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (widget.isCompact)
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    TelegramWebAppService().hapticSelection();
                                    setState(() => _isExpanded = !_isExpanded);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _isExpanded ? 'Свернуть' : 'Все 8 сил',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Что я могу 🦉',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Персональный AI-ассистент учителя начальных классов',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Информационная подсказка
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasCustomTopic
                              ? 'Готов помочь с уроком «». Выберите задачу ниже:'
                              : 'Выберите готовый сценарий для урока или нажмите зелёную кнопку:',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Блок суперсил: либо развёрнутый полный список, либо понятная сетка 2x2 без скролла
                if (!widget.isCompact || _isExpanded)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _capabilities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cap = _capabilities[index];
                        return _buildCapabilityCard(context, cap, isDark);
                      },
                    ),
                  )
                else
                  _buildCleanGrid(context, isDark),

                const SizedBox(height: 14),

                // Главная кнопка открытия ассистента
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      TelegramWebAppService().hapticSelection();
                      MetodistAssistantDialog.show(
                        context,
                        currentTopic: widget.currentTopic,
                        currentWorld: widget.currentWorld,
                        currentMethod: widget.currentMethod,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🦉', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'Открыть диалог с Совёнком-Методистом',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Простая, понятная и адаптивная сетка сценариев (без горизонтального скролла)
  Widget _buildCleanGrid(BuildContext context, bool isDark) {
    // 4 ключевых сценария для быстрого запуска
    final quickCards = [
      _capabilities[1], // 💬 В родительский чат
      _capabilities[2], // 📚 3 Уровня домашки
      _capabilities[3], // 🎮 Сюжетная игра-квест
      _capabilities[4], // 📝 Экспресс-тест
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(context, quickCards[0], isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuickActionCard(context, quickCards[1], isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(context, quickCards[2], isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuickActionCard(context, quickCards[3], isDark)),
          ],
        ),
        const SizedBox(height: 10),
        // Кнопка разворачивания остальных возможностей
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            TelegramWebAppService().hapticSelection();
            setState(() => _isExpanded = true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '✨ Ещё 4 суперсилы (Ловушка Незнайки, СанПиН...)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Компактная карточка действия в сетке
  Widget _buildQuickActionCard(
    BuildContext context,
    Map<String, dynamic> cap,
    bool isDark,
  ) {
    final color = cap['color'] as Color;
    final title = cap['title'] as String;
    final tag = cap['tag'] as String;
    final icon = cap['icon'] as String;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _triggerCapability(context, cap['actionPrompt'] as String);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.22 : 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityCard(
    BuildContext context,
    Map<String, dynamic> cap,
    bool isDark,
  ) {
    final color = cap['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(cap['icon'] as String, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cap['title'] as String,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cap['tag'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cap['desc'] as String,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      _triggerCapability(context, cap['actionPrompt'] as String);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Попробовать',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
