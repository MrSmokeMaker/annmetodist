import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../models/pdf_style_config.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme.dart';
import 'glass_card.dart';

/// Модальное окно тонкой настройки стилей перед экспортом PDF
class PdfCustomizerModal extends StatefulWidget {
  final Conspect conspect;
  final PdfMaterialType initialMaterialType;
  final bool exportAllCombined;

  const PdfCustomizerModal({
    super.key,
    required this.conspect,
    this.initialMaterialType = PdfMaterialType.worksheet,
    this.exportAllCombined = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Conspect conspect,
    PdfMaterialType initialMaterialType = PdfMaterialType.worksheet,
    bool exportAllCombined = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PdfCustomizerModal(
        conspect: conspect,
        initialMaterialType: initialMaterialType,
        exportAllCombined: exportAllCombined,
      ),
    );
  }

  @override
  State<PdfCustomizerModal> createState() => _PdfCustomizerModalState();
}

class _PdfCustomizerModalState extends State<PdfCustomizerModal> {
  late PdfPreset _selectedPreset;
  late PdfFontSize _selectedFontSize;
  late PdfMarginSize _selectedMarginSize;
  late PdfDensity _selectedDensity;
  late bool _showStudentHeader;
  late PdfMaterialType _selectedMaterial;
  late bool _exportAll;

  late TextEditingController _schoolCtrl;
  late TextEditingController _teacherCtrl;
  int _selectedBrandColor = 0xFF1E40AF;
  bool _isExporting = false;

  final List<(String, int, Color)> _brandColors = const [
    ('Синий', 0xFF1E40AF, Color(0xFF1E40AF)),
    ('Бордовый', 0xFF991B1B, Color(0xFF991B1B)),
    ('Изумрудный', 0xFF15803D, Color(0xFF15803D)),
    ('Индиго', 0xFF4338CA, Color(0xFF4338CA)),
    ('Графитовый', 0xFF1E293B, Color(0xFF1E293B)),
  ];

  @override
  void initState() {
    super.initState();
    _exportAll = widget.exportAllCombined;
    _selectedMaterial = widget.initialMaterialType;

    // Начальный пресет
    _selectedPreset = PdfPreset.schoolStandard;
    final initialConfig = PdfStyleConfig.fromPreset(_selectedPreset);
    _selectedFontSize = initialConfig.fontSize;
    _selectedMarginSize = initialConfig.marginSize;
    _selectedDensity = initialConfig.density;
    _showStudentHeader = initialConfig.showStudentHeader;
    _selectedBrandColor = initialConfig.brandColorHex;

    _schoolCtrl = TextEditingController(text: 'Лицей №1');
    _teacherCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  void _onPresetChanged(PdfPreset preset) {
    setState(() {
      _selectedPreset = preset;
      final cfg = PdfStyleConfig.fromPreset(
        preset,
        defaultSchool: _schoolCtrl.text.isNotEmpty ? _schoolCtrl.text : 'Гимназия №1',
        defaultTeacher: _teacherCtrl.text,
      );
      _selectedFontSize = cfg.fontSize;
      _selectedMarginSize = cfg.marginSize;
      _selectedDensity = cfg.density;
      _selectedBrandColor = cfg.brandColorHex;
    });
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final provider = context.read<AppProvider>();
    final isPro = provider.isProUser;

    final config = PdfStyleConfig(
      preset: _selectedPreset,
      fontSize: _selectedFontSize,
      marginSize: _selectedMarginSize,
      density: _selectedDensity,
      showStudentHeader: _showStudentHeader,
      schoolName: _schoolCtrl.text.trim(),
      teacherName: _teacherCtrl.text.trim(),
      brandColorHex: _selectedBrandColor,
    );

    try {
      if (_exportAll) {
        await PdfExportService.exportAllMaterialsCombinedPdf(
          widget.conspect,
          isPro: isPro,
          styleConfig: config,
        );
      } else {
        await PdfExportService.exportMaterialPdf(
          widget.conspect,
          _selectedMaterial,
          isPro: isPro,
          styleConfig: config,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Документ PDF успешно сформирован!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка генерации PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Параметры оформления PDF',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        Text(
                          'Выберите готовый стиль или настройте детали',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Settings Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Material Selector (if not fixed)
                  const Text(
                    'Документ для печати',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMaterialChip('Рабочий лист', PdfMaterialType.worksheet, Icons.assignment_outlined),
                      _buildMaterialChip('Конспект урока', PdfMaterialType.conspect, Icons.menu_book_rounded),
                      _buildMaterialChip('Домашнее задание', PdfMaterialType.homework, Icons.home_work_outlined),
                      _buildAllCombinedChip(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Preset Cards (4 Presets)
                  const Text(
                    'Готовые стили оформления',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPresetCard(
                          preset: PdfPreset.ecoPrint,
                          icon: '🌿',
                          title: 'Eco-Print',
                          subtitle: 'Монохром, -50% тонера',
                          tag: '0 ₽ БЕСПЛАТНО',
                          tagColor: const Color(0xFF10B981),
                          accentColor: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPresetCard(
                          preset: PdfPreset.schoolStandard,
                          icon: '📚',
                          title: 'Школьный',
                          subtitle: 'ГОСТ, синие рамки 65°',
                          tag: 'ПРАКТИК',
                          tagColor: const Color(0xFF2563EB),
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPresetCard(
                          preset: PdfPreset.premiumTextbook,
                          icon: '🎨',
                          title: 'Премиум Учебник',
                          subtitle: 'Цветные плашки, маскоты',
                          tag: 'METODIST PRO',
                          tagColor: const Color(0xFF7C3AED),
                          accentColor: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPresetCard(
                          preset: PdfPreset.schoolBranding,
                          icon: '👑',
                          title: 'Фирменный стиль',
                          subtitle: 'Школа, герб, ФИО учителя',
                          tag: 'ДИРЕКТОР',
                          tagColor: const Color(0xFFD97706),
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // School Branding inputs if School Branding preset is selected
                  if (_selectedPreset == PdfPreset.schoolBranding) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('👑', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Text(
                                'Брендирование школы (Тариф Директор)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolCtrl,
                            decoration: InputDecoration(
                              labelText: 'Название школы / лицея в шапке',
                              hintText: 'МБОУ СОШ №1 или Лицей "Вектор"',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _teacherCtrl,
                            decoration: InputDecoration(
                              labelText: 'ФИО учителя (необязательно)',
                              hintText: 'Иванова М. С.',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Фирменный акцентный цвет:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _brandColors.map((c) {
                              final isSelected = _selectedBrandColor == c.$2;
                              return ChoiceChip(
                                label: Text(c.$1, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                                selected: isSelected,
                                selectedColor: c.$3,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedBrandColor = c.$2);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Fine-tuning Details Header
                  const Text(
                    'Тонкие настройки деталей',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  // 1. Font Size
                  _buildDetailRow(
                    icon: Icons.format_size_rounded,
                    title: 'Размер текста',
                    child: SegmentedButton<PdfFontSize>(
                      segments: const [
                        ButtonSegment(value: PdfFontSize.compact, label: Text('Компактный', style: TextStyle(fontSize: 10.5))),
                        ButtonSegment(value: PdfFontSize.standard, label: Text('Обычный', style: TextStyle(fontSize: 10.5))),
                        ButtonSegment(value: PdfFontSize.large, label: Text('Крупный', style: TextStyle(fontSize: 10.5))),
                      ],
                      selected: {_selectedFontSize},
                      onSelectionChanged: (set) => setState(() => _selectedFontSize = set.first),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Margins
                  _buildDetailRow(
                    icon: Icons.space_bar_rounded,
                    title: 'Поля страницы',
                    child: SegmentedButton<PdfMarginSize>(
                      segments: const [
                        ButtonSegment(value: PdfMarginSize.compact, label: Text('Узкие 10мм', style: TextStyle(fontSize: 10.5))),
                        ButtonSegment(value: PdfMarginSize.standard, label: Text('Стандарт 15мм', style: TextStyle(fontSize: 10.5))),
                        ButtonSegment(value: PdfMarginSize.wide, label: Text('Широкие 20мм', style: TextStyle(fontSize: 10.5))),
                      ],
                      selected: {_selectedMarginSize},
                      onSelectionChanged: (set) => setState(() => _selectedMarginSize = set.first),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Density
                  _buildDetailRow(
                    icon: Icons.density_medium_rounded,
                    title: 'Плотность заданий',
                    child: SegmentedButton<PdfDensity>(
                      segments: const [
                        ButtonSegment(value: PdfDensity.compact, label: Text('Плотная', style: TextStyle(fontSize: 10.5))),
                        ButtonSegment(value: PdfDensity.comfortable, label: Text('Просторная', style: TextStyle(fontSize: 10.5))),
                      ],
                      selected: {_selectedDensity},
                      onSelectionChanged: (set) => setState(() => _selectedDensity = set.first),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Student Header Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Строка "Ученик: ____  Класс: ____  Дата: ____"', style: TextStyle(fontSize: 12.5)),
                    subtitle: Text('Поле для подписи листа ребенком', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    value: _showStudentHeader,
                    onChanged: (val) => setState(() => _showStudentHeader = val),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _isExporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  _isExporting
                      ? 'Создание PDF...'
                      : (_exportAll ? 'Сформировать весь комплект PDF' : 'Сформировать и распечатать PDF'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isExporting ? null : _handleExport,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialChip(String title, PdfMaterialType type, IconData icon) {
    final isSelected = !_exportAll && _selectedMaterial == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
      label: Text(title, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      onSelected: (val) {
        if (val) {
          setState(() {
            _exportAll = false;
            _selectedMaterial = type;
          });
        }
      },
    );
  }

  Widget _buildAllCombinedChip() {
    return ChoiceChip(
      avatar: Icon(Icons.all_inclusive_rounded, size: 14, color: _exportAll ? Colors.white : Colors.grey),
      label: Text('Весь комплект', style: TextStyle(fontSize: 11, color: _exportAll ? Colors.white : null)),
      selected: _exportAll,
      selectedColor: const Color(0xFF059669),
      onSelected: (val) {
        if (val) {
          setState(() {
            _exportAll = true;
          });
        }
      },
    );
  }

  Widget _buildPresetCard({
    required PdfPreset preset,
    required String icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Color accentColor,
  }) {
    final isSelected = _selectedPreset == preset;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _onPresetChanged(preset),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(isDark ? 0.20 : 0.08)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: tagColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: isSelected ? accentColor : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: child),
      ],
    );
  }
}
