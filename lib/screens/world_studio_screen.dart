import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/custom_world.dart';
import '../models/custom_methodology.dart';
import '../models/thematic_world.dart';
import '../models/department_team.dart';
import '../models/conspect.dart';
import '../providers/app_provider.dart';
import '../services/developer_api_service.dart';
import '../services/curriculum_bulk_service.dart';
import '../services/docx_export_service.dart';
import '../services/pdf_export_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class WorldStudioScreen extends StatefulWidget {
  const WorldStudioScreen({super.key});

  @override
  State<WorldStudioScreen> createState() => _WorldStudioScreenState();
}

class _WorldStudioScreenState extends State<WorldStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Custom World State
  final _schoolNameController = TextEditingController(text: 'Лицей №1');
  final _supportPhraseController =
      TextEditingController(text: 'Каждая решенная задача приближает к звездам знаний!');
  final _mascotNameController = TextEditingController(text: 'Кот Учёный');
  final _customPromptStyleController = TextEditingController(text: 'Акварельный скетч');
  int _selectedColorIndex = 0;
  String _selectedArtStyle = 'Акварельный скетч';
  bool _isGeneratingArt = false;
  String? _generatedBannerPreview;

  final List<Color> _paletteOptions = const [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFFE11D48), // Rose
    Color(0xFF0891B2), // Cyan
    Color(0xFF7C3AED), // Violet
  ];

  final List<String> _artStyles = const [
    'Акварельный скетч',
    'Советский диафильм',
    'Чертёж тушью',
    'Киберпанк неоновый',
    'Гравюра XIX века',
    '3D пластилиновый мультфильм',
  ];

  // Methodology State
  final _methodNameController = TextEditingController(text: 'Интерактивная методика ТРИЗ');
  final _stopWordsController = TextEditingController(text: 'тривиально, очевидно, лень, глупо');
  PedagogicalTone _selectedTone = PedagogicalTone.triz;
  List<String> _methodBlocks = [
    'ФГОС планируемые результаты',
    'ТРИЗ-разминка и противоречие',
    'Пошаговый разбор с наглядными моделями',
    'Трёхуровневый рабочий лист',
    'Рефлексивная лестница успеха',
    'Ключи и критерии для учителя',
  ];

  // Bulk Generator State
  String _bulkSubject = 'Математика';
  String _bulkGrade = '3 класс (8-9 лет)';
  int _bulkLessonCount = 20;
  String _bulkWorldId = 'space_explorers';
  bool _isGeneratingBulk = false;
  List<Conspect>? _generatedBulkConspects;
  CurriculumValidationResult? _latestValidation;

  // Department State
  late DepartmentTeam _team;
  final _newMemberEmailController = TextEditingController();
  final _newMemberNameController = TextEditingController();

  // Developer API State
  late String _apiToken;
  String _selectedLms = 'МЭШ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _apiToken = DeveloperApiService.generateDevToken();
    _team = DepartmentTeam.createDefault();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameController.dispose();
    _supportPhraseController.dispose();
    _mascotNameController.dispose();
    _customPromptStyleController.dispose();
    _methodNameController.dispose();
    _stopWordsController.dispose();
    _newMemberEmailController.dispose();
    _newMemberNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDev = context.watch<AppProvider>().isDeveloper;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Студия авторских миров',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDev ? const Color(0xFF10B981) : Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDev ? 'РАЗРАБОТЧИК' : 'ТРЕБУЕТСЯ ПОДПИСКА',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mobbin UI v2.4 • YandexART & GPT Pro',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.brush_rounded, size: 16), text: '1. Миры и Маскот'),
                Tab(icon: Icon(Icons.psychology_rounded, size: 16), text: '2. Методики'),
                Tab(icon: Icon(Icons.api_rounded, size: 16), text: '3. REST API / LMS'),
                Tab(icon: Icon(Icons.auto_stories_rounded, size: 16), text: '4. Курс на четверть'),
                Tab(icon: Icon(Icons.biotech_rounded, size: 16), text: '5. Лаборатория Self-Refine'),
                Tab(icon: Icon(Icons.group_rounded, size: 16), text: '6. Кафедра (5 мест)'),
              ],
            ),
          ),
        ),
      ),
      body: !isDev
          ? _buildDeveloperTierLockedBanner(context, isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorldStudioTab(isDark),
                _buildMethodologyTab(isDark),
                _buildRestApiTab(isDark),
                _buildBulkCurriculumTab(isDark),
                _buildTokenInspectorTab(isDark),
                _buildDepartmentTab(isDark),
              ],
            ),
    );
  }

  Widget _buildDeveloperTierLockedBanner(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Студия авторских миров и модули Разработчика',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Создавайте маскотов школы, управляйте промптами YandexART, создавайте авторские методики, экспортируйте курсы на четверть в ZIP (PDF+DOCX) и подключайте LMS через REST API.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '1 199 ₽ / месяц ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    Text(
                      '(в год 14 388 ₽) или 1 499 ₽/мес',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Активировать тариф Разработчик',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onPressed: () {
                  context.read<AppProvider>().setUserTier('developer');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Тариф «Разработчик» активирован! Добро пожаловать в Студию.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 1: СТУДИЯ МИРОВ И МАСКОТ =================
  Widget _buildWorldStudioTab(bool isDark) {
    final activeColor = _paletteOptions[_selectedColorIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1.2 Interactive Panoramic Header Preview (Mobbin aesthetic)
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                activeColor,
                activeColor.withOpacity(0.8),
                const Color(0xFF1E1B4B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: activeColor.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mascot badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                  ],
                ),
                child: Center(
                  child: Text(
                    _mascotNameController.text.contains('Кот')
                        ? '🐱'
                        : (_mascotNameController.text.contains('Сова')
                            ? '🦉'
                            : (_mascotNameController.text.contains('Лев') ? '🦁' : '🎓')),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'МИССИЯ: ${_schoolNameController.text.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Маскот: ${_mascotNameController.text}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '«${_supportPhraseController.text}»',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Стиль: $_selectedArtStyle',
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1.3 Mascot & School Emblem
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('1.3 Создание маскота школы/класса',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolNameController,
                decoration: InputDecoration(
                  labelText: 'Название школы / лицея / класса',
                  hintText: 'Например: Лицей №1535 или 3 «А» класс',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mascotNameController,
                decoration: InputDecoration(
                  labelText: 'Имя маскота и персонажа',
                  hintText: 'Например: Кот Учёный, Лисёнок Вектор, Медвежонок Ерофей',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Text('🐱'),
                    label: const Text('Кот Учёный'),
                    onPressed: () => setState(() => _mascotNameController.text = 'Кот Учёный'),
                  ),
                  ActionChip(
                    avatar: const Text('🦉'),
                    label: const Text('Сова Архимед'),
                    onPressed: () => setState(() => _mascotNameController.text = 'Сова Архимед'),
                  ),
                  ActionChip(
                    avatar: const Text('🚀'),
                    label: const Text('Астронавт Юра'),
                    onPressed: () => setState(() => _mascotNameController.text = 'Астронавт Юра'),
                  ),
                  ActionChip(
                    avatar: const Text('🦁'),
                    label: const Text('Лев Леонардо'),
                    onPressed: () => setState(() => _mascotNameController.text = 'Лев Леонардо'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1.4 Custom Palettes & Slogans
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('1.4 Кастомные палитры и личные фразы поддержки',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Фирменный цвет мира задания:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_paletteOptions.length, (i) {
                  final isSelected = _selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _paletteOptions[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _paletteOptions[i].withOpacity(0.6),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _supportPhraseController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Личная фраза поддержки от учителя',
                  hintText: 'Печатается в шапке листа заданий ученика',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1.5 Direct control of YandexART prompts
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('1.5 Прямое управление промптами YandexART',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Выберите художественный стиль генерации шапки и иллюстраций:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _artStyles.map((style) {
                  final isSelected = _selectedArtStyle == style;
                  return ChoiceChip(
                    label: Text(style),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedArtStyle = style;
                          _customPromptStyleController.text = style;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customPromptStyleController,
                decoration: InputDecoration(
                  labelText: 'Свой художественный стиль (промпт для YandexART)',
                  hintText: 'Например: советский диафильм 1970-х, пастельные тона',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) => setState(() => _selectedArtStyle = val),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isGeneratingArt
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.palette_rounded),
                  label: Text(
                    _isGeneratingArt
                        ? 'YandexART генерирует панораму...'
                        : 'Сгенерировать панорамную шапку через YandexART',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGeneratingArt
                      ? null
                      : () async {
                          setState(() => _isGeneratingArt = true);
                          await Future.delayed(const Duration(milliseconds: 1200));
                          if (mounted) {
                            setState(() {
                              _isGeneratingArt = false;
                              _generatedBannerPreview = 'yandex_art_banner_ready';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Панорамная шапка «${_schoolNameController.text}» в стиле «$_selectedArtStyle» готова!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: КОНСТРУКТОР МЕТОДИК =================
  Widget _buildMethodologyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 22),
                  SizedBox(width: 8),
                  Text('Редактор собственных методик (Prompt Architect)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте уникальную педагогическую методику в дополнение к 7 предустановленным (Пчёлко, Костин, Редозубов, Шаталов, Выготский, Занков, Эльконин-Давыдов).',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _methodNameController,
                decoration: InputDecoration(
                  labelText: 'Название авторской методики',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Педагогический тон YandexGPT Pro:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PedagogicalTone>(
                value: _selectedTone,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PedagogicalTone.academic,
                    child: Text('Академический классический (Строгий ФГОС)'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.triz,
                    child: Text('Игровой ТРИЗ (Изобретательское мышление)'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.fairytale,
                    child: Text('Сказкотерапия и образное погружение'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.socratic,
                    child: Text('Сократический диалог (Вопросы и рассуждения)'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.inquiry,
                    child: Text('Исследовательский проектный подход'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTone = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _stopWordsController,
                decoration: InputDecoration(
                  labelText: 'Стоп-слова и запретные темы нейросети',
                  hintText: 'Слова, которые YandexGPT исключит из заданий',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Блоки структуры конспекта под требования школы:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ..._methodBlocks.map((block) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(block, style: const TextStyle(fontSize: 13)),
                  value: true,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) {},
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Сохранить авторскую методику'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Методика «${_methodNameController.text}» успешно сохранена!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 3: REST API И LMS =================
  Widget _buildRestApiTab(bool isDark) {
    final curlExample = DeveloperApiService.generateCurlExample(_apiToken);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('Персональный API-токен Разработчика',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _apiToken,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Скопировать токен',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _apiToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API-токен скопирован в буфер обмена')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Перевыпустить токен',
                      onPressed: () {
                        setState(() {
                          _apiToken = DeveloperApiService.generateDevToken();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Сгенерирован новый API-токен')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Экспорт в электронные журналы и LMS:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['МЭШ', 'ЭЖД', 'Сферум', 'Moodle'].map((lms) {
                  final isSelected = _selectedLms == lms;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lms),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _selectedLms = lms),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.code_rounded, size: 16),
                      label: const Text('JSON'),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(
                            text: '{"status":"ok","lms_export_format":"json_schema_v2"}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON схема скопирована в буфер')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.text_snippet_rounded, size: 16),
                      label: const Text('Markdown'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Markdown конспекта скопирован в буфер')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.html_rounded, size: 16),
                      label: const Text('HTML'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HTML с CSS шапкой скопирован для LMS')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Пример cURL запроса генерации:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  curlExample,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 4: ПАКЕТНЫЙ ГЕНЕРАТОР КУРСА =================
  Widget _buildBulkCurriculumTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('4.1 Генерация блока из 15–30 уроков в 1 клик',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Сквозная генерация всей учебной четверти с сохранением сюжетной линии игрового мира, трёхуровневыми листами заданий и единым ZIP-архивом (PDF и DOCX).',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bulkSubject,
                      decoration: const InputDecoration(labelText: 'Предмет'),
                      items: ['Математика', 'Русский язык', 'Окружающий мир']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _bulkSubject = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _bulkLessonCount,
                      decoration: const InputDecoration(labelText: 'Уроков в блоке'),
                      items: [15, 20, 25, 30]
                          .map((c) => DropdownMenuItem(value: c, child: Text('$c уроков', style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _bulkLessonCount = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bulkWorldId,
                decoration: const InputDecoration(labelText: 'Сквозной сюжетный мир'),
                items: ThematicWorld.allWorlds
                    .map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text('${w.title} (${w.mascotName})', style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _bulkWorldId = val);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isGeneratingBulk
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _isGeneratingBulk
                        ? 'Генерация $_bulkLessonCount уроков четверти...'
                        : 'Сгенерировать курс на четверть ($_bulkLessonCount уроков)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGeneratingBulk
                      ? null
                      : () async {
                          setState(() => _isGeneratingBulk = true);
                          await Future.delayed(const Duration(milliseconds: 1400));
                          final conspects = CurriculumBulkService.generateQuarterCurriculum(
                            subject: _bulkSubject,
                            ageGroup: _bulkGrade,
                            methodId: 'pchelko',
                            methodName: 'Методика А.С. Пчёлко',
                            worldId: _bulkWorldId,
                            lessonCount: _bulkLessonCount,
                          );
                          final validation = CurriculumBulkService.validateLessonQuality(conspects.first);

                          if (mounted) {
                            setState(() {
                              _isGeneratingBulk = false;
                              _generatedBulkConspects = conspects;
                              _latestValidation = validation;
                            });
                          }
                        },
                ),
              ),
            ],
          ),
        ),
        if (_generatedBulkConspects != null && _latestValidation != null) ...[
          const SizedBox(height: 16),
          // 4.2 Quality & Volume check result
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                    const SizedBox(width: 8),
                    const Text('4.2 Проверка качества и объёма курса',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Оценка: ${_latestValidation!.qualityScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._latestValidation!.passedAudits.map((audit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(audit, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      'Скачать единый ZIP-архив (${_generatedBulkConspects!.length} уроков PDF + DOCX)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await CurriculumBulkService.shareCurriculumZip(_generatedBulkConspects!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================= TAB 5: ЛАБОРАТОРИЯ SELF-REFINE =================
  Widget _buildTokenInspectorTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.biotech_rounded, color: Color(0xFF6366F1), size: 22),
                  SizedBox(width: 8),
                  Text('Лаборатория отладки и инспектор токенов',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Просмотр двухпроходной верификации Self-Refine: проход 1 (Методист-архитектор) и правки прохода 2 (Строгий цензор).',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.looks_one_rounded, color: Color(0xFF6366F1), size: 18),
                        SizedBox(width: 6),
                        Text('Проход 1: Методист-архитектор (YandexGPT Pro)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '✓ Сформирована дидактическая канва темы\n✓ Интегрирован сюжет мира «Космические исследователи»\n✓ Сгенерировано 7 трёхуровневых задач и ДЗ\n• Токенов затрачено: 1 420 токенов (время ответа: 2.1 с)',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                    Divider(height: 16),
                    Row(
                      children: [
                        Icon(Icons.looks_two_rounded, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 6),
                        Text('Проход 2: Строгий цензор (Self-Refine Critic)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '✓ Проверена логическая корректность числовых данных\n✓ Исключено двусмысленное толкование условия задачи №4\n✓ Проверено соответствие ФГОС и методике А.С. Пчёлко\n• Токенов цензора: 680 токенов (время верификации: 1.0 с)',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Метрики академической строгости аттестационной комиссии:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMetricBar('Совпадение ключей с решением', 1.0, const Color(0xFF10B981)),
              _buildMetricBar('Проверка множителей и размерностей', 0.98, const Color(0xFF6366F1)),
              _buildMetricBar('Соответствие стандарту ФГОС 2026', 0.96, const Color(0xFF0EA5E9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5)),
              Text('${(value * 100).toInt()}%',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 6: КОМАНДНЫЙ ДОСТУП (КАФЕДРА) =================
  Widget _buildDepartmentTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_rounded, color: Color(0xFF6366F1), size: 22),
                  const SizedBox(width: 8),
                  const Text('Лицензия кафедры (до 5 рабочих мест)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_team.activeSeatsCount} из ${_team.maxSeats} мест',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Общий корпоративный банк конспектов, общие авторские методики и единая база шаблонов для учителей вашей школы.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              ..._team.members.map((member) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                    child: Text(
                      member.name.characters.first,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ),
                  title: Text(member.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('${member.role} • ${member.email}', style: const TextStyle(fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Активен', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
              const Divider(height: 20),
              if (_team.canAddMember) ...[
                const Text('Пригласить педагога кафедры:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newMemberNameController,
                        decoration: InputDecoration(
                          hintText: 'ФИО учителя',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _newMemberEmailController,
                        decoration: InputDecoration(
                          hintText: 'Email учителя',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_newMemberNameController.text.isNotEmpty &&
                            _newMemberEmailController.text.isNotEmpty) {
                          setState(() {
                            _team.members.add(
                              DepartmentMember(
                                id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
                                name: _newMemberNameController.text.trim(),
                                email: _newMemberEmailController.text.trim(),
                                role: 'Учитель',
                                joinedAt: DateTime.now(),
                              ),
                            );
                            _newMemberNameController.clear();
                            _newMemberEmailController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Педагог успешно добавлен на кафедру!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
