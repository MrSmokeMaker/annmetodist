// Widget for selecting generation type via a bottom sheet
import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme.dart';
import '../screens/new_conspect_screen.dart';
import '../screens/worksheet_screen.dart';
import '../screens/homework_screen.dart';

class GenerationTypeSheet extends StatelessWidget {
  const GenerationTypeSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите тип генерации',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...GenerationType.values.map((type) => _item(context, type)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, GenerationType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(type.icon, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(type.label),
      subtitle: Text(type.description),
      onTap: () {
        Navigator.of(context).pop(); // close sheet
        // Navigate to appropriate screen
        switch (type) {
          case GenerationType.conspect:
            Navigator.of(context).push(FadeSlidePageRoute(page: const NewConspectScreen()));
            break;
          case GenerationType.worksheet:
            Navigator.of(context).push(FadeSlidePageRoute(page: const WorksheetScreen()));
            break;
          case GenerationType.homework:
            Navigator.of(context).push(FadeSlidePageRoute(page: const HomeworkScreen()));
            break;
        }
      },
    );
  }
}
