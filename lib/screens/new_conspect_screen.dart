import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_technique.dart';
import '../models/method_prompt.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';
import 'conspect_view_screen.dart';
import 'settings_screen.dart';

class NewConspectScreen extends StatefulWidget {
  const NewConspectScreen({super.key});

  @override
  State<NewConspectScreen> createState() => _NewConspectScreenState();
}

class _NewConspectScreenState extends State<NewConspectScreen> {
  final _formKey = GlobalKey<FormState>();

  MethodPrompt? _selectedMethod;
  String _selectedAgeGroup = 'grade_1'; // default: 1 класс
  Topic? _selectedTopic;
  String _customTopicText = '';
  bool _isCustomTopic = false;
  String _selectedDuration = '45 мин';

  // Шаг 1: Шаблоны ситуаций и библиотека приёмов
  SituationTemplate? _selectedSituation;
  final Set<String> _selectedActivities = {};

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customTopicController = TextEditingController();

  final List<Map<String, String>> _ageGroups = [
    {'id': 'preschool', 'label': '4–6 лет'},
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
          _selectedMethod = provider.methods.first;
          _updateDurationForAgeGroup(_selectedAgeGroup);
        });
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _notesController.dispose();
    _customTopicController.dispose();
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
    if (_isCustomTopic) {
      return _customTopicText.trim();
    }
    return _selectedTopic?.title ?? '';
  }

  IconData _getActivityIcon(String category) {
    switch (category) {
      case 'Разминка':
        return Icons.pan_tool_outlined;
      case 'Чистописание':
        return Icons.edit_outlined;
      case 'Грамота и звуки':
        return Icons.record_voice_over_outlined;
      case 'Нейромоторика':
        return Icons.psychology_outlined;
      case 'Математика':
        return Icons.calculate_outlined;
      case 'Обучение чтению':
        return Icons.auto_stories_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Future<void> _onGeneratePressed() async {
    final provider = context.read<AppProvider>();

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите методику.')),
      );
      return;
    }

    final topicTitle = _effectiveTopicTitle;
    if (topicTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите или введите тему занятия.')),
      );
      return;
    }

    // Check API Key
    final apiKey = await provider.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      if (!mounted) return;
      _showApiKeyRequiredDialog();
      return;
    }

    final selectedTechniques = _selectedActivities
        .map((id) => provider.activityLibrary.firstWhere((a) => a.id == id))
        .toList();

    // Navigate to ConspectViewScreen with generation parameters
    if (!mounted) return;
    Navigator.of(context).push(
      FadeSlidePageRoute(
        page: ConspectViewScreen(
          method: _selectedMethod!,
          ageGroup: _selectedAgeGroup,
          topicTitle: topicTitle,
          duration: _selectedDuration,
          review: _reviewController.text.trim(),
          notes: _notesController.text.trim(),
          situation: _selectedSituation,
          activities: selectedTechniques,
          isNewGeneration: true,
        ),
      ),
    );
  }

  void _showApiKeyRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text('Требуется API-ключ YandexGPT'),
        content: const Text(
          'Для генерации конспекта необходимо указать API-ключ YandexGPT (Яндекс Облако) в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const SettingsScreen()),
              );
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

    final availableTopics = _selectedMethod != null
        ? provider.getTopicsFor(_selectedMethod!.id, _selectedAgeGroup)
        : <Topic>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Новый конспект',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                // Top Glass Card with Core Form Fields
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  borderRadius: AppRadii.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Методика
                      Text(
                        'Методика обучения',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<MethodPrompt>(
                            isExpanded: true,
                            value: _selectedMethod,
                            dropdownColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: provider.methods.map((method) {
                              return DropdownMenuItem<MethodPrompt>(
                                value: method,
                                child: Text(
                                  '${method.name} — ${method.subject}',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (method) {
                              if (method != null) {
                                setState(() {
                                  _selectedMethod = method;
                                  _selectedTopic = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 2. Предмет (автоматически)
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 16,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Предмет: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppGradients.cyanBlue,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              _selectedMethod?.subject ?? 'Русский язык',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 3. Класс / Возраст
                      Text(
                        'Возрастная группа / Класс',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _ageGroups.map((group) {
                          final isSelected = _selectedAgeGroup == group['id'];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedAgeGroup = group['id']!;
                                    _selectedTopic = null;
                                    _updateDurationForAgeGroup(_selectedAgeGroup);
                                  });
                                },
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? AppGradients.indigoViolet
                                        : null,
                                    color: isSelected
                                        ? null
                                        : (isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : Colors.black.withOpacity(0.04)),
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black.withOpacity(0.08)),
                                    ),
                                  ),
                                  child: Text(
                                    group['label']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 4. Тема
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Тема занятия *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCustomTopic = !_isCustomTopic;
                              });
                            },
                            child: Text(
                              _isCustomTopic ? 'Выбрать из каталога' : 'Ввести вручную',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (!_isCustomTopic) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Topic>(
                              isExpanded: true,
                              value: _selectedTopic,
                              hint: Text(
                                availableTopics.isEmpty
                                    ? 'Нет готовых тем для этой методики'
                                    : 'Выберите тему из списка',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              dropdownColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              items: availableTopics.map((topic) {
                                return DropdownMenuItem<Topic>(
                                  value: topic,
                                  child: Text(
                                    topic.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (topic) {
                                setState(() {
                                  _selectedTopic = topic;
                                });
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        GlassTextField(
                          label: '',
                          controller: _customTopicController,
                          hintText: 'Введите название темы...',
                          prefixIcon: Icons.edit_note_rounded,
                          onChanged: (val) {
                            setState(() {
                              _customTopicText = val;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // 5. Шаг 1: Выпадающий список «Ситуация»
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryIndigo),
                          const SizedBox(width: 6),
                          Text(
                            'Ситуация урока (шаблон)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SituationTemplate?>(
                            isExpanded: true,
                            value: _selectedSituation,
                            hint: Text(
                              'Обычное занятие (без особых условий)',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            dropdownColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            items: [
                              const DropdownMenuItem<SituationTemplate?>(
                                value: null,
                                child: Text('Стандартное занятие (без ограничений)'),
                              ),
                              ...provider.situationTemplates.map((sit) {
                                return DropdownMenuItem<SituationTemplate?>(
                                  value: sit,
                                  child: Row(
                                    children: [
                                      Text(
                                        sit.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryIndigo.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sit.autoDuration,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryIndigo,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (situation) {
                              setState(() {
                                _selectedSituation = situation;
                                if (situation != null && situation.autoDuration.isNotEmpty) {
                                  _selectedDuration = situation.autoDuration;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      if (_selectedSituation != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _selectedSituation!.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cyan,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // 6. Длительность занятия
                      Text(
                        'Длительность занятия',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currentDurations.map((duration) {
                          final isSelected = _selectedDuration == duration;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDuration = duration;
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppGradients.indigoViolet : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.08)),
                                ),
                              ),
                              child: Text(
                                duration,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 7. Повторение (необязательное)
                      GlassTextField(
                        controller: _reviewController,
                        label: 'Повторение пройденного (необязательно)',
                        hintText: 'Что нужно кратко вспомнить в начале урока...',
                        prefixIcon: Icons.replay_rounded,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 8. Замечания (многострочное, необязательное)
                      GlassTextField(
                        controller: _notesController,
                        label: 'Замечания и пожелания учителя (необязательно)',
                        hintText: 'Особый темп, акцент на игровые элементы, уровень группы...',
                        prefixIcon: Icons.comment_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Шаг 1: Секция «Добавить приёмы» (activity_library)
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  borderRadius: AppRadii.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.indigoViolet,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Библиотека приёмов',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          if (_selectedActivities.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppGradients.cyanBlue,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Text(
                                'Выбрано: ${_selectedActivities.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Выберите карточки техник — YandexGPT гармонично встроит их сценарий в ход урока',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Сетка карточек приёмов (GridView 2 столбца)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.activityLibrary.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.45,
                        ),
                        itemBuilder: (context, index) {
                          final activity = provider.activityLibrary[index];
                          final isSelected = _selectedActivities.contains(activity.id);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedActivities.remove(activity.id);
                                } else {
                                  _selectedActivities.add(activity.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryIndigo.withOpacity(isDark ? 0.22 : 0.12)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.white.withOpacity(0.65)),
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryIndigo
                                      : (isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.08)),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryIndigo
                                              : (isDark
                                                  ? Colors.white.withOpacity(0.08)
                                                  : Colors.black.withOpacity(0.06)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          _getActivityIcon(activity.category),
                                          size: 15,
                                          color: isSelected ? Colors.white : AppColors.cyan,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: AppColors.primaryIndigo,
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        activity.shortDescription,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          height: 1.25,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Кнопка «Сгенерировать»
                GradientButton(
                  text: 'Сгенерировать',
                  icon: Icons.auto_awesome,
                  onPressed: _onGeneratePressed,
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
