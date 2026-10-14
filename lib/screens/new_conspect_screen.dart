import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/method_prompt.dart';
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

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customTopicController = TextEditingController();

  final List<Map<String, String>> _ageGroups = [
    {'id': 'preschool', 'label': '4–6 лет'},
    {'id': 'grade_1', 'label': '1 класс'},
    {'id': 'grade_2', 'label': '2 класс'},
  ];

  final List<String> _preschoolDurations = ['15 мин', '20 мин', '25 мин', '30 мин'];
  final List<String> _schoolDurations = ['35 мин', '40 мин', '45 мин', '60 мин'];

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

    // Available topics for selected method and age group
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
                // Top Glass Card with Form Fields
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
                                  _selectedTopic = null; // reset selected topic
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

                      // 5. Длительность занятия
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

                      // 6. Повторение (необязательное)
                      GlassTextField(
                        controller: _reviewController,
                        label: 'Повторение пройденного (необязательно)',
                        hintText: 'Что нужно кратко вспомнить в начале урока...',
                        prefixIcon: Icons.replay_rounded,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 7. Замечания (многострочное, необязательное)
                      GlassTextField(
                        controller: _notesController,
                        label: 'Замечания и пожелания учителя (необязательно)',
                        hintText: 'Особый темп, акцент на игровые элементы, уровень группы...',
                        prefixIcon: Icons.comment_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 8. Кнопка «Сгенерировать»
                GradientButton(
                  text: 'Сгенерировать',
                  icon: Icons.auto_awesome,
                  onPressed: _onGeneratePressed,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
