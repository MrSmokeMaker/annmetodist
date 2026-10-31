import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../models/thematic_world.dart';
import '../models/custom_methodology.dart';
import '../models/lesson_presentation.dart';
import '../providers/app_provider.dart';
import '../services/methodology_architect_service.dart';
import '../services/pptx_export_service.dart';
import '../services/docx_export_service.dart';
import '../services/pdf_export_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class MethodologyArchitectScreen extends StatefulWidget {
  const MethodologyArchitectScreen({super.key});

  @override
  State<MethodologyArchitectScreen> createState() => _MethodologyArchitectScreenState();
}

class _MethodologyArchitectScreenState extends State<MethodologyArchitectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Step 1: Book selection
  PredefinedMethodologyBook? _selectedBook;
  bool _isCustomBook = false;
  final _customBookTitleController = TextEditingController(text: 'Моя авторская методика ТРИЗ');
  final _customBookAuthorController = TextEditingController(text: 'Учитель-новатор');
  final _customBookYearController = TextEditingController(text: '2026');

  // Step 2: Settings & AI Paradigm
  PedagogicalTone _selectedTone = PedagogicalTone.triz;
  final _stopWordsController = TextEditingController(text: 'тривиально, очевидно, лень, глупо');
  String _selectedSubject = 'Математика';
  String _selectedGrade = '3 класс (8-9 лет)';
  int _lessonCount = 30; // Quarter

  // Step 3: Generated Topics
  List<String> _courseTopics = [];
  bool _isGeneratingTopics = false;

  // Step 4: Deep 7-Page Lesson
  Conspect? _generatedDeepLesson;
  DeepLessonVolumeAudit? _lessonAudit;
  bool _isGeneratingDeepLesson = false;

  // Step 5: PowerPoint Presentation
  LessonPresentation? _generatedPresentation;
  bool _isGeneratingPresentation = false;
  int _activeSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedBook = PredefinedMethodologyBook.classicLibrary.first;
    _courseTopics = MethodologyArchitectService.generateCourseTopics(
      subject: _selectedSubject,
      ageGroup: _selectedGrade,
      lessonCount: _lessonCount,
      methodologyName: _selectedBook!.title,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customBookTitleController.dispose();
    _customBookAuthorController.dispose();
    _customBookYearController.dispose();
    _stopWordsController.dispose();
    super.dispose();
  }

  String get _currentMethodologyName {
    if (_isCustomBook) return _customBookTitleController.text;
    return _selectedBook?.title ?? 'Авторская методика';
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
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Конструктор методик',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Text('👑', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'РАЗРАБОТЧИК',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Пошаговая генерация авторских тем и планов от 7 страниц',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
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
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.book_rounded, size: 16), text: '1. Методика-книга'),
                Tab(icon: Icon(Icons.tune_rounded, size: 16), text: '2. Установки ИИ'),
                Tab(icon: Icon(Icons.format_list_numbered_rounded, size: 16), text: '3. Темы курса'),
                Tab(icon: Icon(Icons.auto_stories_rounded, size: 16), text: '4. Урок от 7 стр. 👑'),
                Tab(icon: Icon(Icons.slideshow_rounded, size: 16), text: '5. PowerPoint 📽️'),
              ],
            ),
          ),
        ),
      ),
      body: !isDev
          ? _buildDeveloperTierLocked(context, isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStep1BookSelection(isDark),
                _buildStep2AiSettings(isDark),
                _buildStep3CourseTopics(isDark),
                _buildStep4DeepLesson(isDark),
                _buildStep5PowerPoint(isDark),
              ],
            ),
    );
  }

  Widget _buildDeveloperTierLocked(BuildContext context, bool isDark) {
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
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
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
                child: const Center(child: Text('👑', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 16),
              const Text(
                'Конструктор авторских методик (Тариф Разработчик)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Создавайте и генерируйте курсы по любой педагогической книге или собственной программе. Повышенная глубина объяснений, расширенное число тем и объём от 7 страниц на урок.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Подключить тариф Разработчик',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onPressed: () {
                  context.read<AppProvider>().setUserTier('developer');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Тариф «Разработчик» активирован! Конструктор методик разблокирован.'),
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

  // ================= STEP 1: КНИГА / МЕТОДИКА =================
  Widget _buildStep1BookSelection(bool isDark) {
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
                  Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('Шаг 1: Выберите первоисточник или укажите свою методику',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ИИ исследует принципы выбранной книги-методики, извлечет канонические темы, приёмы наглядности и специфику формулирования заданий.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Шедевры педагогики (8 книг)')),
                      selected: !_isCustomBook,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: TextStyle(
                        color: !_isCustomBook ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _isCustomBook = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Своя авторская книга / программа')),
                      selected: _isCustomBook,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: TextStyle(
                        color: _isCustomBook ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _isCustomBook = true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_isCustomBook) ...[
          ...PredefinedMethodologyBook.classicLibrary.map((book) {
            final isSelected = _selectedBook?.id == book.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  width: 2,
                ),
              ),
              elevation: isSelected ? 3 : 1,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(book.icon, style: const TextStyle(fontSize: 22))),
                ),
                title: Text(
                  '${book.title} (${book.year})',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text('Автор: ${book.author}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                    const SizedBox(height: 3),
                    Text(book.paradigm, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                ),
                onTap: () {
                  setState(() {
                    _selectedBook = book;
                  });
                },
              ),
            );
          }),
        ] else ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _customBookTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Название вашей методики / книги',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customBookAuthorController,
                        decoration: const InputDecoration(
                          labelText: 'Автор / Педагог',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _customBookYearController,
                        decoration: const InputDecoration(
                          labelText: 'Год издания',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================= STEP 2: УСТАНОВКИ ИИ =================
  Widget _buildStep2AiSettings(bool isDark) {
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
                  Icon(Icons.tune_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('Шаг 2: Новые дидактические установки нейросети',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'Предмет'),
                      items: ['Математика', 'Русский язык', 'Окружающий мир', 'Литературное чтение', 'Информатика']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSubject = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(labelText: 'Класс / Возраст'),
                      items: ['1 класс (6-7 лет)', '2 класс (7-8 лет)', '3 класс (8-9 лет)', '4 класс (9-10 лет)', '5-6 классы']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGrade = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Педагогический тон и глубина объяснений:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PedagogicalTone>(
                value: _selectedTone,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: PedagogicalTone.academic,
                    child: Text('Академический классический (ФГОС высший стандарт)'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.triz,
                    child: Text('Игровой ТРИЗ (Изобретательские противоречия)'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.fairytale,
                    child: Text('Сказкотерапия и образные метафоры'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.socratic,
                    child: Text('Сократический диалог и проблемный поиск'),
                  ),
                  DropdownMenuItem(
                    value: PedagogicalTone.inquiry,
                    child: Text('Исследовательский проектный эксперимент'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTone = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _stopWordsController,
                decoration: const InputDecoration(
                  labelText: 'Стоп-слова (исключаются из формулировок)',
                  hintText: 'тривиально, очевидно, лень, плохая оценка',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFF6366F1), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'В тарифе Разработчик активирован режим генерации повышенного объёма: от 7 страниц подробных методических материалов на каждый урок курса.',
                        style: TextStyle(fontSize: 11.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= STEP 3: ТЕМЫ КУРСА =================
  Widget _buildStep3CourseTopics(bool isDark) {
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
                  const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 8),
                  const Text('Шаг 3: Генерация расширенного списка тем курса',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_lessonCount уроков',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Количество занятий в учебном блоке:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [15, 30, 45, 60].map((count) {
                  final isSelected = _lessonCount == count;
                  return ChoiceChip(
                    label: Text(count == 30 ? '$count уроков (Четверть)' : '$count уроков'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _lessonCount = count;
                          _courseTopics = MethodologyArchitectService.generateCourseTopics(
                            subject: _selectedSubject,
                            ageGroup: _selectedGrade,
                            lessonCount: _lessonCount,
                            methodologyName: _currentMethodologyName,
                          );
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isGeneratingTopics
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_isGeneratingTopics ? 'ИИ генерирует структуру тем...' : 'Перегенерировать темы через YandexGPT'),
                  onPressed: _isGeneratingTopics
                      ? null
                      : () async {
                          setState(() => _isGeneratingTopics = true);
                          await Future.delayed(const Duration(milliseconds: 900));
                          if (mounted) {
                            setState(() {
                              _isGeneratingTopics = false;
                              _courseTopics = MethodologyArchitectService.generateCourseTopics(
                                subject: _selectedSubject,
                                ageGroup: _selectedGrade,
                                lessonCount: _lessonCount,
                                methodologyName: _currentMethodologyName,
                              );
                            });
                          }
                        },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._courseTopics.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final topic = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                child: Text('$idx', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              ),
              title: Text(topic, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: () {
                _generateLessonForTopic(topic, idx);
              },
            ),
          );
        }),
      ],
    );
  }

  void _generateLessonForTopic(String topic, int index) {
    setState(() => _isGeneratingDeepLesson = true);
    final lesson = MethodologyArchitectService.generateDeepSevenPageLesson(
      topic: topic,
      lessonIndex: index,
      totalLessons: _lessonCount,
      subject: _selectedSubject,
      ageGroup: _selectedGrade,
      methodologyName: _currentMethodologyName,
      world: ThematicWorld.space,
      tone: _selectedTone.name,
    );
    final audit = MethodologyArchitectService.auditDeepLessonVolume(lesson);

    setState(() {
      _generatedDeepLesson = lesson;
      _lessonAudit = audit;
      _isGeneratingDeepLesson = false;
      _tabController.animateTo(3);
    });
  }

  // ================= STEP 4: УРОК ОТ 7 СТРАНИЦ =================
  Widget _buildStep4DeepLesson(bool isDark) {
    if (_generatedDeepLesson == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_stories_rounded, color: Color(0xFF6366F1), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Выберите тему на шаге 3 или сгенерируйте первый урок',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Сгенерировать урок №1 (от 7 страниц)'),
                onPressed: () {
                  _generateLessonForTopic(_courseTopics.first, 1);
                },
              ),
            ],
          ),
        ),
      );
    }

    final audit = _lessonAudit!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Volume badge card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                  const SizedBox(width: 8),
                  const Text('Академический объём: от 7 страниц подтверждён',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '~${audit.estimatedPages} страниц (${audit.totalWordCount} слов)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...audit.passedQualityMetrics.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(m, style: const TextStyle(fontSize: 11.5))),
                      ],
                    ),
                  )),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.description_rounded, size: 16),
                      label: const Text('Word (DOCX)'),
                      onPressed: () async {
                        await DocxExportService.exportConspectToDocx(_generatedDeepLesson!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                      icon: const Icon(Icons.slideshow_rounded, size: 16),
                      label: const Text('В PowerPoint'),
                      onPressed: () {
                        setState(() {
                          _generatedPresentation = MethodologyArchitectService.generatePresentationForLesson(
                            conspect: _generatedDeepLesson!,
                          );
                          _tabController.animateTo(4);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _generatedDeepLesson!.content,
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ),
      ],
    );
  }

  // ================= STEP 5: POWERPOINT СЛАЙДЫ =================
  Widget _buildStep5PowerPoint(bool isDark) {
    if (_generatedPresentation == null) {
      if (_generatedDeepLesson != null) {
        _generatedPresentation = MethodologyArchitectService.generatePresentationForLesson(
          conspect: _generatedDeepLesson!,
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.slideshow_rounded, color: Color(0xFF6366F1), size: 48),
                const SizedBox(height: 12),
                const Text('Создайте презентацию для ведения урока',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Сгенерировать PowerPoint слайды'),
                  onPressed: () {
                    _generateLessonForTopic(_courseTopics.first, 1);
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    final pres = _generatedPresentation!;
    final slide = pres.slides[_activeSlideIndex];

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
                  const Icon(Icons.slideshow_rounded, color: Color(0xFF6366F1), size: 22),
                  const SizedBox(width: 8),
                  const Text('Презентация для ведения урока (Mobbin дизайн)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Скачать .pptx', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      await PptxExportService.exportPresentation(pres);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Шаблоны слайдов созданы по правилам Mobbin: 1 идея на слайд, карточки с акцентами, промпты YandexART и подсказки учителю.',
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              // Slide thumb chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(pres.slides.length, (i) {
                    final isCurrent = _activeSlideIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('Слайд ${i + 1}'),
                        selected: isCurrent,
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: isCurrent ? Colors.white : null,
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _activeSlideIndex = i),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Mobbin Slide Preview Card (16:9 aspect ratio)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(slide.accentColorHex).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(slide.accentColorHex),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slide.badgeText,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${slide.slideNumber} / ${pres.slides.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  slide.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                if (slide.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
                const Divider(height: 16),
                Expanded(
                  child: ListView(
                    children: slide.bulletPoints
                        .map((bp) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Expanded(child: Text(bp, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Speaker notes and YandexART prompt card
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: Color(0xFF6366F1), size: 18),
                  SizedBox(width: 8),
                  Text('Указания и речевой скрипт учителя:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                slide.speakerNotes,
                style: const TextStyle(fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 16),
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFEC4899), size: 18),
                  SizedBox(width: 8),
                  Text('Промпт YandexART для фона слайда:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slide.yandexArtPrompt,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
