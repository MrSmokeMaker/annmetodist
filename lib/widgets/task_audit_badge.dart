import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_evaluation.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class TaskAuditBadge extends StatefulWidget {
  final TaskEvaluation evaluation;

  const TaskAuditBadge({
    super.key,
    required this.evaluation,
  });

  @override
  State<TaskAuditBadge> createState() => _TaskAuditBadgeState();
}

class _TaskAuditBadgeState extends State<TaskAuditBadge> {
  bool _isGeneratingArt = false;
  String? _artBase64;

  Future<void> _generateArt() async {
    final prompt = widget.evaluation.yandexArtPrompt;
    if (prompt == null || _isGeneratingArt) return;

    setState(() => _isGeneratingArt = true);
    try {
      final appProvider = context.read<AppProvider>();
      final artService = appProvider.yandexArtService;
      final imageResult = await artService.generateImage(
        prompt: prompt,
        type: widget.evaluation.taskIndex % 2 == 1 ? 'coloring' : 'card',
        label: prompt,
      );

      if (mounted) {
        setState(() {
          _artBase64 = imageResult;
          _isGeneratingArt = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingArt = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка вызова YandexART: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eval = widget.evaluation;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryIndigo.withOpacity(isDark ? 0.3 : 0.2),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded, size: 16, color: AppColors.primaryIndigo),
              const SizedBox(width: 6),
              const Text(
                'Оценка YandexGPT Pro:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildScoreChip('Логика', eval.logicScore),
              const SizedBox(width: 4),
              _buildScoreChip('Орфография', eval.orthographyScore),
              const SizedBox(width: 4),
              _buildScoreChip('Визуал', eval.visualScore),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• ${eval.logicNotes} | ${eval.visualNotes}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
          if (eval.yandexArtPrompt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '🎨 YandexART: ${eval.yandexArtPrompt}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.accentCyan : AppColors.primaryIndigo,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isGeneratingArt ? null : _generateArt,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppGradients.cyanTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isGeneratingArt
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Создать арт',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
          if (_artBase64 != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(_artBase64!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, int score) {
    Color color = AppColors.success;
    if (score < 8) color = AppColors.accentAmber;
    if (score < 6) color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.6),
      ),
      child: Text(
        '$label $score/10',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildImageWidget(String data) {
    if (data.startsWith('data:image')) {
      final base64Str = data.split(',').last;
      return Image.memory(
        base64Decode(base64Str),
        height: 140,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      data,
      height: 140,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
  }
}
