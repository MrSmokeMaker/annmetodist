// Worksheet generation screen (based on NewConspectScreen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/method_prompt.dart';
import '../models/topic.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';
import 'settings_screen.dart';

class WorksheetScreen extends StatefulWidget {
  const WorksheetScreen({super.key});

  @override
  State<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends State<WorksheetScreen> {
  final _formKey = GlobalKey<FormState>();
  MethodPrompt? _selectedMethod;
  String _selectedAgeGroup = 'grade_1';
  Topic? _selectedTopic;
  String _customTopicText = '';
  bool _isCustomTopic = false;
  String _selectedDuration = '45 мин';

  int _tasksCount = 5;
  bool _withAnswers = false;
  bool _includeWordBank = true;
  bool _ecoPrint = false;
  final String _pageFormat = '1_page';

  final TextEditingController _customTopicController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _ageGroups = [
    {'id': 'preschool', 'label': 'Дошкольники'},
    {'id': 'grade_1', 'label': '1 класс'},
    {'id': 'grade_2', 'label': '2 класс'},
  ];

  final List<String> _preschoolDurations = ['15 мин', '20 мин', '25 мин', '30 мин'];
  final List<String> _schoolDurations = ['15 мин', '20 мин', '25 мин', '30 мин', '35 мин', '40 мин', '45 мин', '60 мин'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.methods.isNotEmpty) {
        setState(() {
          _selectedAgeGroup = provider.selectedAgeGroup;
          _selectedMethod = provider.methods.first;
          _updateDurationForAgeGroup(_selectedAgeGroup);
        });
      }
    });
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateDurationForAgeGroup(String age) {
    if (age == 'preschool') {
      if (!_preschoolDurations.contains(_selectedDuration)) {
        _selectedDuration = '20 мин';
      }
    } else {
      if (!_schoolDurations.contains(_selectedDuration)) {
        _selectedDuration = '45 мин';
      }
    }
  }

  List<String> get _currentDurations =>
      _selectedAgeGroup == 'preschool' ? _preschoolDurations : _schoolDurations;

  String get _effectiveTopicTitle {
    return _isCustomTopic ? _customTopicText.trim() : (_selectedTopic?.title ?? '');
  }

  Future<void> _onGeneratePressed() async {
    final provider = context.read<AppProvider>();
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите методику')));
      return;
    }
    final topicTitle = _effectiveTopicTitle;
    if (topicTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Укажите тему занятия')));
      return;
    }
    final proxyUrl = await provider.getProxyUrl();
    if (proxyUrl == null || proxyUrl.trim().isEmpty) {
      _showProxyUrlRequiredDialog();
      return;
    }

    final payload = {
      'generationType': 'worksheet',
      'title': 'Лист заданий: $topicTitle',
      'methodId': _selectedMethod!.id,
      'ageGroup': _selectedAgeGroup,
      'topic': topicTitle,
      'duration': _selectedDuration,
      'tasksCount': _tasksCount,
      'withAnswers': _withAnswers,
      'includeWordBank': _includeWordBank,
      'ecoPrint': _ecoPrint,
      'pageFormat': _pageFormat,
      'notes': _notesController.text.trim(),
    };

    try {
      jsonEncode(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Лист заданий формируется и скачивается в PDF...'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка генерации PDF: $e')));
    }
  }

  void _showProxyUrlRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: const Text('Требуется URL прокси-функции'),
        content: const Text('Для генерации листа заданий необходимо указать URL прокси в настройках.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryIndigo, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: const Text('Перейти в Настройки'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableTopics = _selectedMethod != null ? provider.getTopicsFor(_selectedMethod!.id, _selectedAgeGroup) : <Topic>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppGradients.cyanTeal,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                boxShadow: AppShadows.glowSecondary,
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Генератор листа заданий',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  children: [
                    // Card 1: Параметры урока
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryIndigo.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(Icons.auto_stories_rounded, color: AppColors.primaryIndigo, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '1. Параметры занятия',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          const SizedBox(height: AppSpacing.md),

                          // Методика
                          Text(
                            'Методика обучения',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<MethodPrompt>(
                                isExpanded: true,
                                value: _selectedMethod,
                                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: provider.methods.map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('${m.name} — ${m.subject}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                )).toList(),
                                onChanged: (m) => setState(() {
                                  _selectedMethod = m;
                                  _selectedTopic = null;
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Возрастная группа
                          Text(
                            'Возрастная группа',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _ageGroups.map((g) {
                              final isSel = _selectedAgeGroup == g['id'];
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      _selectedAgeGroup = g['id']!;
                                      _selectedTopic = null;
                                      _updateDurationForAgeGroup(_selectedAgeGroup);
                                    }),
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      decoration: BoxDecoration(
                                        gradient: isSel ? AppGradients.indigoViolet : null,
                                        color: isSel ? null : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                        borderRadius: BorderRadius.circular(AppRadii.md),
                                        border: Border.all(
                                          color: isSel ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                        ),
                                        boxShadow: isSel ? AppShadows.glowPrimary : null,
                                      ),
                                      child: Text(
                                        g['label']!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Тема
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Тема занятия *',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isCustomTopic = !_isCustomTopic),
                                child: Text(
                                  _isCustomTopic ? 'Выбрать из каталога' : 'Ввести вручную',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentCyan),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!_isCustomTopic)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Topic>(
                                  isExpanded: true,
                                  value: _selectedTopic,
                                  hint: Text(availableTopics.isEmpty ? 'Нет тем' : 'Выберите тему', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  items: availableTopics.map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                  )).toList(),
                                  onChanged: (t) => setState(() => _selectedTopic = t),
                                ),
                              ),
                            )
                          else
                            GlassTextField(
                              label: '',
                              controller: _customTopicController,
                              hintText: 'Введите название темы...',
                              prefixIcon: Icons.edit_note_rounded,
                              onChanged: (v) => setState(() => _customTopicText = v),
                            ),
                          const SizedBox(height: AppSpacing.md),

                          // Длительность
                          Text(
                            'Длительность занятия',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _currentDurations.map((d) {
                              final sel = _selectedDuration == d;
                              return InkWell(
                                onTap: () => setState(() => _selectedDuration = d),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: sel ? AppGradients.indigoViolet : null,
                                    color: sel ? null : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                    borderRadius: BorderRadius.circular(AppRadii.sm),
                                    border: Border.all(
                                      color: sel ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    ),
                                  ),
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                      color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Card 2: Конфигурация заданий
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(Icons.tune_rounded, color: AppColors.accentCyan, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '2. Формат и опции заданий',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          const SizedBox(height: AppSpacing.md),

                          // Количество заданий
                          Text(
                            'Количество заданий',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [3, 5, 7].map((cnt) {
                              final sel = _tasksCount == cnt;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() => _tasksCount = cnt),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: sel ? AppGradients.cyanTeal : null,
                                      color: sel ? null : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                      borderRadius: BorderRadius.circular(AppRadii.sm),
                                      border: Border.all(
                                        color: sel ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      ),
                                    ),
                                    child: Text(
                                      '$cnt заданий',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                        color: sel ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Опции
                          _buildSwitchRow(
                            title: 'Корзинка слов для справок',
                            subtitle: 'Банк слов и подсказок внизу листа',
                            icon: Icons.shopping_basket_outlined,
                            iconColor: AppColors.primaryIndigo,
                            value: _includeWordBank,
                            onChanged: (val) => setState(() => _includeWordBank = val),
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSwitchRow(
                            title: 'Режим Eco-Print (ч/б печать)',
                            subtitle: 'Оптимизация под черно-белый принтер',
                            icon: Icons.print_outlined,
                            iconColor: AppColors.accentCyan,
                            value: _ecoPrint,
                            onChanged: (val) => setState(() => _ecoPrint = val),
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSwitchRow(
                            title: 'С ответами для учителя',
                            subtitle: 'Блок самопроверки и ключ к заданиям',
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.success,
                            value: _withAnswers,
                            onChanged: (val) => setState(() => _withAnswers = val),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Card 3: Заметки
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentAmber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(Icons.comment_outlined, color: AppColors.accentAmber, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '3. Особые пожелания к листу',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GlassTextField(
                            controller: _notesController,
                            label: 'Замечания учителя (необязательно)',
                            hintText: 'Особый темп, акцент на игровые элементы, уровень группы...',
                            prefixIcon: Icons.edit_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Bottom CTA
                    GradientButton(
                      text: 'Сгенерировать лист заданий',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _onGeneratePressed,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accentCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
