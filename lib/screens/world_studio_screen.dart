import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_world_config.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class WorldStudioScreen extends StatefulWidget {
  const WorldStudioScreen({super.key});

  @override
  State<WorldStudioScreen> createState() => _WorldStudioScreenState();
}

class _WorldStudioScreenState extends State<WorldStudioScreen> {
  late CustomWorldConfig _config;
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _mascotNameCtrl;
  late TextEditingController _missionCtrl;
  late TextEditingController _artPromptCtrl;
  late TextEditingController _newSloganCtrl;

  bool _isGeneratingArt = false;
  String _activeTab = 'mascot'; // 'mascot' | 'palette' | 'prompts' | 'preview'

  // Pre-configured school presets for quick setup
  final List<Map<String, dynamic>> _schoolPresets = [
    {
      'school': 'Лицей №1 «Интеллект»',
      'mascot': 'Учёный Кот Архимед',
      'mission': 'Миссия Лицея: От смелой гипотезы к великому открытию',
      'style': 'Советский диафильм 70-х, теплая пастель, мягкий зернистый свет',
      'primary': 0xFF4F46E5,
      'secondary': 0xFF06B6D4,
    },
    {
      'school': 'Гимназия «Корифей»',
      'mascot': 'Мудрый Беркут Олимпиец',
      'mission': 'Путь к вершинам академической чести и познания',
      'style': 'Старинная гравюра на меди, утончённая штриховка, винтажный пергамент',
      'primary': 0xFF7C3AED,
      'secondary': 0xFFF59E0B,
    },
    {
      'school': 'Физтех-Школа «Вектор»',
      'mascot': 'Робот-Навигатор Фотон',
      'mission': 'Точный расчёт, инженерная дерзость, уверенный полёт',
      'style': 'Чертёж тушью и акварельная отмывка, академическая графика',
      'primary': 0xFF0284C7,
      'secondary': 0xFF10B981,
    },
    {
      'school': 'Начальная Эко-Школа «Росток»',
      'mascot': 'Лисёнок-Исследователь Лютик',
      'mission': 'Бережное познание мира природы и радость каждого дня',
      'style': 'Акварельный скетч с четким контуром, живая ботаническая иллюстрация',
      'primary': 0xFF059669,
      'secondary': 0xFFEAB308,
    },
  ];

  final List<Color> _paletteOptions = const [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFF0284C7), // Sky
    Color(0xFF059669), // Emerald
    Color(0xFFDC2626), // Crimson
    Color(0xFFD97706), // Amber
    Color(0xFFDB2777), // Pink
    Color(0xFF475569), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _config = CustomWorldConfig.defaultLyceum();
    _schoolNameCtrl = TextEditingController(text: _config.schoolName);
    _mascotNameCtrl = TextEditingController(text: _config.mascotName);
    _missionCtrl = TextEditingController(text: _config.missionTitle);
    _artPromptCtrl = TextEditingController(text: _config.yandexArtStylePrompt);
    _newSloganCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _mascotNameCtrl.dispose();
    _missionCtrl.dispose();
    _artPromptCtrl.dispose();
    _newSloganCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _schoolNameCtrl.text = preset['school'] as String;
      _mascotNameCtrl.text = preset['mascot'] as String;
      _missionCtrl.text = preset['mission'] as String;
      _artPromptCtrl.text = preset['style'] as String;
      _config = _config.copyWith(
        schoolName: preset['school'] as String,
        mascotName: preset['mascot'] as String,
        missionTitle: preset['mission'] as String,
        yandexArtStylePrompt: preset['style'] as String,
        primaryColorHex: preset['primary'] as int,
        secondaryColorHex: preset['secondary'] as int,
        isCustomHeaderGenerated: true,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Применён шаблон: ${preset['school']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generateYandexArtHeader() async {
    setState(() => _isGeneratingArt = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _isGeneratingArt = false;
      _config = _config.copyWith(
        schoolName: _schoolNameCtrl.text.trim(),
        mascotName: _mascotNameCtrl.text.trim(),
        missionTitle: _missionCtrl.text.trim(),
        yandexArtStylePrompt: _artPromptCtrl.text.trim(),
        isCustomHeaderGenerated: true,
        updatedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Панорамная шапка листа заданий сгенерирована через YandexART!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addSlogan() {
    final text = _newSloganCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final slogans = List<String>.from(_config.teacherSlogans)..add(text);
      _config = _config.copyWith(teacherSlogans: slogans);
      _newSloganCtrl.clear();
    });
  }

  void _removeSlogan(int index) {
    setState(() {
      final slogans = List<String>.from(_config.teacherSlogans)..removeAt(index);
      _config = _config.copyWith(teacherSlogans: slogans);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDirector = context.watch<AppProvider>().isDirector;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.palette_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Студия авторских миров',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                  ),
                                ),
                                child: const Text(
                                  'ДИРЕКТОР',
                                  style: TextStyle(
                                    color: Color(0xFFA855F7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Персонализация маскота школы, стилей YandexART и палитр для PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Director Upgrade Banner if not active
            if (!isDirector)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GlassCard(
                    borderRadius: AppRadii.lg,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Студия авторских миров входит в тариф «Директор»',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '1 199 ₽ / месяц (при оплате за год) или 1 499 ₽ помесячно. Активируйте для генерации брендированных листов школы.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            context.read<AppProvider>().setTariff(TariffLevel.director);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Тариф «Директор» успешно активирован!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          child: const Text('Включить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Live Panoramic Header Preview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _buildPanoramicHeaderPreview(isDark),
              ),
            ),

            // Tab Navigation (Mascot / Palettes / Prompts / Presets)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('mascot', Icons.pets_rounded, 'Маскот & Школа'),
                      const SizedBox(width: 8),
                      _buildTabButton('palette', Icons.color_lens_rounded, 'Палитра & Слоганы'),
                      const SizedBox(width: 8),
                      _buildTabButton('prompts', Icons.brush_rounded, 'Промпты YandexART'),
                      const SizedBox(width: 8),
                      _buildTabButton('presets', Icons.auto_awesome_rounded, 'Готовые школы'),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Active Tab Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActiveTabContent(isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, IconData icon, String label) {
    final isSelected = _activeTab == tabId;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanoramicHeaderPreview(bool isDark) {
    final primary = _config.primaryColor;
    final secondary = _config.secondaryColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary.withOpacity(0.95),
                secondary.withOpacity(0.85),
                const Color(0xFF0F172A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              // Decorative background texture
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 140,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // School Emblem / Mascot avatar
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.school_rounded, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ЛИСТ ЗАДАНИЙ: ${_config.schoolName.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _config.missionTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Маскот: ${_config.mascotName} • Стиль: ${_config.yandexArtStylePrompt.split(',').first}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Teacher Encouragement Slogan Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _config.teacherSlogans.isNotEmpty
                                  ? '«${_config.teacherSlogans.first}»'
                                  : '«Вперёд к знаниям!»',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Generation trigger button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Панорамная арт-шапка YandexART',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: _isGeneratingArt
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_rounded, size: 14),
                          label: Text(
                            _isGeneratingArt ? 'Генерация...' : 'Сгенерировать арт-шапку',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isGeneratingArt ? null : _generateYandexArtHeader,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 'mascot':
        return _buildMascotSection(isDark);
      case 'palette':
        return _buildPaletteSection(isDark);
      case 'prompts':
        return _buildPromptsSection(isDark);
      case 'presets':
        return _buildPresetsSection(isDark);
      default:
        return _buildMascotSection(isDark);
    }
  }

  Widget _buildMascotSection(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Эмблема школы и персонаж-маскот',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Задайте официальное наименование образовательного учреждения и персонажа, сопровождающего ученика в листах заданий.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _schoolNameCtrl,
            decoration: InputDecoration(
              labelText: 'Название школы / лицея / гимназии',
              hintText: 'Лицей №1 «Интеллект»',
              prefixIcon: const Icon(Icons.school_outlined),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              setState(() => _config = _config.copyWith(schoolName: val.trim()));
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _mascotNameCtrl,
            decoration: InputDecoration(
              labelText: 'Имя маскота (животное / робот / сказочный персонаж)',
              hintText: 'Учёный Кот Архимед',
              prefixIcon: const Icon(Icons.pets_outlined),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              setState(() => _config = _config.copyWith(mascotName: val.trim()));
            },
          ),
          const SizedBox(height: 14),
          // Upload Emblem Button Mock
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Загрузить эмблему школы / векторный герб (SVG, PNG)'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Эмблема школы успешно прикреплена к генератору листа заданий!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteSection(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Цветовая палитра и личные фразы поддержки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Настройте фирменные цвета для колонтитулов и рамки листа заданий, а также вдохновляющие цитаты учителя.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _missionCtrl,
            decoration: InputDecoration(
              labelText: 'Слоган миссии на шапке листа',
              hintText: 'Миссия Лицея: От смелой гипотезы к великому открытию',
              prefixIcon: const Icon(Icons.flag_outlined),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              setState(() => _config = _config.copyWith(missionTitle: val.trim()));
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Основной цвет оформления (Primary):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _paletteOptions.map((color) {
              final isSelected = _config.primaryColorHex == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(primaryColorHex: color.value);
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Фразы поддержки от учителя в колонтитулах:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._config.teacherSlogans.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 12.5)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeSlogan(idx),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newSloganCtrl,
                  decoration: InputDecoration(
                    hintText: 'Добавить слоган поддержки...',
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _addSlogan,
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptsSection(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Прямое управление промптами YandexART',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Выберите художественный стиль иллюстраций или введите собственный промпт для генератора картинок к задачам.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 14),
          ...CustomWorldConfig.popularArtStyles.map((style) {
            final isChosen = _artPromptCtrl.text.trim() == style;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _artPromptCtrl.text = style;
                    _config = _config.copyWith(yandexArtStylePrompt: style);
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? const Color(0xFF6366F1).withOpacity(0.18)
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChosen ? const Color(0xFF6366F1) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isChosen ? const Color(0xFF6366F1) : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          style,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _artPromptCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Собственный художественный стиль для YandexART',
              hintText: 'Например: советский диафильм, акварельный скетч с тушью...',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              setState(() => _config = _config.copyWith(yandexArtStylePrompt: val.trim()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(bool isDark) {
    return Column(
      children: _schoolPresets.map((preset) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppRadii.lg,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(preset['primary'] as int).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(preset['primary'] as int)),
                  ),
                  child: Icon(Icons.school, color: Color(preset['primary'] as int), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset['school'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Маскот: ${preset['mascot']} • ${preset['mission']}',
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
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _applyPreset(preset),
                  child: const Text('Применить', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
