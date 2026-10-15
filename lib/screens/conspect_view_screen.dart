import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/method_prompt.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';
import '../providers/app_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/thinking_indicator.dart';

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
                        ],
                      ),
                    ),

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

                    // Шаг 2: Секция «Обратная связь»
                    _buildFeedbackSection(isDark),

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
}
