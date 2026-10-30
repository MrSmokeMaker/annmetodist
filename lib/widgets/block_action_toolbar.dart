import 'package:flutter/material.dart';
import '../services/surgical_ai_service.dart';
import '../theme.dart';

class BlockActionToolbar extends StatelessWidget {
  final bool isLoading;
  final Function(BlockAction action, String? customTheme) onAction;

  const BlockActionToolbar({
    super.key,
    required this.isLoading,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'YandexGPT переписывает блок...',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(
            context,
            icon: Icons.refresh_rounded,
            label: 'Другое',
            tooltip: 'Сгенерировать аналогичное задание того же типа',
            onTap: () => onAction(BlockAction.regenerate, null),
          ),
          const SizedBox(width: 6),
          _buildBtn(
            context,
            icon: Icons.trending_up_rounded,
            label: 'Сложнее',
            tooltip: 'Повысить сложность до олимпиадного уровня (Детектив Pro)',
            color: const Color(0xFFF59E0B),
            onTap: () => onAction(BlockAction.makeHarder, null),
          ),
          const SizedBox(width: 6),
          _buildBtn(
            context,
            icon: Icons.trending_down_rounded,
            label: 'Проще',
            tooltip: 'Добавить визуальную опору и пошаговый алгоритм (ОВЗ)',
            color: const Color(0xFF10B981),
            onTap: () => onAction(BlockAction.makeEasier, null),
          ),
          const SizedBox(width: 6),
          _buildBtn(
            context,
            icon: Icons.theater_comedy_rounded,
            label: 'Сюжет',
            tooltip: 'Сменить тему сюжета (космос, динозавры, роботы)',
            color: const Color(0xFF8B5CF6),
            onTap: () => _showThemeDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tooltip,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? Colors.white70 : AppColors.primaryIndigo);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: effectiveColor.withOpacity(0.2),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: effectiveColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final controller = TextEditingController(text: 'Космическая экспедиция на Марс');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.theater_comedy_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Сменить сюжет задания', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Укажите тематику (например: "Магия и волшебники", "Подводный мир", "Роботы и кибернетика"):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction(BlockAction.changeTheme, controller.text.trim());
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
