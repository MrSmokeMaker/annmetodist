import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/method_prompt.dart';
import '../models/printable_card.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';
import '../providers/app_provider.dart';
import '../services/colleague_brief_service.dart';
import '../services/ics_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/prompt_builder.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/thinking_indicator.dart';
import 'lesson_run_screen.dart';

class ConspectViewScreen extends StatefulWidget {
  final Conspect? existingConspect;
  final MethodPrompt? method;
  final String? ageGroup;
  final String? topicTitle;
  final String? duration;
  final String? review;
  final String? notes;
  final SituationTemplate? situation;
  final List<ActivityTechnique>? activities;
  final bool isNewGeneration;
  final int variantsCount;

  const ConspectViewScreen({
    super.key,
    this.existingConspect,
    this.method,
    this.ageGroup,
    this.topicTitle,
    this.duration,
    this.review,
    this.notes,
    this.situation,
    this.activities,
    this.isNewGeneration = false,
    this.variantsCount = 1,
  });

  @override
  State<ConspectViewScreen> createState() => _ConspectViewScreenState();
}

class _ConspectViewScreenState extends State<ConspectViewScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLoading;
  String? _errorMessage;
  Conspect? _currentConspect;
  List<Conspect> _variants = [];
  int _selectedVariantIndex = 0;

  bool _isEditing = false;
  late TextEditingController _editController;
  late TextEditingController _parentNotesController;
  bool _isPreviewNotes = false;

  // Animation for save action (fade + scale)
  late AnimationController _saveAnimController;
  late Animation<double> _saveScaleAnim;
  late Animation<double> _saveFadeAnim;
  bool _showSavedBanner = false;

  @override
  void initState() {
    super.initState();
    _currentConspect = widget.existingConspect;
    _isLoading = widget.isNewGeneration;
    _editController = TextEditingController(
      text: _currentConspect?.content ?? '',
    );
    _parentNotesController = TextEditingController(
      text: _currentConspect?.parentNotes ?? '',
    );

    if (_currentConspect != null) {
      _variants = [_currentConspect!];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentConspect!.batchGroupId != null) {
          final siblings = context
              .read<AppProvider>()
              .conspects
              .where((c) => c.batchGroupId == _currentConspect!.batchGroupId)
              .toList()
            ..sort((a, b) => a.variantIndex.compareTo(b.variantIndex));
          if (siblings.length > 1) {
            setState(() {
              _variants = siblings;
              _selectedVariantIndex =
                  _variants.indexWhere((c) => c.id == _currentConspect!.id);
              if (_selectedVariantIndex < 0) _selectedVariantIndex = 0;
            });
          }
        }
      });
    }

    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _saveScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeOutBack),
    );

    _saveFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeIn),
    );

    if (widget.isNewGeneration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGeneration();
      });
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _parentNotesController.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<AppProvider>();
      if (widget.variantsCount > 1) {
        final variants = await provider.generateBatchConspects(
          method: widget.method!,
          ageGroup: widget.ageGroup!,
          topicTitle: widget.topicTitle!,
          duration: widget.duration!,
          review: widget.review,
          notes: widget.notes,
          situation: widget.situation,
          activities: widget.activities,
          variantsCount: widget.variantsCount,
        );

        setState(() {
          _variants = variants;
          _selectedVariantIndex = 0;
          _currentConspect = variants.isNotEmpty ? variants.first : null;
          _editController.text = _currentConspect?.content ?? '';
          _parentNotesController.text = _currentConspect?.parentNotes ?? '';
          _isLoading = false;
        });
      } else {
        final conspect = await provider.generateConspect(
          method: widget.method!,
          ageGroup: widget.ageGroup!,
          topicTitle: widget.topicTitle!,
          duration: widget.duration!,
          review: widget.review,
          notes: widget.notes,
          situation: widget.situation,
          activities: widget.activities,
        );

        setState(() {
          _variants = [conspect];
          _selectedVariantIndex = 0;
          _currentConspect = conspect;
          _editController.text = conspect.content;
          _parentNotesController.text = conspect.parentNotes;
          _isLoading = false;
        });

        // Automatically save to library on first generation
        await provider.saveConspect(conspect);
      }

      _triggerSaveFeedback();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _selectVariant(int index) {
    if (index >= 0 && index < _variants.length) {
      setState(() {
        _selectedVariantIndex = index;
        _currentConspect = _variants[index];
        _editController.text = _currentConspect?.content ?? '';
        _parentNotesController.text = _currentConspect?.parentNotes ?? '';
        _isEditing = false;
      });
    }
  }

  void _triggerSaveFeedback() {
    setState(() {
      _showSavedBanner = true;
    });
    _saveAnimController.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _saveAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showSavedBanner = false;
            });
          }
        });
      }
    });
  }

  Future<void> _saveCurrentContent() async {
    if (_currentConspect == null) return;
    final updated = _currentConspect!.copyWith(
      content: _editController.text,
      updatedAt: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    await provider.saveConspect(updated);

    setState(() {
      _currentConspect = updated;
      _isEditing = false;
    });

    _triggerSaveFeedback();
  }

  Future<void> _shareConspectText() async {
    if (_currentConspect == null) return;
    final textToShare = '''
${_currentConspect!.title}
Методика: ${_currentConspect!.methodName} (${_currentConspect!.subject})
Возраст: ${Topic.getAgeGroupLabel(_currentConspect!.ageGroup)} | Длительность: ${_currentConspect!.duration}

${_currentConspect!.content}
''';
    await Share.share(textToShare, subject: _currentConspect!.title);
  }

  Future<void> _exportPdf() async {
    if (_currentConspect == null) return;
    try {
      await PdfExportService.exportAndSharePdf(_currentConspect!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта в PDF: $e')),
      );
    }
  }

  /// Parses Markdown content into distinct sections by `# ` headers
  List<Map<String, String>> _parseSections(String content) {
    final lines = content.split('\n');
    final List<Map<String, String>> sections = [];

    String currentHeader = '';
    final StringBuffer currentBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ') || (trimmed.startsWith('## ') && currentHeader.isEmpty)) {
        if (currentHeader.isNotEmpty || currentBuffer.isNotEmpty) {
          sections.add({
            'header': currentHeader.isEmpty ? 'Общие сведения' : currentHeader,
            'content': currentBuffer.toString().trim(),
          });
          currentBuffer.clear();
        }
        currentHeader = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
      } else {
        currentBuffer.writeln(line);
      }
    }

    if (currentHeader.isNotEmpty || currentBuffer.isNotEmpty) {
      sections.add({
        'header': currentHeader.isEmpty ? 'Конспект занятия' : currentHeader,
        'content': currentBuffer.toString().trim(),
      });
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _currentConspect?.title ?? 'Конспект занятия',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && _currentConspect != null) ...[
            // Toggle edit mode
            IconButton(
              tooltip: _isEditing ? 'Сохранить изменения' : 'Редактировать',
              icon: Icon(_isEditing ? Icons.check_circle_outline : Icons.edit_note),
              color: _isEditing ? AppColors.success : null,
              onPressed: () {
                if (_isEditing) {
                  _saveCurrentContent();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
            // Export PDF
            IconButton(
              tooltip: 'Экспорт в PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _exportPdf,
            ),
            // Share
            IconButton(
              tooltip: 'Поделиться',
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareConspectText,
            ),
            // Шаг 7: В календарь (.ics)
            IconButton(
              tooltip: 'В календарь (.ics)',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: _showCalendarExportDialog,
            ),
            // Шаг 7: Для коллеги
            IconButton(
              tooltip: 'Для коллеги',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: _showColleagueBriefSheet,
            ),
            // Шаг 4: Вести урок
            IconButton(
              tooltip: 'Вести урок',
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.cyan),
              onPressed: () {
                Navigator.of(context).push(
                  FadeSlidePageRoute(
                    page: LessonRunScreen(conspect: _currentConspect!),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Loading State
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: ThinkingIndicator(),
                  ),
                )

              // 2. Error State
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Не удалось получить конспект',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          GradientButton(
                            text: 'Повторить попытку',
                            icon: Icons.refresh_rounded,
                            onPressed: _startGeneration,
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // 3. Content View / Edit Mode
              else if (_currentConspect != null)
                ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // Переключатель вариантов, если создано > 1 варианта
                    if (_variants.length > 1) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: List.generate(_variants.length, (idx) {
                            final isSel = _selectedVariantIndex == idx;
                            final variantNumber = _variants[idx].variantIndex;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  onTap: () => _selectVariant(idx),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: isSel ? AppGradients.indigoViolet : null,
                                      color: isSel
                                          ? null
                                          : (isDark
                                              ? Colors.white.withOpacity(0.04)
                                              : Colors.black.withOpacity(0.04)),
                                      borderRadius: BorderRadius.circular(AppRadii.sm),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Вариант $variantNumber',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Top Info Glass Chip Banner
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppGradients.indigoViolet,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentConspect!.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_currentConspect!.methodName} • ${_currentConspect!.subject} • ${Topic.getAgeGroupLabel(_currentConspect!.ageGroup)} • ${_currentConspect!.duration}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                            label: const Text(
                              'Вести урок',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                FadeSlidePageRoute(
                                  page: LessonRunScreen(conspect: _currentConspect!),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Шаг 3: Аудио-подсказка для родителя (быстрая плашка)
                    _buildParentAudioHintBanner(isDark),

                    const SizedBox(height: AppSpacing.md),

                    // Edit Mode or Structured Glass Sections View
                    if (_isEditing) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Режим редактирования (Markdown)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryIndigo,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryIndigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Готово'),
                                  onPressed: _saveCurrentContent,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _editController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Текст конспекта...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Render structured sections with gradient underline headers
                      ..._buildStructuredSections(
                        _currentConspect!.content,
                        isDark,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Шаг 3: Секция «Раздаточные карточки (распечатка А4)»
                    _buildPrintableCardsSection(isDark),

                    const SizedBox(height: AppSpacing.lg),

                    // Шаг 2: Секция «Обратная связь»
                    _buildFeedbackSection(isDark),

                    const SizedBox(height: AppSpacing.lg),

                    // Шаг 6: Секция «Заметки родителя» с Markdown-редактором
                    _buildParentNotesSection(isDark),

                    const SizedBox(height: AppSpacing.lg),

                    // Шаг 7: Секция «Интеграции: Календарь и Шпаргалка для коллеги»
                    _buildIntegrationsSection(isDark),

                    const SizedBox(height: AppSpacing.lg),

                    // Action Button: "Сгенерировать ещё вариант"
                    if (widget.method != null)
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Нужен другой вариант?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Перегенерировать с теми же параметрами',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GradientButton(
                              width: 130,
                              height: 42,
                              borderRadius: AppRadii.md,
                              text: 'Ещё вариант',
                              icon: Icons.refresh_rounded,
                              onPressed: _startGeneration,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),

              // 4. Save feedback banner (fade + scale)
              if (_showSavedBanner)
                Positioned(
                  top: 16,
                  left: 24,
                  right: 24,
                  child: FadeTransition(
                    opacity: _saveFadeAnim,
                    child: ScaleTransition(
                      scale: _saveScaleAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.cyanBlue,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Конспект сохранён в библиотеку!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStructuredSections(String content, bool isDark) {
    final sections = _parseSections(content);
    final List<Widget> widgets = [];

    for (final section in sections) {
      final header = section['header']!;
      final sectionBody = section['content']!;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            borderRadius: AppRadii.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Gradient underline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      header,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      width: 52,
                      decoration: BoxDecoration(
                        gradient: AppGradients.indigoViolet,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Markdown Renderer for Section Body
                MarkdownBody(
                  data: sectionBody,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    listBullet: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryIndigo,
                    ),
                    h2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    h3: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Шаг 2: Секция «Обратная связь» с адаптацией последующих генераций
  Widget _buildFeedbackSection(bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();

    final provider = context.watch<AppProvider>();
    // Находим актуальный конспект в провайдере
    final current = provider.conspects.firstWhere(
      (c) => c.id == _currentConspect!.id,
      orElse: () => _currentConspect!,
    );
    final activeTags = current.feedbackTags;

    final feedbackOptions = [
      {
        'tag': 'Было трудно',
        'icon': Icons.sentiment_dissatisfied_outlined,
        'color': const Color(0xFFF59E0B), // amber
        'hint': 'Упростит темп и добавит наглядные опоры',
      },
      {
        'tag': 'Справился легко',
        'icon': Icons.sentiment_very_satisfied_outlined,
        'color': const Color(0xFF10B981), // emerald
        'hint': 'Добавит вариативности и эвристики',
      },
      {
        'tag': 'Слишком много письма',
        'icon': Icons.draw_outlined,
        'color': const Color(0xFF8B5CF6), // purple
        'hint': 'Автоматически сократит письмо на 30%',
      },
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanBlue,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Обратная связь по занятию',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Отметьте результат урока — система учтёт его при следующих генерациях (например, сократит объём письменных заданий на 30%):',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: feedbackOptions.map((opt) {
              final tag = opt['tag'] as String;
              final icon = opt['icon'] as IconData;
              final color = opt['color'] as Color;
              final hint = opt['hint'] as String;
              final isSelected = activeTags.contains(tag);

              return Tooltip(
                message: hint,
                child: InkWell(
                  onTap: () async {
                    await provider.toggleFeedbackTag(current.id, tag);
                    if (mounted) {
                      setState(() {
                        _currentConspect = provider.conspects.firstWhere(
                          (c) => c.id == current.id,
                          orElse: () => current,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : icon,
                          size: 16,
                          color: isSelected ? color : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? color : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
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

  /// Шаг 3: Быстрая плашка «Подсказка для родителя»
  Widget _buildParentAudioHintBanner(bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();

    final audioText = _currentConspect!.parentAudioScript ??
        PromptBuilder.extractParentAudioScript(_currentConspect!.content);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      borderRadius: AppRadii.lg,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppGradients.cyanBlue,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              Icons.record_voice_over_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Подсказка для родителя',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '30–60 сек аудио-заготовка: как объяснить тему',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(color: AppColors.cyan.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            icon: const Icon(Icons.headphones_outlined, size: 16, color: AppColors.cyan),
            label: const Text(
              'Слушать',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cyan,
              ),
            ),
            onPressed: () => _showParentAudioModal(
              audioText ??
                  'Для этой темы сформулируйте основные правила простыми словами, избегая академических терминов, и поддержите ребенка при первых попытках.',
            ),
          ),
        ],
      ),
    );
  }

  void _showParentAudioModal(String script) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161922) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.cyanBlue,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Подсказка для родителя',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '⏱ Время звучания: ~45 сек',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Скопировать текст',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: script));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Текст подсказки скопирован в буфер')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  script,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Понятно'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Шаг 3: Секция «Раздаточные карточки (распечатка А4)»
  Widget _buildPrintableCardsSection(bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();

    final List<PrintableCard> cards = _currentConspect!.cards ??
        PromptBuilder.extractPrintableCards(_currentConspect!.content);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                    child: const Icon(
                      Icons.style_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Карточки и распечатки',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (cards.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 15),
                  label: const Text('Печать А4 (2×3)'),
                  onPressed: () async {
                    try {
                      await PdfExportService.exportCardsPdf(
                        cards: cards,
                        lessonTitle: _currentConspect!.title,
                        methodName: _currentConspect!.methodName,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка печати карточек: $e')),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cards.isNotEmpty
                ? 'Готово ${cards.length} карточек. Распечатайте на листе А4 и разрежьте по пунктирным линиям:'
                : 'К этому занятию можно создать 6 двусторонних карточек для печати на А4:',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (cards.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, idx) {
                final card = cards[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
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
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryIndigo.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              PrintableCard.getTypeLabel(card.type).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryIndigo,
                              ),
                            ),
                          ),
                          const Text('✂', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Center(
                        child: Text(
                          card.frontText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: card.frontText.length <= 4 ? 22 : 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        card.imageHint != null && card.imageHint!.isNotEmpty
                            ? '💡 ${card.imageHint}'
                            : card.backText,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: const BorderSide(color: AppColors.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: AppColors.cyan, size: 18),
                  label: const Text(
                    'Создать 6 карточек к уроку',
                    style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final provider = context.read<AppProvider>();
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Генерируем карточки к уроку...')),
                      );
                      final newCards = await provider.generateCardsForConspect(_currentConspect!.id);
                      if (mounted && newCards.isNotEmpty) {
                        setState(() {
                          _currentConspect = _currentConspect!.copyWith(cards: newCards);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Карточки успешно созданы!')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка генерации карточек: $e')),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Шаг 6: Секция «Заметки родителя» с Markdown-редактором и кнопками форматирования
  Widget _buildParentNotesSection(bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                      gradient: AppGradients.cyanBlue,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Заметки родителя / учителя',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: _isPreviewNotes ? 'Редактировать' : 'Предпросмотр Markdown',
                icon: Icon(
                  _isPreviewNotes ? Icons.edit_note : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.cyan,
                ),
                onPressed: () {
                  setState(() {
                    _isPreviewNotes = !_isPreviewNotes;
                  });
                },
              ),
            ],
          ),

          if (!_isPreviewNotes) ...[
            const SizedBox(height: 8),
            // Markdown форматирование (кнопки)
            Wrap(
              spacing: 6,
              children: [
                _buildFormatBtn('**Ж**', () => _insertMarkdown('**', '**')),
                _buildFormatBtn('*К*', () => _insertMarkdown('*', '*')),
                _buildFormatBtn('• Список', () => _insertMarkdown('- ', '')),
                _buildFormatBtn('✔ Чек-лист', () => _insertMarkdown('- [ ] ', '')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _parentNotesController,
              maxLines: 3,
              onChanged: (text) {
                context.read<AppProvider>().updateParentNotes(_currentConspect!.id, text);
              },
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                hintText: 'Запишите успехи ребенка, новые слова или заметки (Markdown)...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: MarkdownBody(
                data: _parentNotesController.text.isNotEmpty
                    ? _parentNotesController.text
                    : '*Заметок пока нет. Переключите режим, чтобы написать заметку.*',
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _parentNotesController.text;
    final selection = _parentNotesController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _parentNotesController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final offset = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(offset, offset, '$prefix$suffix');
      _parentNotesController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset + prefix.length),
      );
    }
    context.read<AppProvider>().updateParentNotes(_currentConspect!.id, _parentNotesController.text);
  }

  Widget _buildFormatBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryIndigo.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.primaryIndigo.withOpacity(0.3), width: 0.8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryIndigo,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Шаг 7: Интеграции (Календарь ICS & Для коллеги)
  // ==========================================

  Widget _buildIntegrationsSection(bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanBlue,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Интеграции и обмен',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Календарь занятий и шпаргалка для коллеги',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // 1. В календарь (.ics)
              Expanded(
                child: InkWell(
                  onTap: _showCalendarExportDialog,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'В календарь',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Файл .ics (Google, Apple, Outlook)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 2. Для коллеги
              Expanded(
                child: InkWell(
                  onTap: _showColleagueBriefSheet,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppGradients.indigoViolet,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Для коллеги',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Шпаргалка с целями и этапами',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCalendarExportDialog() {
    if (_currentConspect == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int selectedDuration = IcsExportService.parseDurationMinutes(
      _currentConspect!.duration,
      fallback: 30,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
            final endDateTime = startDateTime.add(Duration(minutes: selectedDuration));

            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xl),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Добавить занятие в календарь',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                'Экспорт в формате RFC 5545 (.ics)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Date & Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: const Icon(Icons.event_outlined, size: 18),
                            label: Text(
                              '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: const Icon(Icons.access_time_rounded, size: 18),
                            label: Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Duration Selector
                    Text(
                      'Длительность занятия:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      children: [20, 25, 30, 40, 45].map((mins) {
                        final isSel = selectedDuration == mins;
                        return ChoiceChip(
                          label: Text('$mins мин'),
                          selected: isSel,
                          selectedColor: AppColors.primaryIndigo.withValues(alpha: 0.25),
                          onSelected: (_) => setModalState(() => selectedDuration = mins),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Event Preview Info
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentConspect!.topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Время: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} – ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')} ($selectedDuration мин)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            'Методика: ${_currentConspect!.methodName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text(
                          'Скачать / Добавить событие (.ics)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await IcsExportService.shareIcsFile(
                            conspect: _currentConspect!,
                            startDateTime: startDateTime,
                            customDurationMinutes: selectedDuration,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showColleagueBriefSheet() {
    if (_currentConspect == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brief = ColleagueBriefService.generateColleagueBrief(_currentConspect!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.indigoViolet,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Шпаргалка для коллеги',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Краткая выжимка для проведения занятия или замены',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        brief,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Скопировать'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: brief));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Шпаргалка скопирована в буфер обмена!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Отправить'),
                        onPressed: () async {
                          await ColleagueBriefService.shareColleagueBrief(_currentConspect!);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
