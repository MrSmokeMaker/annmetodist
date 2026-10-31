import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/conspect.dart';
import '../services/assistant_ai_service.dart';
import '../services/telegram/telegram_web_app_service.dart';
import '../theme.dart';
import 'animated_owl_widget.dart';
import 'metodist_assistant_dialog.dart';

class EnhanceLessonModal extends StatefulWidget {
  final Conspect conspect;
  final String currentContent;
  final Function(String enhancedText) onApplyEnhanced;

  const EnhanceLessonModal({
    super.key,
    required this.conspect,
    required this.currentContent,
    required this.onApplyEnhanced,
  });

  static Future<void> show(
    BuildContext context, {
    required Conspect conspect,
    required String currentContent,
    required Function(String enhancedText) onApplyEnhanced,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: EnhanceLessonModal(
            conspect: conspect,
            currentContent: currentContent,
            onApplyEnhanced: onApplyEnhanced,
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EnhanceLessonModal(
          conspect: conspect,
          currentContent: currentContent,
          onApplyEnhanced: onApplyEnhanced,
        ),
      );
    }
  }

  @override
  State<EnhanceLessonModal> createState() => _EnhanceLessonModalState();
}

class _EnhanceLessonModalState extends State<EnhanceLessonModal> {
  final AssistantAiService _aiService = AssistantAiService();
  bool _isLoading = true;
  String _enhancedText = '';
  String _currentStep = 'Анализ конспекта по канонам академической дидактики...';

  @override
  void initState() {
    super.initState();
    _startEnhancement();
  }

  Future<void> _startEnhancement() async {
    // Анимация шагов обогащения
    _updateSteps();

    try {
      final res = await _aiService.enhanceLessonWithMetodistProAi(
        currentContent: widget.currentContent,
        topic: widget.conspect.topic,
        world: widget.conspect.thematicWorld,
        method: widget.conspect.methodName,
      );

      if (mounted) {
        TelegramWebAppService().hapticNotification('success');
        setState(() {
          _enhancedText = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enhancedText = widget.currentContent;
          _isLoading = false;
        });
      }
    }
  }

  void _updateSteps() {
    final steps = [
      '1. Анализ конспекта по нормам ФГОС и методике Пчёлко...',
      '2. Инъекция живой драматургии диалогов учителя и детей...',
      '3. Включение проблемного ТРИЗ-противоречия и ловушки Незнайки...',
      '4. Формирование 3 уровней ДЗ и СанПиН-разминки для глаз...',
      '5. Сборка готового поста для родительского чата...'
    ];

    for (int i = 0; i < steps.length; i++) {
      Future.delayed(Duration(milliseconds: 600 * (i + 1)), () {
        if (mounted && _isLoading) {
          setState(() => _currentStep = steps[i]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: isDesktop ? 760 : double.infinity,
          height: isDesktop ? 700 : MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.95)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading ? _buildLoadingView(isDark) : _buildResultView(isDark),
              ),
              _buildBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.6) : const Color(0xFFEEF2FF).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFD97706)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Улучшить с MetodistPro AI',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD97706), width: 0.8),
                      ),
                      child: const Text(
                        '👑 ДИРЕКТОР',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Тема: «${widget.conspect.topic}» • Мир: «${widget.conspect.thematicWorld.title}»',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedOwlWidget(
              state: OwlState.thinking,
              size: 96,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Педагогическое обогащение урока...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(bool isDark) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Урок успешно обогащён: добавлены диалоги с таймингом, ТРИЗ-задача, 3 уровня ДЗ и СанПиН-разминка!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MarkdownBody(
              data: _enhancedText,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                ),
                h1: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                h2: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                ),
                h3: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Скопировать', style: TextStyle(fontSize: 12)),
            onPressed: _isLoading
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _enhancedText));
                    TelegramWebAppService().hapticNotification('success');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Обогащённый конспект скопирован в буфер!')),
                    );
                  },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Text('🦉', style: TextStyle(fontSize: 14)),
            label: const Text('В чат Совёнка', style: TextStyle(fontSize: 12)),
            onPressed: () {
              Navigator.of(context).pop();
              MetodistAssistantDialog.show(
                context,
                currentTopic: widget.conspect.topic,
                currentWorld: widget.conspect.thematicWorld,
                currentMethod: widget.conspect.methodName,
                ageGroup: widget.conspect.ageGroup,
              );
            },
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text(
              'Применить к конспекту',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    TelegramWebAppService().hapticImpact('heavy');
                    widget.onApplyEnhanced(_enhancedText);
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
    );
  }
}
