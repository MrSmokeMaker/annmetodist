// Worksheet generation screen (based on NewConspectScreen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:js' as js;

import '../models/activity_technique.dart';
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
  const WorksheetScreen({Key? key}) : super(key: key);

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

  // New fields for worksheet
  int _tasksCount = 5; // default 5
  bool _withAnswers = false;

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

    // Build request payload
    final payload = {
      'generationType': 'worksheet',
      'title': 'Лист заданий: $topicTitle',
      'methodId': _selectedMethod!.id,
      'ageGroup': _selectedAgeGroup,
      'topic': topicTitle,
      'duration': _selectedDuration,
      'tasksCount': _tasksCount,
      'withAnswers': _withAnswers,
      'notes': _notesController.text.trim(),
    };

    // Call JS to generate PDF (pdfmake helper expected on window)
    try {
      final jsonStr = jsonEncode(payload);
      js.context.callMethod('createWorksheetPdf', [jsonStr]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Лист заданий формируется и скачивается в PDF...'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
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
      appBar: AppBar(
        title: const Text('Лист заданий'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                // Методика
                Text('Методика обучения', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MethodPrompt>(
                      isExpanded: true,
                      value: _selectedMethod,
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: provider.methods.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} — ${m.subject}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)))).toList(),
                      onChanged: (m) => setState(() { _selectedMethod = m; _selectedTopic = null; }),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Возрастная группа
                Text('Возрастная группа', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Row(
                  children: _ageGroups.map((g) {
                    final isSel = _selectedAgeGroup == g['id'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => setState(() { _selectedAgeGroup = g['id']!; _selectedTopic = null; _updateDurationForAgeGroup(_selectedAgeGroup); }),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSel ? AppGradients.indigoViolet : null,
                              color: isSel ? null : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(color: isSel ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                            ),
                            child: Text(g['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal, color: isSel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Тема
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Тема занятия *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    GestureDetector(
                      onTap: () => setState(() => _isCustomTopic = !_isCustomTopic),
                      child: Text(_isCustomTopic ? 'Выбрать из каталога' : 'Ввести вручную', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryIndigo)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_isCustomTopic)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Topic>(
                        isExpanded: true,
                        value: _selectedTopic,
                        hint: Text(availableTopics.isEmpty ? 'Нет тем' : 'Выберите тему', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        items: availableTopics.map((t) => DropdownMenuItem(value: t, child: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)))).toList(),
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
                const SizedBox(height: AppSpacing.lg),
                // Длительность
                Text('Длительность занятия', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
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
                          color: sel ? null : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                        ),
                        child: Text(d, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Количество заданий
                Text('Количество заданий', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [3, 5, 7].map((cnt) {
                    final sel = _tasksCount == cnt;
                    return ChoiceChip(
                      label: Text('$cnt'),
                      selected: sel,
                      onSelected: (_) => setState(() => _tasksCount = cnt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // С ответами для учителя
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('С ответами для учителя', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    Switch(value: _withAnswers, onChanged: (val) => setState(() => _withAnswers = val)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Замечания (optional)
                GlassTextField(
                  controller: _notesController,
                  label: 'Замечания и пожелания учителя (необязательно)',
                  hintText: 'Особый темп, акцент на игровые элементы, уровень группы...',
                  prefixIcon: Icons.comment_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                GradientButton(
                  text: 'Сгенерировать лист',
                  onPressed: _onGeneratePressed,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
