import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/thematic_world.dart';
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
import '../widgets/metodist_assistant_dialog.dart';
import 'profile_screen.dart';
import '../services/docx_export_service.dart';
import '../services/pptx_export_service.dart';
import '../services/methodology_architect_service.dart';
import '../services/surgical_ai_service.dart';
import '../widgets/interactive_methodist_drawer.dart';
import '../widgets/block_action_toolbar.dart';
import '../widgets/rno_dialog.dart';
import '../services/worksheet_audit_service.dart';
import '../widgets/task_audit_badge.dart';
import '../services/lesson_rubric_service.dart';
import '../services/lesson_context_service.dart';

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
  final Set<GenerationType>? materials;
  final bool isDeepLesson;

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
    this.materials,
    this.isDeepLesson = false,
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
  int? _isRegeneratingBlockIndex;
  bool _isDebugAuditMode = false;

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

        // В тарифе Metodist PRO автоматически догенерируем иллюстрации к карточкам, если их еще не созданы
        final provider = context.read<AppProvider>();
        if (provider.isProUser && _currentConspect != null && _currentConspect!.cards != null && _currentConspect!.cards!.isNotEmpty) {
          final lacksImages = _currentConspect!.cards!.any((c) => c.imageUrl == null || c.imageUrl!.isEmpty);
          if (lacksImages) {
            _autoGenerateImagesForPro();
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
          materials: widget.materials,
          isDeepLesson: widget.isDeepLesson,
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
          materials: widget.materials,
          isDeepLesson: widget.isDeepLesson,
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

  bool _hasMaterial(PdfMaterialType type) {
    if (_currentConspect == null) return false;
    final generated = _currentConspect!.generatedMaterials;
    switch (type) {
      case PdfMaterialType.conspect:
        return generated.contains('conspect') || generated.isEmpty;
      case PdfMaterialType.worksheet:
        return generated.contains('worksheet') && PdfExportService.hasMaterialContent(_currentConspect!.content, PdfMaterialType.worksheet);
      case PdfMaterialType.homework:
        return generated.contains('homework') && PdfExportService.hasMaterialContent(_currentConspect!.content, PdfMaterialType.homework);
    }
  }

  Future<void> _exportMaterial(PdfMaterialType type) async {
    if (_currentConspect == null) return;
    try {
      final isPro = context.read<AppProvider>().isProUser;
      await PdfExportService.exportMaterialPdf(_currentConspect!, type, isPro: isPro);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта в PDF: $e')),
      );
    }
  }

  Future<void> _exportAllCombined() async {
    if (_currentConspect == null) return;
    try {
      final isPro = context.read<AppProvider>().isProUser;
      await PdfExportService.exportAllMaterialsCombinedPdf(_currentConspect!, isPro: isPro);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта комплекта PDF: $e')),
      );
    }
  }

  Future<void> _autoGenerateImagesForPro() async {
    if (_currentConspect == null) return;
    try {
      final provider = context.read<AppProvider>();
      await provider.generateArtPackageForConspect(_currentConspect!.id);
      final updated = provider.conspects.firstWhere((c) => c.id == _currentConspect!.id);
      if (mounted) {
        setState(() {
          _currentConspect = updated;
        });
      }
    } catch (_) {}
  }



  void _showProFeatureDialog({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161922) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppGradients.amberOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Позже'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.stars_rounded, size: 20),
                      label: const Text(
                        'Перейти к тарифам',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          FadeSlidePageRoute(page: const ProfileScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      floatingActionButton: (_isLoading || _currentConspect == null)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.school_rounded, size: 20),
              label: const Text('Методист на связи', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                InteractiveMethodistDrawer.show(
                  context,
                  conspect: _currentConspect!,
                  gptService: context.read<AppProvider>().yandexGptService,
                );
              },
            ),
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
            // Совёнок-Методист AI
            IconButton(
              tooltip: 'Спросить Совёнка-Методиста AI',
              icon: const Text('🦉', style: TextStyle(fontSize: 18)),
              onPressed: () {
                MetodistAssistantDialog.show(
                  context,
                  currentTopic: _currentConspect?.topic,
                  currentWorld: _currentConspect?.thematicWorld,
                  currentMethod: _currentConspect?.methodName,
                  ageGroup: _currentConspect?.ageGroup,
                  onApplySnippet: (snippet) {
                    setState(() {
                      _editController.text = '${_editController.text}\n\n$snippet';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Материал от Совёнка добавлен в конспект!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
            // Методический аудит (QA YandexGPT Pro)
            IconButton(
              tooltip: 'Методический аудит качества (ФГОС & QA)',
              icon: const Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
              onPressed: () => _showRubricDialog(context),
            ),
            // Тесты и контрольный срез
            IconButton(
              tooltip: 'Контрольный срез (5 тестов + 3 открытых вопроса)',
              icon: const Icon(Icons.quiz_rounded, color: AppColors.accentCyan),
              onPressed: () => _showTestQuestionsModal(context),
            ),
            // Отладочный режим YandexGPT
            IconButton(
              tooltip: _isDebugAuditMode ? 'Выключить отладку' : 'Отладка заданий (Оценка YandexGPT)',
              icon: Icon(
                Icons.biotech_rounded,
                color: _isDebugAuditMode ? AppColors.accentCyan : null,
              ),
              onPressed: () {
                setState(() => _isDebugAuditMode = !_isDebugAuditMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isDebugAuditMode
                        ? 'Отладочный режим включен: отображаются оценки логики, орфографии, визуала и генерация в YandexART'
                        : 'Отладочный режим выключен'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            // Пакет дифференциации «3 в 1»
            IconButton(
              tooltip: 'Дифференциация «3 в 1» (Опора / База / Pro)',
              icon: const Icon(Icons.layers_rounded, color: AppColors.accentAmber),
              onPressed: _generateDifferentiationPackage,
            ),
            // Работа над ошибками
            IconButton(
              tooltip: 'Работа над ошибками (РНО)',
              icon: const Icon(Icons.healing_rounded, color: Color(0xFF10B981)),
              onPressed: () => RnoDialog.show(context, currentConspect: _currentConspect),
            ),
            // Word export
            IconButton(
              tooltip: 'Экспорт в Word (.docx)',
              icon: const Icon(Icons.description_rounded, color: Color(0xFF3B82F6)),
              onPressed: _exportDocx,
            ),
            // PowerPoint export (Тариф Директор)
            IconButton(
              tooltip: 'Презентация PowerPoint (.pptx) [ДИРЕКТОР]',
              icon: const Icon(Icons.slideshow_rounded, color: Color(0xFFD97706)),
              onPressed: _exportPptx,
            ),
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
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      children: [
                        // Переключатель вариантов, если создано > 1 варианта
                        if (_variants.length > 1) ...[
                          GlassCard(
                            padding: const EdgeInsets.all(6),
                            borderRadius: AppRadii.lg,
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
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: isSel ? AppGradients.indigoViolet : null,
                                          color: isSel
                                              ? null
                                              : (isDark
                                                  ? const Color(0x14FFFFFF)
                                                  : Colors.black.withOpacity(0.04)),
                                          borderRadius: BorderRadius.circular(AppRadii.sm),
                                          boxShadow: isSel ? AppShadows.glowPrimary : null,
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
                          padding: const EdgeInsets.all(AppSpacing.md),
                          borderRadius: AppRadii.xl,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.indigoViolet,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: AppShadows.glowPrimary,
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentConspect!.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: AppGradients.indigoViolet,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            _currentConspect!.methodName,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            _currentConspect!.subject,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            '${Topic.getAgeGroupLabel(_currentConspect!.ageGroup)} • ${_currentConspect!.duration}',
                                            style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                label: const Text(
                                  'Вести урок',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
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

                    // Тематический игровой мир и маскот YandexART
                        _buildThematicWorldSelectorCard(context, isDark),
                        const SizedBox(height: AppSpacing.sm),

                        // Методический аудит качества YandexGPT Pro (QA)
                        _buildQaRubricCard(context, isDark),
                        const SizedBox(height: AppSpacing.sm),

                        // Интерактивные кнопки быстрого экспорта только сгенерированных материалов
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryIndigo.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.accentCyan),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Экспорт материалов в отдельные PDF:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_hasMaterial(PdfMaterialType.conspect))
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryIndigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                                  label: const Text('PDF Конспект', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: () => _exportMaterial(PdfMaterialType.conspect),
                                ),
                              if (_hasMaterial(PdfMaterialType.worksheet))
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.assignment_outlined, size: 16),
                                  label: const Text('PDF Лист заданий', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: () => _exportMaterial(PdfMaterialType.worksheet),
                                ),
                              if (_hasMaterial(PdfMaterialType.homework))
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.home_work_outlined, size: 16),
                                  label: const Text('PDF Домашка', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: () => _exportMaterial(PdfMaterialType.homework),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.description_rounded, size: 16),
                                  label: const Text('Word (.docx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: _exportDocx,
                                ),
                              // Если сгенерировано больше одного материала, предлагаем единый комплект (с гарантией новых листов)
                              if ((_hasMaterial(PdfMaterialType.worksheet) || _hasMaterial(PdfMaterialType.homework)) && _hasMaterial(PdfMaterialType.conspect))
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? AppColors.accentCyan : AppColors.primaryIndigo,
                                    side: BorderSide(color: isDark ? AppColors.accentCyan.withOpacity(0.5) : AppColors.primaryIndigo.withOpacity(0.5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.collections_bookmark_outlined, size: 16),
                                  label: const Text('PDF Весь комплект (с новых листов)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: _exportAllCombined,
                                ),
                            ],
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
              ),
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

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final header = section['header']!;
      final sectionBody = section['content']!;
      final lowerHeader = header.toLowerCase();

      final bool isWorksheet = lowerHeader.contains('лист заданий') || lowerHeader.contains('раздаточн');
      final bool isHomework = lowerHeader.contains('домашн') || lowerHeader.contains('блок дополнительных');
      // Place conspect button after the last conspect section (or after 'ход занятия')
      final bool isConspectKeySection = lowerHeader.contains('дифференциация') ||
          (lowerHeader.contains('ход занятия') && i + 1 < sections.length &&
              (sections[i + 1]['header']!.toLowerCase().contains('лист заданий')));

      IconData sectionIcon = Icons.article_rounded;
      Color sectionColor = AppColors.primaryIndigo;
      if (lowerHeader.contains('цели') || lowerHeader.contains('задач') || lowerHeader.contains('план')) {
        sectionIcon = Icons.flag_rounded;
        sectionColor = AppColors.primaryIndigo;
      } else if (lowerHeader.contains('ход') || lowerHeader.contains('этап') || lowerHeader.contains('заняти')) {
        sectionIcon = Icons.timeline_rounded;
        sectionColor = AppColors.cyan;
      } else if (isWorksheet) {
        sectionIcon = Icons.assignment_rounded;
        sectionColor = const Color(0xFF2563EB);
      } else if (isHomework) {
        sectionIcon = Icons.home_work_rounded;
        sectionColor = const Color(0xFF059669);
      } else if (lowerHeader.contains('дифференц') || lowerHeader.contains('рефлекс') || lowerHeader.contains('итог')) {
        sectionIcon = Icons.lightbulb_outline_rounded;
        sectionColor = AppColors.accentAmber;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            borderRadius: AppRadii.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Modern Icon Tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: sectionColor.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(sectionIcon, size: 16, color: sectionColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        header,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              fontSize: 16,
                            ),
                      ),
                    ),
                    if (isWorksheet || lowerHeader.contains('ход') || lowerHeader.contains('задани'))
                      BlockActionToolbar(
                        isLoading: _isRegeneratingBlockIndex == i,
                        onAction: (action, customTheme) => _handleBlockAction(i, section, action, customTheme),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                ),
                const SizedBox(height: AppSpacing.md),

                // Markdown Renderer for Section Body
                MarkdownBody(
                  data: sectionBody,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
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
                      color: sectionColor,
                    ),
                    h2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
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

                if (_isDebugAuditMode && isWorksheet && _currentConspect != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryIndigo.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.biotech_rounded, size: 16, color: AppColors.primaryIndigo),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Отладка листа заданий: оценки YandexGPT и промпты YandexART',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final injected = WorksheetAuditService.injectAuditBadges(
                              content: _currentConspect!.content,
                              topic: _currentConspect!.topic,
                              ageGroup: _currentConspect!.ageGroup,
                              subject: _currentConspect!.subject,
                              methodId: _currentConspect!.methodId,
                            );
                            _saveInjectedContent(injected);
                          },
                          child: const Text('Встроить в текст', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...WorksheetAuditService.auditWorksheet(
                    content: sectionBody,
                    topic: _currentConspect!.topic,
                    ageGroup: _currentConspect!.ageGroup,
                    subject: _currentConspect!.subject,
                    methodId: _currentConspect!.methodId,
                  ).map((eval) => TaskAuditBadge(evaluation: eval)),
                ],

                // Dedicated Export Buttons after sections
                if (isWorksheet) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Лист заданий для печати',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Распечатайте рабочий лист для урока',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Печать PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _exportMaterial(PdfMaterialType.worksheet),
                        ),
                      ],
                    ),
                  ),
                ] else if (isHomework) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: const Color(0xFF059669).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_work_rounded, color: Color(0xFF059669), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Домашняя работа',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Распечатайте домашнее задание и памятку',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Печать PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _exportMaterial(PdfMaterialType.homework),
                        ),
                      ],
                    ),
                  ),
                ] else if (isConspectKeySection) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.primaryIndigo.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.primaryIndigo, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Конспект занятия',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Методика, тайминг и ход урока для преподавателя',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Печать PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _exportMaterial(PdfMaterialType.conspect),
                        ),
                      ],
                    ),
                  ),
                ],
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

    // Безопасно извлекаем карточки
    List<PrintableCard> cards = [];
    try {
      final rawCards = _currentConspect!.cards;
      if (rawCards != null && rawCards.isNotEmpty) {
        cards = rawCards;
      } else {
        // Попробуем извлечь из контента
        final extracted = PromptBuilder.extractPrintableCards(_currentConspect!.content);
        if (extracted.isNotEmpty) {
          cards = extracted;
        }
      }
    } catch (e) {
      // Если возникла ошибка при разборе карточек, покажем заглушку
      print('Ошибка при разборе карточек: $e');
      cards = [];
    }

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
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, idx) {
                final card = cards[idx];
                final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
                
                return Container(
                  padding: const EdgeInsets.all(8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryIndigo.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              PrintableCard.getTypeLabel(card.type).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryIndigo,
                              ),
                            ),
                          ),
                          const Text('✂', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                      
                      // Изображение или текст
                      Expanded(
                        child: Center(
                          child: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(
                                      card.imageUrl!.contains(',')
                                          ? card.imageUrl!.split(',').last
                                          : card.imageUrl!,
                                    ),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : Text(
                                  card.frontText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: card.frontText.length <= 4 ? 24 : 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                      
                      // Подсказка или текст на обороте
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          card.imageHint != null && card.imageHint!.isNotEmpty
                              ? '💡 ${card.imageHint}'
                              : (card.backText.isNotEmpty 
                                  ? card.backText 
                                  : (hasImage ? 'Изображение' : '')),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Builder(
                builder: (artCtx) {
                  final provider = artCtx.watch<AppProvider>();
                  final isPro = provider.isProUser;
                  final isGenerating = provider.isGenerating;

                  // В тарифе Metodist PRO иллюстрации генерируются автоматически по умолчанию, кнопку скрываем
                  if (isPro) return const SizedBox.shrink();

                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: BorderSide(color: isPro ? AppColors.primaryIndigo : const Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.palette_outlined,
                            color: isPro ? AppColors.primaryIndigo : const Color(0xFFF59E0B),
                            size: 16,
                          ),
                    label: Text(
                      isGenerating
                          ? 'YandexART генерирует арт-пакет...'
                          : '🎨 Добавить иллюстрации YandexART (PRO)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPro ? (isDark ? Colors.white : AppColors.primaryIndigo) : const Color(0xFFF59E0B),
                      ),
                    ),
                    onPressed: isGenerating
                        ? null
                        : () async {
                            if (!isPro) {
                              _showProFeatureDialog(
                                context: context,
                                title: 'Иллюстрации YandexART (PRO)',
                                description:
                                    'Генерация художественных иллюстраций к карточкам, маскота урока, развивающей раскраски и наградной медали доступна в тарифе «Методист Pro».',
                              );
                              return;
                            }

                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🎨 YandexART создает иллюстрации к уроку и PDF...')),
                              );
                              await provider.generateArtPackageForConspect(_currentConspect!.id);
                              final updated = provider.conspects.firstWhere((c) => c.id == _currentConspect!.id);
                              if (mounted) {
                                setState(() {
                                  _currentConspect = updated;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✨ Иллюстрации YandexART успешно встроены в карточки и PDF!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка генерации YandexART: $e')),
                                );
                              }
                            }
                          },
                  );
                },
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Builder(
                  builder: (btnCtx) {
                    final provider = btnCtx.watch<AppProvider>();
                    final isPro = provider.isProUser;

                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        side: BorderSide(color: isPro ? AppColors.cyan : const Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      icon: Icon(
                        isPro ? Icons.auto_awesome : Icons.workspace_premium_rounded,
                        color: isPro ? AppColors.cyan : const Color(0xFFF59E0B),
                        size: 18,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isPro) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            'Создать 6 карточек к уроку',
                            style: TextStyle(
                              color: isPro ? AppColors.cyan : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        if (!isPro) {
                          _showProFeatureDialog(
                            context: context,
                            title: 'Дидактические карточки для вырезания',
                            description:
                                'Генерация комплекта двусторонних карточек к уроку для распечатки на формате А4 (сетка 2x3) доступна в тарифе «Методист Pro».',
                          );
                          return;
                        }

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
                              const SnackBar(content: Text('Карточки успешно созданы! Формируем PDF...')),
                            );
                            await PdfExportService.exportCardsPdf(
                              cards: newCards,
                              lessonTitle: _currentConspect!.title,
                              methodName: _currentConspect!.methodName,
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Не удалось сгенерировать карточки. Попробуйте еще раз.')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка генерации карточек: $e')),
                          );
                        }
                      },
                    );
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

  Future<void> _exportDocx() async {
    if (_currentConspect == null) return;
    try {
      await DocxExportService.exportConspectToDocx(_currentConspect!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта в Word: $e')),
      );
    }
  }

  Future<void> _exportPptx() async {
    if (_currentConspect == null) return;
    final isDirector = context.read<AppProvider>().isDirector;
    if (!isDirector) {
      _showDirectorWorldUpgradeSheet(context);
      return;
    }
    try {
      final pres = MethodologyArchitectService.generatePresentationForLesson(
        conspect: _currentConspect!,
      );
      await PptxExportService.exportPresentation(pres);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания презентации PowerPoint: $e')),
      );
    }
  }

  Future<void> _generateDifferentiationPackage() async {
    if (_currentConspect == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.layers_rounded, color: AppColors.accentAmber),
            SizedBox(width: 8),
            Text('Дифференциация «3 в 1»', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Создать комплект из 3 дифференцированных вариантов на класс по этой теме?\n\n'
          '• Вариант А: Опора (ОВЗ / пошаговый алгоритм)\n'
          '• Вариант Б: Стандарт ФГОС (базовый уровень)\n'
          '• Вариант В: Детектив Pro (Олимпиада / ТРИЗ-задачи)',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryIndigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сгенерировать пакет 3 в 1'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final appProvider = context.read<AppProvider>();
      final bundle = await appProvider.generateDifferentiatedPackage(_currentConspect!);
      setState(() {
        _currentConspect = bundle[1]; // Вариант Б
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пакет из ${bundle.length} вариантов успешно создан!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания пакета дифференциации: $e')),
        );
      }
    }
  }

  Future<void> _handleBlockAction(int index, Map<String, String> section, BlockAction action, String? customTheme) async {
    if (_currentConspect == null || _isRegeneratingBlockIndex != null) return;
    setState(() => _isRegeneratingBlockIndex = index);

    try {
      final appProvider = context.read<AppProvider>();
      final surgicalService = appProvider.surgicalAiService;
      final oldBlockText = section['content']!;

      final updatedBlockText = await surgicalService.modifyBlock(
        conspect: _currentConspect!,
        blockText: oldBlockText,
        action: action,
        customTheme: customTheme,
      );

      final updatedConspect = await appProvider.updateConspectBlock(
        conspect: _currentConspect!,
        oldBlockText: oldBlockText,
        newBlockText: updatedBlockText,
      );

      setState(() {
        _currentConspect = updatedConspect;
        _editController.text = updatedConspect.content;
        _isRegeneratingBlockIndex = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Блок успешно обновлен через YandexGPT Pro!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegeneratingBlockIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления блока: $e')),
        );
      }
    }
  }


  Future<void> _saveInjectedContent(String text) async {
    if (_currentConspect == null) return;
    final updated = _currentConspect!.copyWith(
      content: text,
      updatedAt: DateTime.now(),
    );
    await context.read<AppProvider>().saveConspect(updated);
    setState(() {
      _currentConspect = updated;
      _editController.text = text;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Строки оценки YandexGPT успешно встроены под каждое задание!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }


  LessonRubricEvaluation _getRubricEvaluation() {
    if (_currentConspect == null) {
      return LessonRubricService.evaluateLesson(
        content: '',
        topic: '',
        ageGroup: '',
        subject: '',
      );
    }
    return LessonRubricService.evaluateLesson(
      content: _currentConspect!.content,
      topic: _currentConspect!.topic,
      ageGroup: _currentConspect!.ageGroup,
      subject: _currentConspect!.subject,
      methodName: _currentConspect!.methodName,
    );
  }

  Future<void> _exportChunkedPdf() async {
    if (_currentConspect == null) return;
    try {
      final isPro = context.read<AppProvider>().isProUser;
      await PdfExportService.exportAllMaterialsCombinedPdf(_currentConspect!, isPro: isPro);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Успешный экспорт урока по логическим частям в PDF!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  void _showTestQuestionsModal(BuildContext context, [List<LessonTestQuestion>? testQuestions]) {
    final rubric = _getRubricEvaluation();
    final questions = testQuestions ?? rubric.testQuestions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161922) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppGradients.cyanBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Контрольный срез (5 тестов + 3 вопроса)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Сгенерировано YandexGPT Pro для проверки знаний',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, idx) {
                  final q = questions[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x14FFFFFF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: q.isOpenQuestion ? const Color(0xFF8B5CF6) : AppColors.primaryIndigo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                q.isOpenQuestion ? 'Открытый вопрос ${q.index - 5}' : 'Тест ${q.index}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                            if (q.isOpenQuestion)
                              const Text('Эвристика / Рефлексия', style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.question,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        if (q.options.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...List.generate(q.options.length, (optIdx) {
                            final isCorrect = optIdx == q.correctOptionIndex;
                            final letter = String.fromCharCode(65 + optIdx);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : (isDark ? const Color(0x0EFFFFFF) : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCorrect
                                      ? const Color(0xFF10B981)
                                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$letter) ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? const Color(0xFF10B981) : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      q.options[optIdx],
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.accentAmber),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Пояснение: ${q.explanation}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRubricDialog(BuildContext context) {
    final rubric = _getRubricEvaluation();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161922) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppGradients.indigoViolet,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Аудит качества YandexGPT Pro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Итоговый балл: ${rubric.overallScore} / 10.0',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...rubric.criteria.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x14FFFFFF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.isPassed
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFF59E0B).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${c.score}/10',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(c.feedback, style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildQaRubricCard(BuildContext context, bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();
    final rubric = _getRubricEvaluation();

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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Методический аудит YandexGPT Pro',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 3),
                    Text(
                      '${rubric.overallScore} / 10.0',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Объем: ${rubric.wordCount} слов  •  ≈ ${rubric.estimatedTokens} токенов  •  ФГОС & отечественная педагогика',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: rubric.criteria.map((c) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isPassed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 12,
                        color: c.isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${c.title}: ${c.score}/10',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.quiz_rounded, size: 15, color: AppColors.accentCyan),
                  label: Text(
                    'Тесты и вопросы (${rubric.testQuestions.length})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  onPressed: () => _showTestQuestionsModal(context, rubric.testQuestions),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.view_carousel_rounded, size: 15),
                  label: const Text(
                    'Детали аудита',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showRubricDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThematicWorldSelectorCard(BuildContext context, bool isDark) {
    if (_currentConspect == null) return const SizedBox.shrink();
    final world = _currentConspect!.thematicWorld;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      borderRadius: AppRadii.lg,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(world.primaryColorHex),
              shape: BoxShape.circle,
              border: Border.all(color: Color(world.accentColorHex), width: 2),
            ),
            child: Center(
              child: Text(
                world.type == ThematicWorldType.space
                    ? '🚀'
                    : (world.type == ThematicWorldType.forest
                        ? '🦉'
                        : (world.type == ThematicWorldType.detective
                            ? '🔍'
                            : (world.type == ThematicWorldType.workshop
                                ? '⚙️'
                                : '🐻'))),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Color(world.primaryColorHex).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Color(world.primaryColorHex).withOpacity(0.4), width: 0.8),
                      ),
                      child: Text(
                        world.missionBadge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(world.primaryColorHex),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      world.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${world.mascotName} (${world.mascotRole}) • «${world.mascotEncouragement('worksheet')}»',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Builder(
            builder: (ctx) {
              final isDirector = ctx.watch<AppProvider>().isDirector;
              return OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(
                    color: isDirector
                        ? Color(world.primaryColorHex).withOpacity(0.5)
                        : Colors.amber.withOpacity(0.7),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(
                  isDirector ? Icons.palette_outlined : Icons.lock_outline,
                  size: 14,
                  color: isDirector ? null : Colors.amber.shade700,
                ),
                label: Text(
                  isDirector ? 'Сменить мир' : 'Сменить мир 🔒',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDirector ? null : Colors.amber.shade800,
                  ),
                ),
                onPressed: () {
                  if (isDirector) {
                    _showWorldSelectorSheet(context);
                  } else {
                    _showDirectorWorldUpgradeSheet(context);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDirectorWorldUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B4B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ТАРИФ ДИРЕКТОР',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Переключение и настройка миров доступна в тарифе «Директор»',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Мгновенная трансформация листа заданий в 5 тематических игровых миров (Космос, Лес, Детектив, Мастерская, Тайга) с уникальной арт-шапкой YandexART, конструктор авторских методик, REST API для LMS и генератор четверти.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E1065).withOpacity(0.6)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF818CF8).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                '1 199 ₽',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                              Text(
                                ' / месяц',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            'при оплате за год (14 388 ₽) • выгода 20%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.purple.shade200 : const Color(0xFF4338CA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'или 1 499 ₽ при помесячной оплате',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text(
                    'Подключить тариф «Директор»',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    context.read<AppProvider>().setUserTier('director');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Тариф «Директор» успешно активирован! Все 5 миров и эксклюзивные студии доступны.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _showWorldSelectorSheet(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWorldSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B4B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выберите игровой мир задания',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...ThematicWorld.allWorlds.map((w) {
                final isCurrent = _currentConspect?.thematicWorld.id == w.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(w.primaryColorHex),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(w.accentColorHex), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        w.type == ThematicWorldType.space
                            ? '🚀'
                            : (w.type == ThematicWorldType.forest
                                ? '🦉'
                                : (w.type == ThematicWorldType.detective
                                    ? '🔍'
                                    : (w.type == ThematicWorldType.workshop
                                        ? '⚙️'
                                        : '🐻'))),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Текущий', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text('${w.mascotName} • ${w.mascotRole}', style: const TextStyle(fontSize: 12)),
                  trailing: Icon(
                    isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isCurrent ? AppColors.accentCyan : null,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentConspect = _currentConspect!.copyWith(thematicWorldId: w.id);
                    });
                    context.read<AppProvider>().saveConspect(_currentConspect!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Игровой мир изменён на «${w.title}» (${w.mascotName})'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
