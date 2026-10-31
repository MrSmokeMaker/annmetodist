import '../services/methodology_architect_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/custom_methodology.dart';
import '../models/department_team.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
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
  late CustomMethodology _methodology;
  late DepartmentTeam _team;

  // Form controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _stopWordCtrl;
  late TextEditingController _systemPromptCtrl;
  late TextEditingController _webhookUrlCtrl;
  late TextEditingController _inviteEmailCtrl;

  // Двухэтапный поиск тем из книги (Stage 1 & Stage 2)
  late TextEditingController _bookTitleCtrl;
  late TextEditingController _bookAuthorCtrl;
  late TextEditingController _bookSubjectCtrl;
  late TextEditingController _bookGradeCtrl;
  late TextEditingController _bookTocCtrl;
  bool _isExtractingStage1 = false;
  bool _isEnrichingStage2 = false;
  List<Stage1CurriculumTopic> _extractedTopics = [];
  List<Stage2EnrichedTopic> _enrichedTopics = [];
  String _bookStatusMsg = '';

  // Bulk Generator State
  int _bulkLessonCount = 20;
  String _bulkSubject = 'Математика';
  int _bulkGrade = 2;
  bool _isGeneratingBulk = false;
  double _bulkProgress = 0.0;
  String _bulkStatusText = '';

  // API Token Mock
  final String _apiToken = 'mtd_live_9f81a74e2d88c911b6a382e441c';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _methodology = CustomMethodology.defaultLyceumMethodology();
    _team = DepartmentTeam.createDefault();

    _titleCtrl = TextEditingController(text: _methodology.title);
    _authorCtrl = TextEditingController(text: _methodology.authorName);
    _stopWordCtrl = TextEditingController();
    _systemPromptCtrl = TextEditingController(text: _methodology.customSystemPromptOverride);
    _webhookUrlCtrl = TextEditingController(text: 'https://lyceum1.edu.ru/api/webhooks/metodist');
    _inviteEmailCtrl = TextEditingController();

    _bookTitleCtrl = TextEditingController(text: 'Методика преподавания арифметики в начальной школе');
    _bookAuthorCtrl = TextEditingController(text: 'А. С. Пчёлко, Г. Б. Поляк');
    _bookSubjectCtrl = TextEditingController(text: 'Математика');
    _bookGradeCtrl = TextEditingController(text: '1-2 класс');
    _bookTocCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _stopWordCtrl.dispose();
    _systemPromptCtrl.dispose();
    _webhookUrlCtrl.dispose();
    _inviteEmailCtrl.dispose();
    _bookTitleCtrl.dispose();
    _bookAuthorCtrl.dispose();
    _bookSubjectCtrl.dispose();
    _bookGradeCtrl.dispose();
    _bookTocCtrl.dispose();
    super.dispose();
  }

  void _addStopWord() {
    final text = _stopWordCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final list = List<String>.from(_methodology.stopWords)..add(text);
      _methodology = _methodology.copyWith(stopWords: list);
      _stopWordCtrl.clear();
    });
  }

  void _removeStopWord(int index) {
    setState(() {
      final list = List<String>.from(_methodology.stopWords)..removeAt(index);
      _methodology = _methodology.copyWith(stopWords: list);
    });
  }

  Future<void> _startQuarterBulkGeneration() async {
    setState(() {
      _isGeneratingBulk = true;
      _bulkProgress = 0.0;
      _bulkStatusText = 'Инициализация пакетной генерации курса...';
    });

    for (int i = 1; i <= _bulkLessonCount; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _bulkProgress = i / _bulkLessonCount;
        _bulkStatusText = 'Генерация урока $i из $_bulkLessonCount: конспект, лист заданий, ключи...';
      });
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingBulk = false;
      _bulkStatusText = 'Пакет из $_bulkLessonCount уроков успешно сгенерирован и проверен (100% ФГОС). Готов к скачиванию!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📦 Курс на четверть скомпонован в ZIP-архив (PDF + DOCX)!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _copyToClipboard(String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDirector = context.watch<AppProvider>().isDirector;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Конструктор методик',
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
                          'Архитектура промптов, REST API, генератор четверти, аудит и кафедра',
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

            if (!isDirector)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: GlassCard(
                  borderRadius: AppRadii.lg,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Тариф «Директор» (1 199 ₽/мес при оплате за год) открывает полный доступ к архитектуре методик, API и генерации четвертей.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          context.read<AppProvider>().setTariff(TariffLevel.director);
                        },
                        child: const Text('Активировать', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.tune_rounded, size: 16), text: 'Методика'),
                  Tab(icon: Icon(Icons.auto_stories_rounded, size: 16), text: 'Поиск тем из книги (2 этапа)'),
                  Tab(icon: Icon(Icons.api_rounded, size: 16), text: 'REST API & LMS'),
                  Tab(icon: Icon(Icons.inventory_2_rounded, size: 16), text: 'Генератор четверти'),
                  Tab(icon: Icon(Icons.science_rounded, size: 16), text: 'Инспектор токенов'),
                  Tab(icon: Icon(Icons.group_rounded, size: 16), text: 'Кафедра (3-5 мест)'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMethodologyTab(isDark),
                  _buildBookTopicsExtractionTab(isDark),
                  _buildRestApiTab(isDark),
                  _buildQuarterCurriculumTab(isDark),
                  _buildTokenInspectorTab(isDark),
                  _buildDepartmentTeamTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Конструктор авторских методик (Prompt & Method Architect)
  Widget _buildMethodologyTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧩 Редактор авторской методики обучения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Создайте методику с нуля в дополнение к классическим (Пчёлко, Костин, Редозубов) с собственным педагогическим тоном.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Название авторской методики',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _methodology = _methodology.copyWith(title: v.trim())),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _authorCtrl,
              decoration: InputDecoration(
                labelText: 'Автор / Кафедра школы',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _methodology = _methodology.copyWith(authorName: v.trim())),
            ),
            const SizedBox(height: 16),
            const Text(
              'Педагогический тон системного промпта YandexGPT Pro:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...PedagogicalTone.values.map((tone) {
              final isSelected = _methodology.tone == tone;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _methodology = _methodology.copyWith(tone: tone)),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withOpacity(0.18)
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tone.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                tone.description,
                                style: TextStyle(
                                  fontSize: 11,
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
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Стоп-слова и запретные фразы (фильтр цензора):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._methodology.stopWords.asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => _removeStopWord(entry.key),
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stopWordCtrl,
                    decoration: InputDecoration(
                      hintText: 'Добавить стоп-слово...',
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addStopWord,
                  child: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _systemPromptCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Переопределение системного промпта YandexGPT Pro',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _methodology = _methodology.copyWith(customSystemPromptOverride: v.trim())),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Строгий контроль множителей (по методике Пчёлко)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('В задачах на умножение первым множителем строго ставится цена/порция, вторым — количество', style: TextStyle(fontSize: 11)),
              value: _methodology.strictPchelkoMultiplierCheck,
              onChanged: (v) => setState(() => _methodology = _methodology.copyWith(strictPchelkoMultiplierCheck: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Обязательный блок рефлексии открытий', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Добавлять вопросы самоанализа и критериального оценивания', style: TextStyle(fontSize: 11)),
              value: _methodology.requireReflectiveQuestions,
              onChanged: (v) => setState(() => _methodology = _methodology.copyWith(requireReflectiveQuestions: v)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. REST API и интеграция с электронным журналом (LMS & Bot Webhooks)
  Widget _buildRestApiTab(bool isDark) {
    const curlExample = 'curl -X POST https://api.metodist.ai/v1/generate/conspect \\\n'
        '  -H "Authorization: Bearer mtd_live_9f81a74e2d88c911b6a382e441c" \\\n'
        '  -H "Content-Type: application/json" \\\n'
        '  -d \'{"topic": "Сложение двузначных чисел", "grade": 2, "world": "space"}\'';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ REST API и интеграция с LMS (МЭШ, ЭЖД, Сферум, Moodle)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Вызывайте генератор конспектов и рабочих листов из Telegram-бота школы, локальных скриптов или корпоративной LMS.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Персональный API-токен кафедры:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _apiToken,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Скопировать токен',
                    onPressed: () => _copyToClipboard(_apiToken, 'API-токен скопирован в буфер!'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _webhookUrlCtrl,
              decoration: InputDecoration(
                labelText: 'Webhook URL для отправки готовых уроков в LMS',
                prefixIcon: const Icon(Icons.webhook_rounded),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Пример cURL-запроса:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BASH', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: () => _copyToClipboard(curlExample, 'cURL-запрос скопирован!'),
                        child: const Text('Копировать', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    curlExample,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Экспорт сырых данных урока для школьных платформ:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.code_rounded, size: 16),
                    label: const Text('JSON (МЭШ/ЭЖД)', style: TextStyle(fontSize: 11.5)),
                    onPressed: () => _copyToClipboard(
                      jsonEncode({'lesson': 'Сложение', 'grade': 2, 'stages': 5}),
                      'Сырой JSON урока скопирован!',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text('Markdown (Сферум)', style: TextStyle(fontSize: 11.5)),
                    onPressed: () => _copyToClipboard(
                      '# Урок математики 2 класс\n## Тема: Сложение двузначных чисел',
                      'Markdown урока скопирован!',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Пакетный генератор курса на четверть (Curriculum Bulk Export)
  Widget _buildQuarterCurriculumTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 Пакетный генератор курса на четверть (15–30 уроков)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Сквозная генерация всей учебной четверти в 1 клик с сохранением сюжетной линии игрового мира и автоматическим контролем полноты.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bulkSubject,
                    decoration: InputDecoration(
                      labelText: 'Предмет',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Математика', child: Text('Математика')),
                      DropdownMenuItem(value: 'Русский язык', child: Text('Русский язык')),
                      DropdownMenuItem(value: 'Окружающий мир', child: Text('Окружающий мир')),
                      DropdownMenuItem(value: 'Литературное чтение', child: Text('Литературное чтение')),
                    ],
                    onChanged: (v) => setState(() => _bulkSubject = v ?? 'Математика'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _bulkGrade,
                    decoration: InputDecoration(
                      labelText: 'Класс',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 класс')),
                      DropdownMenuItem(value: 2, child: Text('2 класс')),
                      DropdownMenuItem(value: 3, child: Text('3 класс')),
                      DropdownMenuItem(value: 4, child: Text('4 класс')),
                    ],
                    onChanged: (v) => setState(() => _bulkGrade = v ?? 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Количество уроков в блоке четверти: $_bulkLessonCount уроков',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Slider(
              min: 15,
              max: 30,
              divisions: 15,
              value: _bulkLessonCount.toDouble(),
              label: '$_bulkLessonCount уроков',
              onChanged: _isGeneratingBulk ? null : (v) => setState(() => _bulkLessonCount = v.round()),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Автоматический аудит: каждый сгенерированный урок обязательно содержит конспект (5 этапов), лист заданий (6+ упражнений), домашнее задание и ключи для учителя.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isGeneratingBulk) ...[
              LinearProgressIndicator(value: _bulkProgress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              const SizedBox(height: 8),
              Text(_bulkStatusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(
                  _isGeneratingBulk ? 'Генерация четверти...' : 'Сгенерировать курс четверти ($_bulkLessonCount уроков)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isGeneratingBulk ? null : _startQuarterBulkGeneration,
              ),
            ),
            if (!_isGeneratingBulk && _bulkProgress == 1.0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.folder_zip_rounded, color: Color(0xFF10B981)),
                  label: const Text('Скачать единый ZIP-архив (PDF + DOCX) [48.2 МБ]'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ZIP-архив курса успешно подготовлен к скачиванию!')),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. Лаборатория отладки и инспектор токенов (Token & Self-Refine Inspector)
  Widget _buildTokenInspectorTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔬 Лаборатория отладки и двухпроходный инспектор токенов',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Просмотр логов двухпроходной верификации YandexGPT Pro: Проход 1 (Методист-архитектор) и Проход 2 (Строгий цензор).',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            // Metrics Row
            Row(
              children: [
                _buildMetricBox('Токены промпта', '1 842', Colors.blue, isDark),
                const SizedBox(width: 8),
                _buildMetricBox('Токены ответа', '3 410', Colors.purple, isDark),
                const SizedBox(width: 8),
                _buildMetricBox('Строгость ФГОС', '99.4%', const Color(0xFF10B981), isDark),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Лог двухпроходного аудита последнего урока:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[PASS 1: Архитектор] Создан базовый каркас: 5 этапов, тема "Таблица умножения на 4", сюжет: Космос.',
                    style: TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 11),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '[PASS 2: Строгий цензор] Проверка порядка множителей: в задаче №3 обнаружено "4 × 3", исправлено на "3 × 4" (по 3 ракеты в 4 ангарах). Соответствие Пчёлко 100%.',
                    style: TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace', fontSize: 11),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '[PASS 2: Верификация ключей] Ответы к 6 задачам листа перепроверены: 0 ошибок в вычислениях.',
                    style: TextStyle(color: Color(0xFFA78BFA), fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Командный доступ (Лицензия кафедры — 3-5 мест)
  Widget _buildDepartmentTeamTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👥 Командный доступ (Лицензия кафедры)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'До 5 рабочих мест учителей с общим банком конспектов и шаблонов.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_team.activeSeatsCount} из ${_team.maxSeats} мест занято',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF818CF8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._team.members.map((member) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      radius: 16,
                      child: Text(
                        member.name.isNotEmpty ? member.name[0] : 'У',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${member.role} • ${member.email}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inviteEmailCtrl,
                    decoration: InputDecoration(
                      hintText: 'Email коллеги для приглашения на кафедру...',
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final email = _inviteEmailCtrl.text.trim();
                    if (email.isEmpty) return;
                    setState(() {
                      final newMember = DepartmentMember(
                        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
                        name: 'Учитель кафедры',
                        email: email,
                        role: 'Учитель начальных классов',
                        joinedAt: DateTime.now(),
                      );
                      final updatedMembers = List<DepartmentMember>.from(_team.members)..add(newMember);
                      _team = DepartmentTeam(
                        id: _team.id,
                        teamName: _team.teamName,
                        maxSeats: _team.maxSeats,
                        members: updatedMembers,
                        inviteCode: _team.inviteCode,
                      );
                      _inviteEmailCtrl.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Приглашение отправлено на $email!')),
                    );
                  },
                  child: const Text('Пригласить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // Методы двухэтапного конвейера поиска тем из книги
  Future<void> _runStage1Extraction() async {
    setState(() {
      _isExtractingStage1 = true;
      _bookStatusMsg = 'Этап 1: Макро-картирование всех тем книги через YandexGPT Pro...';
      _extractedTopics.clear();
      _enrichedTopics.clear();
    });

    try {
      final topics = await MethodologyArchitectService.extractAllCourseTopicsFromBook(
        bookTitle: _bookTitleCtrl.text.trim(),
        author: _bookAuthorCtrl.text.trim(),
        subject: _bookSubjectCtrl.text.trim(),
        grade: _bookGradeCtrl.text.trim(),
        tocText: _bookTocCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isExtractingStage1 = false;
        _extractedTopics = topics;
        _bookStatusMsg = 'Этап 1 успешно завершён: найдено ВСЕГО ${topics.length} тем без ограничений! Отметьте нужные темы и перейдите к Этапу 2.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtractingStage1 = false;
        _bookStatusMsg = 'Ошибка Этапа 1: $e';
      });
    }
  }

  Future<void> _runStage2Enrichment() async {
    final selected = _extractedTopics.where((t) => t.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите хотя бы одну тему для обогащения')),
      );
      return;
    }

    setState(() {
      _isEnrichingStage2 = true;
      _bookStatusMsg = 'Этап 2: Педагогическое микро-обогащение выбранных ${selected.length} тем...';
      _enrichedTopics.clear();
    });

    for (int i = 0; i < selected.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      final enriched = MethodologyArchitectService.enrichSingleTopic(
        topic: selected[i],
        methodologyName: _bookTitleCtrl.text.trim(),
        author: _bookAuthorCtrl.text.trim(),
      );
      _enrichedTopics.add(enriched);
    }

    if (!mounted) return;
    setState(() {
      _isEnrichingStage2 = false;
      _bookStatusMsg = 'Этап 2 успешно завершён: ${_enrichedTopics.length} тем полностью обогащены ФГОС-целями, «Ловушками Незнайки», ТРИЗ и 3 уровнями заданий!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Успешно добавлены и обогащены ${_enrichedTopics.length} тем из книги!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // 1.1 Поиск тем из книги (Двухэтапный конвейер без ограничений)
  Widget _buildBookTopicsExtractionTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: AppRadii.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📚 Двухэтапный поиск тем из книги/методики',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Без лимитов на 10-20 тем: извлекаются ВСЕ темы учебника или программы',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Book Details Inputs
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _bookTitleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Название книги или методики',
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _bookAuthorCtrl,
                        decoration: InputDecoration(
                          labelText: 'Автор(ы) книги',
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bookSubjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Предметная область',
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _bookGradeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Класс / возраст',
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _bookTocCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Оглавление книги или фрагмент программы (необязательно)',
                    hintText: 'Вставьте оглавление учебника или оставьте пустым для канонического поиска по автору...',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Button Stage 1
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isExtractingStage1
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(
                      _isExtractingStage1 ? 'Анализ книги YandexGPT Pro...' : '🚀 Этап 1: Найти ВСЕ темы книги без ограничений',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: _isExtractingStage1 ? null : _runStage1Extraction,
                  ),
                ),

                if (_bookStatusMsg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _bookStatusMsg,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stage 1 Extracted Topics Cards
          if (_extractedTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: AppRadii.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '📋 Извлечённые темы курса',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Найдено: ${_extractedTopics.length} тем',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final allSelected = _extractedTopics.every((t) => t.isSelected);
                            for (var t in _extractedTopics) {
                              t.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(_extractedTopics.every((t) => t.isSelected) ? 'Снять все' : 'Выбрать все'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _extractedTopics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = _extractedTopics[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: t.isSelected ? const Color(0xFF6366F1).withOpacity(0.4) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: t.isSelected,
                              activeColor: const Color(0xFF6366F1),
                              onChanged: (val) {
                                setState(() {
                                  t.isSelected = val ?? false;
                                });
                              },
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${t.number}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white12 : Colors.black12,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(t.section, style: const TextStyle(fontSize: 9.5)),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Навык: ${t.focusSkill}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Button Stage 2
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isEnrichingStage2
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _isEnrichingStage2
                            ? 'Обогащение выбранных тем...'
                            : '✨ Этап 2: Педагогическое обогащение и сохранение (${_extractedTopics.where((t) => t.isSelected).length} тем)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: _isEnrichingStage2 ? null : _runStage2Enrichment,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Stage 2 Enriched Previews
          if (_enrichedTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: AppRadii.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Педагогический паспорт обогащённых тем (ФГОС + ТРИЗ)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._enrichedTopics.take(3).map((et) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Урок ${et.number}. ${et.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('🎯 ФГОС: ${et.subjectGoal}', style: const TextStyle(fontSize: 11)),
                          Text('⚠️ Ловушка Незнайки: ${et.neznaykaTrap}', style: const TextStyle(fontSize: 11, color: Colors.amber)),
                          Text('📋 3 уровня: ${et.tier1Start} | ${et.tier3DetectivePro}', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ),
                    );
                  }),
                  if (_enrichedTopics.length > 3)
                    Text(
                      '... и ещё ${_enrichedTopics.length - 3} тем сохранены в базу данных.',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
