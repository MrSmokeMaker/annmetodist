import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../providers/app_provider.dart';
import '../screens/conspect_view_screen.dart';
import '../services/prompt_builder.dart';
import '../theme.dart';

class RnoDialog extends StatefulWidget {
  final Conspect? currentConspect;

  const RnoDialog({super.key, this.currentConspect});

  static Future<void> show(BuildContext context, {Conspect? currentConspect}) {
    return showDialog(
      context: context,
      builder: (ctx) => RnoDialog(currentConspect: currentConspect),
    );
  }

  @override
  State<RnoDialog> createState() => _RnoDialogState();
}

class _RnoDialogState extends State<RnoDialog> {
  final TextEditingController _errorsController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentConspect != null) {
      // Предзаполняем подсказки по предмету
      if (widget.currentConspect!.subject.toLowerCase().contains('русск')) {
        _errorsController.text = 'написали "вада" вместо "вода"\nзабыли мягкий знак в слове "пальто"\nнаписали "жыли" с буквой Ы';
      } else if (widget.currentConspect!.subject.toLowerCase().contains('матем')) {
        _errorsController.text = 'в задаче сложили 5 столов и 2 килограмма\nзабыли переход через десяток: 14 - 6 = 9\nперепутали порядок множителей 4 * 2';
      }
    }
  }

  @override
  void dispose() {
    _errorsController.dispose();
    super.dispose();
  }

  Future<void> _generateRno() async {
    final rawText = _errorsController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите хотя бы одну ошибку учеников')),
      );
      return;
    }

    final errors = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    setState(() => _isGenerating = true);

    try {
      final appProvider = context.read<AppProvider>();
      final gptService = appProvider.yandexGptService;

      final topic = widget.currentConspect?.topic ?? 'Отработка типичных ошибок';
      final method = widget.currentConspect?.methodName ?? 'Классическая методика';
      final ageGroup = widget.currentConspect?.ageGroup ?? 'grade_1';
      final subject = widget.currentConspect?.subject ?? 'Русский язык и математика';

      final prompts = PromptBuilder.buildRnoPrompt(
        studentErrors: errors,
        topic: topic,
        method: method,
        ageGroup: ageGroup,
        subject: subject,
      );

      final generatedText = await gptService.generateConspect(
        systemPrompt: prompts['systemPrompt']!,
        userPrompt: prompts['userPrompt']!,
        temperature: 0.4,
        maxTokens: 3000,
      );

      final rnoConspect = Conspect(
        id: '${DateTime.now().millisecondsSinceEpoch}_rno',
        title: 'РНО: $topic',
        methodId: widget.currentConspect?.methodId ?? 'general',
        methodName: method,
        subject: subject,
        ageGroup: ageGroup,
        topic: 'Работа над ошибками: $topic',
        duration: '15 минут',
        content: generatedText,
        generatedMaterials: const ['worksheet'],
        createdAt: DateTime.now(),
      );

      await appProvider.saveConspect(rnoConspect);

      if (mounted) {
        Navigator.of(context).pop(); // закрываем диалог
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConspectViewScreen(existingConspect: rnoConspect),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка генерации листа РНО: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.healing_rounded, color: AppColors.accentAmber, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Работа над ошибками (РНО)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Генератор персонального мини-тренажёра', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите ошибки учеников с последней проверочной работы (по одной на строке):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _errorsController,
              maxLines: 5,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Пример:\nнаписали "пальто" без ь\nошибка в слове "лесной"\nсложили рубли с конфетами',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2432) : const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primaryIndigo, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'YandexGPT определит корень дефицитов и составит лист с правилом-секретом и 3–4 точечными заданиями на 10 минут.',
                      style: TextStyle(fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryIndigo,
            foregroundColor: Colors.white,
          ),
          onPressed: _isGenerating ? null : _generateRno,
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Создать лист РНО'),
        ),
      ],
    );
  }
}
