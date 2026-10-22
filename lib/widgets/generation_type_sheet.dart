// Widget for selecting multiple generation types via a bottom sheet
import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme.dart';
import '../screens/new_conspect_screen.dart';

class GenerationTypeSheet extends StatefulWidget {
  final Function(Set<GenerationType>)? onSelectionChanged;
  final Set<GenerationType> initialSelection;

  const GenerationTypeSheet({
    Key? key,
    this.onSelectionChanged,
    this.initialSelection = const {GenerationType.conspect},
  }) : super(key: key);

  @override
  State<GenerationTypeSheet> createState() => _GenerationTypeSheetState();
}

class _GenerationTypeSheetState extends State<GenerationTypeSheet> {
  late Set<GenerationType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set<GenerationType>.from(widget.initialSelection);
  }

  void _toggleType(GenerationType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
      widget.onSelectionChanged?.call(_selectedTypes);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedTypes = Set<GenerationType>.from(GenerationType.values);
      widget.onSelectionChanged?.call(_selectedTypes);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTypes.clear();
      widget.onSelectionChanged?.call(_selectedTypes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canProceed = _selectedTypes.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите материалы для генерации',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Можно выбрать несколько материалов',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            
            // Selection controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: Text(
                    'Выбрать все',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Очистить',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Generation type items
            ...GenerationType.values.map((type) => _item(context, type)).toList(),
            
            const SizedBox(height: 20),
            
            // Proceed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        Navigator.of(context).pop(); // close sheet
                        Navigator.of(context).push(FadeSlidePageRoute(
                          page: NewConspectScreen(
                            selectedMaterials: _selectedTypes,
                          ),
                        ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Продолжить (${_selectedTypes.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, GenerationType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTypes.contains(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isDark
                  ? Colors.white24
                  : Colors.black12,
          width: isSelected ? 1.5 : 1,
        ),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleType(type),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleType(type),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  type.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isDark
                          ? Colors.white70
                          : Colors.black87,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isDark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}