import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/lesson_summary_card.dart';
import '../models/scheduled_lesson.dart';
import '../models/thematic_world.dart';
import '../providers/app_provider.dart';
import '../services/assistant_ai_service.dart';
import '../services/pdf_export_service.dart';
import '../services/telegram/telegram_web_app_service.dart';
import '../theme.dart';

class LessonSummaryModal extends StatefulWidget {
  final ScheduledLesson lesson;
  final Function(ScheduledLesson updatedLesson)? onSave;

  const LessonSummaryModal({
    super.key,
    required this.lesson,
    this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required ScheduledLesson lesson,
    Function(ScheduledLesson updatedLesson)? onSave,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: LessonSummaryModal(lesson: lesson, onSave: onSave),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: LessonSummaryModal(lesson: lesson, onSave: onSave),
        ),
      );
    }
  }

  @override
  State<LessonSummaryModal> createState() => _LessonSummaryModalState();
}

class _LessonSummaryModalState extends State<LessonSummaryModal> {
  late Map<String, int> _criteriaScores;
  late Set<String> _selectedTags;
  late List<String> _availableTags;
  late TextEditingController _notesController;
  late String _selectedWorldId;
  late String _selectedHomework;

  String? _aiReflection;
  String? _parentChatMessage;
  bool _isGeneratingAi = false;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    final card = widget.lesson.summaryCard;

    if (card != null) {
      _criteriaScores = Map.from(card.criteriaScores);
      _selectedTags = Set.from(card.tags);
      _availableTags = List.from(LessonSummaryCard.defaultTagsPreset);
      for (final t in card.tags) {
        if (!_availableTags.contains(t)) _availableTags.add(t);
      }
      _notesController = TextEditingController(text: card.teacherNotes);
      _selectedWorldId = card.thematicWorldId;
      _selectedHomework = card.homeworkAssigned;
      _aiReflection = card.aiReflection;
      _parentChatMessage = card.parentChatMessage;
    } else {
      _criteriaScores = Map.from(LessonSummaryCard.defaultCriteria);
      _selectedTags = {
        '⭐ Блестящий ответ у доски',
        '🎯 Полное понимание алгоритма',
      };
      _availableTags = List.from(LessonSummaryCard.defaultTagsPreset);
      _notesController = TextEditingController();
      _selectedWorldId = 'world_space';
      _selectedHomework = 'Уровень 1 (Базовый, ФГОС)';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _currentAverageScore {
    if (_criteriaScores.isEmpty) return 5.0;
    final total = _criteriaScores.values.fold<int>(0, (s, v) => s + v);
    return total / _criteriaScores.length;
  }

  int get _currentMasteryPercent {
    return ((_currentAverageScore / 5.0) * 100).round().clamp(0, 100);
  }

  ThematicWorld get _currentWorld {
    return ThematicWorld.fromId(_selectedWorldId);
  }

  LessonSummaryCard _buildCurrentCard() {
    return LessonSummaryCard(
      id: widget.lesson.summaryCard?.id,
      scheduledLessonId: widget.lesson.id,
      date: widget.lesson.date,
      topic: widget.lesson.topic,
      studentOrClass: widget.lesson.studentOrClass,
      conspectId: widget.lesson.conspectId,
      thematicWorldId: _selectedWorldId,
      criteriaScores: _criteriaScores,
      tags: _selectedTags.toList(),
      teacherNotes: _notesController.text.trim(),
      homeworkAssigned: _selectedHomework,
      aiReflection: _aiReflection,
      parentChatMessage: _parentChatMessage,
      createdAt: widget.lesson.summaryCard?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _generateAiAnalysis() async {
    setState(() => _isGeneratingAi = true);
    TelegramWebAppService().hapticImpact('medium');

    final tempCard = _buildCurrentCard();
    try {
      final res = await AssistantAiService().generateLessonSummaryReflection(
        card: tempCard,
        world: _currentWorld,
      );

      if (mounted) {
        setState(() {
          _aiReflection = res['aiReflection'];
          _parentChatMessage = res['parentChatMessage'];
          _isGeneratingAi = false;
        });
        TelegramWebAppService().hapticNotification('success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAi = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    TelegramWebAppService().hapticImpact('heavy');

    try {
      final card = _buildCurrentCard();
      await PdfExportService.exportLessonSummaryPdf(
        card,
        world: _currentWorld,
      );
      if (mounted) {
        TelegramWebAppService().hapticNotification('success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  void _saveSummary() {
    final updatedCard = _buildCurrentCard();
    final updatedLesson = widget.lesson.copyWith(
      summaryCard: updatedCard,
    );

    context.read<AppProvider>().addScheduledLesson(updatedLesson);
    widget.onSave?.call(updatedLesson);
    TelegramWebAppService().hapticNotification('success');

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Карточка итога урока сохранена!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddCriterionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить свой критерий', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Например: Каллиграфия и осанка',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _criteriaScores[text] = 5;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить свою пометку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Например: Нужна карточка на дом',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  final formatted = text.startsWith('📌') ? text : '📌 $text';
                  if (!_availableTags.contains(formatted)) {
                    _availableTags.add(formatted);
                  }
                  _selectedTags.add(formatted);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: isDesktop ? 760 : double.infinity,
          height: isDesktop ? 750 : MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withOpacity(0.96) : Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _buildKpiCard(isDark),
                    const SizedBox(height: 16),
                    _buildWorldSelector(isDark),
                    const SizedBox(height: 16),
                    _buildCriteriaSection(isDark),
                    const SizedBox(height: 16),
                    _buildTagsSection(isDark),
                    const SizedBox(height: 16),
                    _buildNotesSection(isDark),
                    const SizedBox(height: 16),
                    _buildHomeworkSection(isDark),
                    const SizedBox(height: 16),
                    _buildAiReflectionSection(isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _buildBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('📋', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Карточка итога урока',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)),
                      ),
                      child: const Text(
                        'METODIST PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.lesson.topic} • ${widget.lesson.studentOrClass} (${DateFormat('dd.MM.yyyy').format(widget.lesson.date)})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
    );
  }

  Widget _buildKpiCard(bool isDark) {
    final avg = _currentAverageScore;
    final percent = _currentMasteryPercent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'СРЕДНИЙ БАЛЛ УСВОЕНИЯ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const Text(' / 5.0', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'СТАТУС ПО ФГОС',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildCurrentCard().academicStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Text('🎨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text('Игровой мир:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWorldId,
                isDense: true,
                isExpanded: true,
                items: ThematicWorld.allWorlds.map((w) {
                  return DropdownMenuItem<String>(
                    value: w.id,
                    child: Text('${w.title} (${w.mascotName})', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedWorldId = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Критерии усвоения (1 - 5)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Свой критерий', style: TextStyle(fontSize: 12)),
                onPressed: _showAddCriterionDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._criteriaScores.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (starIdx) {
                      final score = starIdx + 1;
                      final isSelected = entry.value >= score;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _criteriaScores[entry.key] = score;
                          });
                          TelegramWebAppService().hapticSelection();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 22,
                            color: isSelected ? const Color(0xFFF59E0B) : Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 28,
                    alignment: entry.key.length > 20 ? Alignment.centerRight : Alignment.center,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if (_criteriaScores.length > 2)
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _criteriaScores.remove(entry.key);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTagsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Пометки и наблюдения урока',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Своя пометка', style: TextStyle(fontSize: 12)),
                onPressed: _showAddTagDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                selected: isSelected,
                label: Text(tag, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
                selectedColor: const Color(0xFF4F46E5).withOpacity(0.18),
                checkmarkColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF4F46E5) : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  TelegramWebAppService().hapticSelection();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Личные заметки учителя',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Особенности работы ученика, скорость счёта, что повторить на следующем уроке...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkSection(bool isDark) {
    const hwOptions = [
      'Уровень 1 (Базовый, ФГОС)',
      'Уровень 2 (Продвинутый, 10 мин)',
      'Уровень 3 (ТРИЗ-вызов, олимпиадный)',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Назначенное домашнее задание',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hwOptions.map((hw) {
              final isSelected = _selectedHomework == hw;
              return ChoiceChip(
                selected: isSelected,
                label: Text(hw, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
                selectedColor: const Color(0xFF10B981).withOpacity(0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF10B981) : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedHomework = hw);
                    TelegramWebAppService().hapticSelection();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiReflectionSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFFF5F3FF), const Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🦉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-наставник Совёнок (YandexGPT Pro)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Академический анализ урока и сообщение родителям',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isGeneratingAi
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(_isGeneratingAi ? 'Анализ...' : 'Сформировать', style: const TextStyle(fontSize: 12)),
                onPressed: _isGeneratingAi ? null : _generateAiAnalysis,
              ),
            ],
          ),
          if (_aiReflection != null && _aiReflection!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                _aiReflection!,
                style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.grey[200] : Colors.grey[900]),
              ),
            ),
          ],
          if (_parentChatMessage != null && _parentChatMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('💬 Пост для родительского чата:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 12),
                  label: const Text('Скопировать', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _parentChatMessage!));
                    TelegramWebAppService().hapticNotification('success');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пост для родителей скопирован в буфер!')),
                    );
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                _parentChatMessage!,
                style: TextStyle(fontSize: 11.5, height: 1.35, color: isDark ? Colors.grey[200] : Colors.grey[900]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isExportingPdf
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF (Mobbin)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            onPressed: _isExportingPdf ? null : _exportPdf,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Сохранить итог', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            onPressed: _saveSummary,
          ),
        ],
      ),
    );
  }
}
