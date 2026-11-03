import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/method_prompt.dart';
import '../models/quarter_plan.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_bell_button.dart';
import 'calendar_screen.dart';

class QuarterPlanningScreen extends StatefulWidget {
  const QuarterPlanningScreen({super.key});

  @override
  State<QuarterPlanningScreen> createState() => _QuarterPlanningScreenState();
}

class _QuarterPlanningScreenState extends State<QuarterPlanningScreen> {
  int _selectedQuarter = 1;
  int _lessonsCount = 8;
  String _selectedAgeGroup = '1 класс';
  MethodPrompt? _selectedMethod;
  bool _useAiTopics = true;
  bool _isGeneratingBatch = false;
  int _currentGeneratingIndex = 0;

  final List<String> _ageGroups = ['Дошкольники', '1 класс', '2 класс'];
  final List<int> _lessonCounts = [8, 12, 16];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.methods.isNotEmpty && _selectedMethod == null) {
        setState(() {
          _selectedMethod = provider.methods.first;
        });
      }
    });
  }

  Future<void> _generateTopicsList() async {
    if (_selectedMethod == null) return;
    final provider = context.read<AppProvider>();

    try {
      await provider.startQuarterPlanning(
        method: _selectedMethod!,
        ageGroup: _selectedAgeGroup,
        quarterNumber: _selectedQuarter,
        lessonsCount: _lessonsCount,
        useAi: _useAiTopics,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка формирования тем: $e')),
      );
    }
  }

  Future<void> _replaceTopic(int index) async {
    final provider = context.read<AppProvider>();
    final TextEditingController hintController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Замена урока ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ИИ подберёт альтернативную тему, логически связывающую программу.'),
            const SizedBox(height: 12),
            TextField(
              controller: hintController,
              decoration: const InputDecoration(
                labelText: 'Пожелание к теме (необязательно)',
                hintText: 'например, больше задач на движение',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Заменить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.replaceQuarterTopic(
        index,
        hint: hintController.text.trim().isNotEmpty ? hintController.text.trim() : null,
      );
    }
  }

  void _editTopicManually(int index, String currentTitle) {
    final provider = context.read<AppProvider>();
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Редактировать тему урока ${index + 1}'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Формулировка темы',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateQuarterTopicTitle(index, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuarterGeneration(QuarterPlan plan) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _isGeneratingBatch = true;
      _currentGeneratingIndex = 0;
    });

    try {
      await provider.runQuarterBatchGeneration(
        plan,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _currentGeneratingIndex = current;
            });
          }
        },
      );

      if (!mounted) return;
      _showCalendarDistributionDialog(provider.activeQuarterPlan ?? plan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сбой пакетной генерации: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingBatch = false;
        });
      }
    }
  }

  void _showCalendarDistributionDialog(QuarterPlan plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime startDate = DateTime.now();
    final Set<int> selectedWeekdays = {DateTime.monday, DateTime.wednesday, DateTime.friday};
    final classController = TextEditingController(text: '1-А класс');
    final timeController = TextEditingController(text: '09:00');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppGradients.indigoViolet,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.event_available, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Раскидать в календаре?', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Все ${plan.topics.length} уроков четверти готовы! Выберите дни недели, и они автоматически займут свои даты в расписании.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Text('Дни занятий в неделю:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final entry in [
                      (DateTime.monday, 'Пн'),
                      (DateTime.tuesday, 'Вт'),
                      (DateTime.wednesday, 'Ср'),
                      (DateTime.thursday, 'Чт'),
                      (DateTime.friday, 'Пт'),
                      (DateTime.saturday, 'Сб'),
                    ])
                      FilterChip(
                        label: Text(entry.$2),
                        selected: selectedWeekdays.contains(entry.$1),
                        selectedColor: AppColors.primaryIndigo.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryIndigo,
                        onSelected: (selected) {
                          setDlgState(() {
                            if (selected) {
                              selectedWeekdays.add(entry.$1);
                            } else if (selectedWeekdays.length > 1) {
                              selectedWeekdays.remove(entry.$1);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Класс / Ученик',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: timeController,
                        decoration: const InputDecoration(
                          labelText: 'Время',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Старт: ${DateFormat('dd.MM.yyyy').format(startDate)}', style: const TextStyle(fontSize: 12)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Сменить', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDlgState(() {
                            startDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Позже'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              onPressed: () async {
                final provider = context.read<AppProvider>();
                await provider.distributeQuarterInCalendar(
                  plan,
                  startDate: startDate,
                  weekdays: selectedWeekdays.toList(),
                  time: timeController.text.trim().isNotEmpty ? timeController.text.trim() : '09:00',
                  studentClass: classController.text.trim().isNotEmpty ? classController.text.trim() : 'Класс',
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              child: const Text('Назначить в календарь'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activePlan = provider.activeQuarterPlan;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('План на четверть (КТП)'),
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildConfigCard(provider),
              const SizedBox(height: 16),
              if (activePlan != null) ...[
                _buildPlanHeader(activePlan),
                const SizedBox(height: 12),
                _buildTopicsList(activePlan),
                const SizedBox(height: 16),
                _buildActionButtons(activePlan),
              ] else ...[
                _buildEmptyState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(AppProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppGradients.indigoViolet,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Параметры четверти', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          // Выбор четверти (1, 2, 3, 4)
          Row(
            children: [
              const Text('Четверть:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              for (int q = 1; q <= 4; q++) ...[
                ChoiceChip(
                  label: Text('$q'),
                  selected: _selectedQuarter == q,
                  selectedColor: AppColors.primaryIndigo,
                  labelStyle: TextStyle(
                    color: _selectedQuarter == q ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedQuarter = q);
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Методика
          DropdownButtonFormField<MethodPrompt>(
            value: _selectedMethod,
            decoration: const InputDecoration(
              labelText: 'Методика и предмет',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: provider.methods.map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text('${m.name} (${m.subject})', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedMethod = val),
          ),
          const SizedBox(height: 12),
          // Возраст и кол-во уроков
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAgeGroup,
                  decoration: const InputDecoration(
                    labelText: 'Возраст',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _ageGroups.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) => setState(() => _selectedAgeGroup = val ?? _selectedAgeGroup),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _lessonsCount,
                  decoration: const InputDecoration(
                    labelText: 'Уроков',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _lessonCounts.map((c) => DropdownMenuItem(value: c, child: Text('$c уроков'))).toList(),
                  onChanged: (val) => setState(() => _lessonsCount = val ?? _lessonsCount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              icon: provider.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(provider.isLoading ? 'Формирование тем...' : 'Сформировать темы четверти'),
              onPressed: provider.isLoading ? null : _generateTopicsList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(QuarterPlan plan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.quarterNumber} четверть • ${plan.subject}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Готово ${plan.completedLessons} из ${plan.totalLessons} уроков',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        if (plan.progress > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: plan.progress == 1.0 ? Colors.green.withOpacity(0.15) : AppColors.primaryIndigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(plan.progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: plan.progress == 1.0 ? Colors.green : AppColors.primaryIndigo,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopicsList(QuarterPlan plan) {
    return Column(
      children: [
        for (int i = 0; i < plan.topics.length; i++) ...[
          _buildTopicCard(plan.topics[i], i, plan),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildTopicCard(QuarterTopicItem item, int index, QuarterPlan plan) {
    Color borderColor = Colors.grey.withOpacity(0.3);
    Widget statusBadge;

    switch (item.status) {
      case QuarterTopicStatus.completed:
        borderColor = Colors.green;
        statusBadge = const Chip(
          avatar: Icon(Icons.check_circle, size: 14, color: Colors.white),
          label: Text('Готов', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        break;
      case QuarterTopicStatus.generating:
        borderColor = AppColors.primaryIndigo;
        statusBadge = const Chip(
          avatar: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          label: Text('Генерация', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryIndigo,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        break;
      case QuarterTopicStatus.failed:
        borderColor = Colors.redAccent;
        statusBadge = const Chip(
          avatar: Icon(Icons.error_outline, size: 14, color: Colors.white),
          label: Text('Ошибка', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        break;
      case QuarterTopicStatus.pending:
      default:
        statusBadge = Chip(
          label: const Text('В очереди', style: TextStyle(fontSize: 10)),
          backgroundColor: Colors.grey.withOpacity(0.2),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        break;
    }

    return GlassCard(
      borderRadius: AppRadii.md,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 3)),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryIndigo.withOpacity(0.15),
              child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statusBadge,
                      if (!_isGeneratingBatch && item.status != QuarterTopicStatus.completed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Заменить тему через ИИ',
                              icon: const Icon(Icons.sync, size: 18),
                              onPressed: () => _replaceTopic(index),
                            ),
                            IconButton(
                              tooltip: 'Редактировать тему вручную',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editTopicManually(index, item.title),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (item.scheduledDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📅 Дата в календаре: ${DateFormat('dd.MM.yyyy').format(item.scheduledDate!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.indigoAccent),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(QuarterPlan plan) {
    if (_isGeneratingBatch) {
      return GlassCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Идёт пакетная генерация четверти...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('$_currentGeneratingIndex / ${plan.topics.length}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: plan.topics.isEmpty ? 0 : _currentGeneratingIndex / plan.topics.length,
              color: AppColors.primaryIndigo,
            ),
          ],
        ),
      );
    }

    final allCompleted = plan.completedLessons == plan.totalLessons && plan.totalLessons > 0;

    return Column(
      children: [
        if (!allCompleted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Сгенерировать все уроки четверти (${plan.totalLessons - plan.completedLessons})'),
              onPressed: () => _startQuarterGeneration(plan),
            ),
          ),
        if (allCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              icon: const Icon(Icons.event_available),
              label: const Text('Раскидать темы в календаре'),
              onPressed: () => _showCalendarDistributionDialog(plan),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('Открыть календарь занятий'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.auto_stories_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Выберите четверть и нажмите\n"Сформировать темы четверти"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
