// Widget for selecting generation types via a bottom sheet with bundle pack support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../screens/new_conspect_screen.dart';
import '../screens/profile_screen.dart';

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
        if (_selectedTypes.length > 1) {
          _selectedTypes.remove(type);
        }
      } else {
        _selectedTypes.add(type);
      }
      widget.onSelectionChanged?.call(_selectedTypes);
    });
  }

  void _selectBundleAll() {
    setState(() {
      _selectedTypes = Set<GenerationType>.from(GenerationType.values);
      widget.onSelectionChanged?.call(_selectedTypes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final hasBundleAccess = provider.hasPackageBundleAccess;
    final isFullBundleSelected = _selectedTypes.length == GenerationType.values.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141724) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Создать материалы',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Выберите отдельные материалы или сгенерируйте полный комплект в 1 клик',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Super-button: "Полный комплект (3 в 1)" for Практик / Pro
              Container(
                decoration: BoxDecoration(
                  gradient: hasBundleAccess
                      ? AppGradients.violetMagenta
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasBundleAccess
                      ? [
                          BoxShadow(
                            color: AppColors.primaryViolet.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasBundleAccess
                        ? () {
                            _selectBundleAll();
                            Navigator.of(context).pop();
                            Navigator.of(context).push(FadeSlidePageRoute(
                              page: NewConspectScreen(
                                selectedMaterials: Set.from(GenerationType.values),
                              ),
                            ));
                          }
                        : () {
                            // Show promo & redirect to Profile
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.stars_rounded, color: Color(0xFFFFB300)),
                                    SizedBox(width: 8),
                                    Text('Пакетная генерация 3 в 1'),
                                  ],
                                ),
                                content: const Text(
                                  'Генерация сразу конспекта, листа заданий и домашней работы одной кнопкой (3 отдельных PDF высокого качества) доступна на тарифах «Практик» (299 ₽) и «Методист Pro».',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Позже'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryIndigo,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).push(
                                        FadeSlidePageRoute(page: const ProfileScreen()),
                                      );
                                    },
                                    child: const Text('Смотреть тарифы'),
                                  ),
                                ],
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasBundleAccess ? Icons.auto_awesome : Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Полный комплект в 1 клик',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hasBundleAccess ? const Color(0xFFFFB300) : Colors.white24,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        hasBundleAccess ? '3 в 1' : 'ПРАКТИК / PRO',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: hasBundleAccess ? Colors.black87 : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Конспект + Лист заданий + Домашняя работа (3 отдельных PDF)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Или выберите отдельные элементы:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Individual Generation type items
              ...GenerationType.values.map((type) => _item(context, type, isDark)).toList(),

              const SizedBox(height: 18),

              // Proceed button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(FadeSlidePageRoute(
                      page: NewConspectScreen(
                        selectedMaterials: _selectedTypes,
                      ),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Сформировать (${_selectedTypes.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, GenerationType type, bool isDark) {
    final isSelected = _selectedTypes.contains(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryIndigo : Colors.white.withOpacity(isDark ? 0.08 : 0.15),
          width: isSelected ? 1.5 : 1,
        ),
        color: isSelected
            ? AppColors.primaryIndigo.withOpacity(isDark ? 0.15 : 0.08)
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleType(type),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primaryIndigo,
                  onChanged: (_) => _toggleType(type),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryIndigo.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? AppColors.accentCyan : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
