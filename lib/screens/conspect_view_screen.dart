import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/conspect.dart';
import '../models/method_prompt.dart';
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
  final bool isNewGeneration;

  const ConspectViewScreen({
    super.key,
    this.existingConspect,
    this.method,
    this.ageGroup,
    this.topicTitle,
    this.duration,
    this.review,
    this.notes,
    this.isNewGeneration = false,
  });

  @override
  State<ConspectViewScreen> createState() => _ConspectViewScreenState();
}

class _ConspectViewScreenState extends State<ConspectViewScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLoading;
  String? _errorMessage;
  Conspect? _currentConspect;

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
      final conspect = await provider.generateConspect(
        method: widget.method!,
        ageGroup: widget.ageGroup!,
        topicTitle: widget.topicTitle!,
        duration: widget.duration!,
        review: widget.review,
        notes: widget.notes,
      );

      setState(() {
        _currentConspect = conspect;
        _editController.text = conspect.content;
        _isLoading = false;
      });

      // Automatically save to library on first generation
      await provider.saveConspect(conspect);
      _triggerSaveFeedback();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
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
                                  _currentConspect!.methodName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_currentConspect!.subject} • ${Topic.getAgeGroupLabel(_currentConspect!.ageGroup)} • ${_currentConspect!.duration}',
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
                      color: isDark ? Colors.white : Colors.black84,
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
}
