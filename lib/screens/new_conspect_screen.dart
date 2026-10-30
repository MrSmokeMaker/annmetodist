import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/activity_technique.dart';
import '../models/method_prompt.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';
import 'conspect_view_screen.dart';
import 'settings_screen.dart';

class NewConspectScreen extends StatefulWidget {
  final Set<GenerationType> selectedMaterials;
  final String? initialTopic;
  final String? initialAgeGroup;
  final String? initialMethodId;

  const NewConspectScreen({
    super.key,
    this.selectedMaterials = const {GenerationType.conspect},
    this.initialTopic,
    this.initialAgeGroup,
    this.initialMethodId,
  });

  @override
  State<NewConspectScreen> createState() => _NewConspectScreenState();
}

class _NewConspectScreenState extends State<NewConspectScreen> {
  final _formKey = GlobalKey<FormState>();

  MethodPrompt? _selectedMethod;
  String _selectedAgeGroup = 'grade_1';
  Topic? _selectedTopic;
  String _customTopicText = '';
  bool _isCustomTopic = false;
  String _selectedDuration = '45 мин';

  // Шаблоны ситуаций и библиотека приёмов
  SituationTemplate? _selectedSituation;
  final Set<String> _selectedActivities = {};

  // Пакетная генерация вариантов
  int _variantsCount = 1;

  // Выбор генерируемых материалов
  late Set<GenerationType> _selectedMaterials;

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customTopicController = TextEditingController();

  final List<Map<String, String>> _ageGroups = [
    {'id': 'preschool', 'label': 'Дошкольники'},
    {'id': 'grade_1', 'label': '1 класс'},
    {'id': 'grade_2', 'label': '2 класс'},
  ];

  final List<String> _preschoolDurations = ['15 мин', '20 мин', '25 мин', '30 мин'];
  final List<String> _schoolDurations = ['15 мин', '20 мин', '25 мин', '30 мин', '35 мин', '40 мин', '45 мин', '60 мин'];

  bool _hasFilledFields() {
    return _customTopicController.text.trim().isNotEmpty ||
        _reviewController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _selectedTopic != null ||
        _selectedSituation != null ||
        _selectedActivities.isNotEmpty;
  }

  String _getGenerateButtonText() {
    final selectedCount = _selectedMaterials.length;
    if (selectedCount == 1) {
      final material = _selectedMaterials.first;
      return 'Создать ${material.label}';
    } else if (selectedCount == GenerationType.values.length) {
      return _variantsCount == 3
          ? 'Создать 3 варианта (всё)'
          : 'Создать все материалы';
    } else {
      return _variantsCount == 3
          ? 'Создать 3 варианта (${_selectedMaterials.length})'
          : 'Создать материалы (${_selectedMaterials.length})';
    }
  }

  Future<bool> _showDiscardConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text('Сбросить форму?'),
        content: const Text(
          'Введённые данные не сохранятся. Вы действительно хотите вернуться назад?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _selectedMaterials = Set<GenerationType>.from(widget.selectedMaterials);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.methods.isNotEmpty) {
        setState(() {
          _selectedAgeGroup = widget.initialAgeGroup ?? provider.selectedAgeGroup;
          if (widget.initialMethodId != null) {
            _selectedMethod = provider.methods.firstWhere(
              (m) => m.id == widget.initialMethodId,
              orElse: () => provider.methods.first,
            );
          } else {
            _selectedMethod = provider.methods.first;
          }
          if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
            _isCustomTopic = true;
            _customTopicText = widget.initialTopic!;
            _customTopicController.text = widget.initialTopic!;
          }
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

    final proxyUrl = await provider.getProxyUrl();
    if (proxyUrl == null || proxyUrl.trim().isEmpty) {
      if (!mounted) return;
      _showProxyUrlRequiredDialog();
      return;
    }

    final List<ActivityTechnique> selectedTechniques = _selectedActivities
        .map((id) => provider.activityLibrary.firstWhere((a) => a.id == id))
        .toList();

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
          variantsCount: _variantsCount,
          materials: _selectedMaterials,
          isNewGeneration: true,
        ),
      ),
    );
  }

  void _showProxyUrlRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text('Требуется URL прокси-функции'),
        content: const Text(
          'Для генерации конспекта необходимо указать URL прокси-функции Yandex Cloud в настройках приложения.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final availableTopics = _selectedMethod != null
        ? provider.getTopicsFor(_selectedMethod!.id, _selectedAgeGroup)
        : <Topic>[];

    return PopScope(
      canPop: !_hasFilledFields(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardConfirmDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _onGeneratePressed,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _onGeneratePressed,
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Назад',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () async {
                if (_hasFilledFields()) {
                  final shouldPop = await _showDiscardConfirmDialog();
                  if (shouldPop && context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: const Text(
              'Конструктор занятия',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Настройки',
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    FadeSlidePageRoute(page: const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: AmbientBackground(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Stack(
                      children: [
                        // Main Scrollable Form Content
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            100, // Padding for sticky bottom CTA
                          ),
                          children: [
                            // Card 1: Core Parameters
                            _buildCoreParametersCard(context, provider, availableTopics, isDark),

                            const SizedBox(height: AppSpacing.md),

                            // Card 2: Activity Techniques Library
                            _buildActivityLibraryCard(context, provider, isDesktop, isDark),

                            const SizedBox(height: AppSpacing.md),

                            // Card 3: Material Generation Options
                            _buildMaterialsAndVariantsCard(isDark),

                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),

                        // Floating Glass Action Bar at the Bottom
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: 12,
                          child: _buildFloatingBottomBar(isDesktop, isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoreParametersCard(
    BuildContext context,
    AppProvider provider,
    List<Topic> availableTopics,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadii.xl,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '1. Параметры урока',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                ],
              ),
              if (_selectedMethod != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.cyanBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _selectedMethod!.subject,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 1. Методика
          Text(
            'Методика обучения',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x18FFFFFF) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MethodPrompt>(
                isExpanded: true,
                value: _selectedMethod,
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: provider.methods.map((method) {
                  return DropdownMenuItem<MethodPrompt>(
                    value: method,
                    child: Text(
                      '${method.name} — ${method.subject}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

          // 2. Возрастная группа
          Text(
            'Возрастная группа',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
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
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.indigoViolet : null,
                        color: isSelected
                            ? null
                            : (isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04)),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                        ),
                        boxShadow: isSelected ? AppShadows.glowPrimary : null,
                      ),
                      child: Text(
                        group['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // 3. Тема занятия
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Тема занятия *',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isCustomTopic = !_isCustomTopic),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    _isCustomTopic ? 'Выбрать из каталога' : 'Ввести вручную',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryIndigo,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (!_isCustomTopic) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x18FFFFFF) : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Topic>(
                  isExpanded: true,
                  value: _selectedTopic,
                  hint: Text(
                    availableTopics.isEmpty
                        ? 'Нет готовых тем для этой методики'
                        : 'Выберите тему из каталога...',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (topic) => setState(() => _selectedTopic = topic),
                ),
              ),
            ),
          ] else ...[
            GlassTextField(
              label: '',
              controller: _customTopicController,
              hintText: 'Введите название темы (например: Сложение с переходом через десяток)...',
              prefixIcon: Icons.edit_note_rounded,
              onChanged: (val) => setState(() => _customTopicText = val),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // 4. Длительность занятия
          Text(
            'Длительность занятия',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _currentDurations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return InkWell(
                onTap: () => setState(() => _selectedDuration = duration),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.indigoViolet : null,
                    color: isSelected
                        ? null
                        : (isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // 5. Ситуация урока (шаблон условий)
          Text(
            'Особая ситуация урока (опционально)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x18FFFFFF) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SituationTemplate?>(
                isExpanded: true,
                value: _selectedSituation,
                hint: Text(
                  'Стандартное занятие (без ограничений)',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                              fontSize: 13.5,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _buildActivityLibraryCard(
    BuildContext context,
    AppProvider provider,
    bool isDesktop,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadii.xl,
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
                      gradient: AppGradients.cyanBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '2. Библиотека приёмов',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                ],
              ),
              if (_selectedActivities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.indigoViolet,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Выбрано: ${_selectedActivities.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Выберите карточки техник — YandexGPT гармонично встроит их сценарий в ход урока',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Сетка карточек приёмов
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.activityLibrary.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isDesktop ? 1.4 : 1.15,
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
                        : (isDark ? const Color(0x14FFFFFF) : Colors.white.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryIndigo
                          : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected ? AppShadows.glowPrimary : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryIndigo
                                  : (isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getActivityIcon(activity.category),
                              size: 14,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              height: 1.2,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.2,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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

          const SizedBox(height: AppSpacing.md),

          // Повторение & Пожелания
          GlassTextField(
            controller: _reviewController,
            label: 'Повторение пройденного (необязательно)',
            hintText: 'Что кратко вспомнить в начале занятия...',
            prefixIcon: Icons.replay_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassTextField(
            controller: _notesController,
            label: 'Замечания и пожелания учителя (необязательно)',
            hintText: 'Темп, специфика класса, акцент на диалог или практику...',
            prefixIcon: Icons.comment_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsAndVariantsCard(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppGradients.amberOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_outlined, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                '3. Состав материалов и варианты',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Варианты генерации: 1 vs 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Количество вариантов:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [1, 3].map((count) {
                    final isSelected = _variantsCount == count;
                    return InkWell(
                      onTap: () => setState(() => _variantsCount = count),
                      borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.indigoViolet : null,
                          borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                          boxShadow: isSelected ? AppShadows.glowPrimary : null,
                        ),
                        child: Text(
                          count == 1 ? '1 вариант' : '3 варианта',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Выбор материалов (чипы)
          Text(
            'Что генерировать:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: GenerationType.values.map((type) {
              final isSelected = _selectedMaterials.contains(type);
              return InkWell(
                onTap: () => setState(() {
                  if (isSelected) {
                    if (_selectedMaterials.length > 1) {
                      _selectedMaterials.remove(type);
                    }
                  } else {
                    _selectedMaterials.add(type);
                  }
                }),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.primaryIndigo : AppColors.primaryIndigo)
                        : (isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Floating Action Capsule Bar
  Widget _buildFloatingBottomBar(bool isDesktop, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F121C).withOpacity(0.90) : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: isDark ? AppColors.specularHighlight : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: AppShadows.cardLg,
          ),
          child: Row(
            children: [
              // Summary pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _effectiveTopicTitle.isNotEmpty
                          ? _effectiveTopicTitle
                          : 'Укажите тему урока',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${_selectedMethod?.subject ?? "Предмет"} • $_selectedDuration • ${_selectedMaterials.length} мат.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action CTA
              SizedBox(
                height: 44,
                child: GradientButton(
                  text: _getGenerateButtonText(),
                  icon: Icons.auto_awesome,
                  shortcutLabel: isDesktop ? 'Ctrl+↵' : null,
                  onPressed: _onGeneratePressed,
                  borderRadius: AppRadii.md,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
