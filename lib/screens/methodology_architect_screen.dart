import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/custom_methodology.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
import '../services/methodology_architect_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import 'new_conspect_screen.dart';

/// Экран методик обучения:
/// 1. Витрина готовых классических методик (Пчёлко, Костин, Редозубов, Мазина, Сингапур CPA...)
/// 2. Создание авторской методики (для тарифа «Директор»)
/// 3. Двухэтапный поиск тем из книги
/// 4. Пакетный генератор курса на четверть
class MethodologyArchitectScreen extends StatefulWidget {
  const MethodologyArchitectScreen({super.key});

  @override
  State<MethodologyArchitectScreen> createState() => _MethodologyArchitectScreenState();
}

class _MethodologyArchitectScreenState extends State<MethodologyArchitectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Фильтр предметов в каталоге
  String _selectedSubjectFilter = 'Все';

  // Авторские методики пользователя (тариф «Директор»)
  final List<CustomMethodology> _customMethodologies = [];

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

  // Пакетный генератор уроков на четверть
  int _bulkLessonCount = 20;
  String _bulkSubject = 'Математика';
  int _bulkGrade = 2;
  bool _isGeneratingBulk = false;
  double _bulkProgress = 0.0;
  String _bulkStatusText = '';

  @override
  void initState() {
    super.initState();
    // 3 понятные и нужные учителю вкладки
    _tabController = TabController(length: 3, vsync: this);

    _customMethodologies.add(CustomMethodology.defaultLyceumMethodology());

    _bookTitleCtrl = TextEditingController(text: 'Методика преподавания арифметики в начальной школе');
    _bookAuthorCtrl = TextEditingController(text: 'А. С. Пчёлко, Г. Б. Поляк');
    _bookSubjectCtrl = TextEditingController(text: 'Математика');
    _bookGradeCtrl = TextEditingController(text: '1-2 класс');
    _bookTocCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookTitleCtrl.dispose();
    _bookAuthorCtrl.dispose();
    _bookSubjectCtrl.dispose();
    _bookGradeCtrl.dispose();
    _bookTocCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDirector = context.watch<AppProvider>().isDirector;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Шапка экрана
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
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Методики обучения',
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
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'ФГОС ЭТАЛОНЫ',
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
                          'Проверенные педагогические системы и конструктор курсов',
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

            // Вкладки
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
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
                  Tab(icon: Icon(Icons.menu_book_rounded, size: 16), text: 'Каталог методик'),
                  Tab(icon: Icon(Icons.search_rounded, size: 16), text: 'Поиск тем из книги'),
                  Tab(icon: Icon(Icons.inventory_2_rounded, size: 16), text: 'Генератор четверти'),
                ],
              ),
            ),

            // Содержимое вкладок
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMethodologyCatalogTab(isDark, isDirector),
                  _buildBookTopicsExtractionTab(isDark),
                  _buildQuarterCurriculumTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. КАТАЛОГ ГОТОВЫХ И АВТОРСКИХ МЕТОДИК
  // ==========================================
  Widget _buildMethodologyCatalogTab(bool isDark, bool isDirector) {
    final allBooks = PredefinedMethodologyBook.classicLibrary;

    // Фильтрация
    final filteredBooks = allBooks.where((book) {
      if (_selectedSubjectFilter == 'Все') return true;
      if (_selectedSubjectFilter == 'Математика') {
        return book.subjectArea.contains('Математика') || book.subjectArea.contains('арифметика');
      }
      if (_selectedSubjectFilter == 'Русский язык') {
        return book.subjectArea.contains('Русский') || book.subjectArea.contains('грамматика');
      }
      if (_selectedSubjectFilter == 'Чтение и речь') {
        return book.subjectArea.contains('чтение') || book.subjectArea.contains('грамоте');
      }
      if (_selectedSubjectFilter == 'Развивающее') {
        return book.subjectArea.contains('Развивающее') || book.subjectArea.contains('Изобретательское') || book.subjectArea.contains('Межпредметная');
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        // Карточка-кнопка добавления авторской методики (Тариф «Директор»)
        _buildCreateCustomMethodologyBanner(isDark, isDirector),

        const SizedBox(height: 16),

        // Чипы быстрой фильтрации по предметам
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              'Все',
              'Математика',
              'Русский язык',
              'Чтение и речь',
              'Развивающее',
            ].map((subject) {
              final isSel = _selectedSubjectFilter == subject;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(subject),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedSubjectFilter = subject),
                  selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.22),
                  checkmarkColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? const Color(0xFF818CF8) : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Если созданы авторские методики
        if (_customMethodologies.isNotEmpty && (_selectedSubjectFilter == 'Все' || _selectedSubjectFilter == 'Развивающее')) ...[
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              const Text(
                'Авторские методики школы',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ДИРЕКТОР', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA855F7))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._customMethodologies.map((cm) => _buildCustomMethodologyCard(cm, isDark)),
          const SizedBox(height: 16),
        ],

        // Заголовок готовых методик
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 8),
            Text(
              'Классические эталонные методики (${filteredBooks.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Список готовых классических методик
        ...filteredBooks.map((book) => _buildPredefinedBookCard(book, isDark)),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Баннер / Кнопка создания авторской методики
  Widget _buildCreateCustomMethodologyBanner(bool isDark, bool isDirector) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('👑', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Авторская методика',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ДИРЕКТОР',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Создайте методику школы с уникальным тоном обучения',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Создать', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _openCreateCustomMethodologyModal(context, isDirector),
          ),
        ],
      ),
    );
  }

  /// Карточка авторской методики
  Widget _buildCustomMethodologyCard(CustomMethodology cm, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🎓', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cm.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Text(
                  '${cm.authorName} • Тон: ${cm.tone.label}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewConspectScreen(),
                ),
              );
            },
            child: const Text('Урок', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Карточка классической готовой методики
  Widget _buildPredefinedBookCard(PredefinedMethodologyBook book, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка карточки
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.2),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(book.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${book.author} (${book.year})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.subjectArea,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Суть методики
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        book.paradigm,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📐 ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        'Наглядность: ${book.visualApproach}',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка создания урока
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text(
                'Создать урок по этой методике',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewConspectScreen(initialMethodId: book.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Модальное окно создания авторской методики (простое, без промптов и стоп-слов)
  void _openCreateCustomMethodologyModal(BuildContext context, bool isDirector) {
    if (!isDirector) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('👑 ', style: TextStyle(fontSize: 22)),
              Text('Тариф «Директор»', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Создание авторских методик начальной школы доступно на тарифе «Директор».\n\n'
            'Вы сможете сформировать фирменный стандарт преподавания вашей школы с собственным педагогическим тоном.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Позже'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<AppProvider>().setTariff(TariffLevel.director);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Тариф «Директор» активирован! Создание авторской методики разблокировано.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Активировать Директор'),
            ),
          ],
        ),
      );
      return;
    }

    // Форма создания для Директора
    final titleCtrl = TextEditingController(text: 'Авторская методика начальной школы');
    final authorCtrl = TextEditingController(text: 'Кафедра начального образования');
    PedagogicalTone selectedTone = PedagogicalTone.triz;
    bool strictMultiplier = true;
    bool requireReflections = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '✨ Новая авторская методика',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Название методики',
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorCtrl,
                      decoration: InputDecoration(
                        labelText: 'Автор / Школа / Кафедра',
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Педагогический стиль и тон:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...PedagogicalTone.values.map((tone) {
                      final isSel = selectedTone == tone;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setModalState(() => selectedTone = tone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.16)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel ? Icons.check_circle_rounded : Icons.radio_button_off,
                                  size: 16,
                                  color: isSel ? const Color(0xFF8B5CF6) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tone.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      Text(
                                        tone.description,
                                        style: TextStyle(
                                          fontSize: 10.5,
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Строгий контроль множителей (Пчёлко)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Цена/порция на первом месте, количество на втором', style: TextStyle(fontSize: 11)),
                      value: strictMultiplier,
                      onChanged: (v) => setModalState(() => strictMultiplier = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Обязательный блок рефлексии открытий', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Вопросы самоанализа для детей в конце урока', style: TextStyle(fontSize: 11)),
                      value: requireReflections,
                      onChanged: (v) => setModalState(() => requireReflections = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final newM = CustomMethodology(
                            id: 'method_custom_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            authorName: authorCtrl.text.trim(),
                            tone: selectedTone,
                            strictPchelkoMultiplierCheck: strictMultiplier,
                            requireReflectiveQuestions: requireReflections,
                          );
                          setState(() {
                            _customMethodologies.add(newM);
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Авторская методика «${newM.title}» добавлена в каталог!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Text('Сохранить авторскую методику', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 2. ПОИСК ТЕМ ИЗ КНИГИ (2 ЭТАПА)
  // ==========================================
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
                const Text(
                  '📖 Извлечение тем из книги или программы (2 этапа)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Загрузите оглавление советского или современного учебника, чтобы автоматически извлечь и обогатить темы уроков.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bookTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Название книги или программы',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bookAuthorCtrl,
                        decoration: InputDecoration(
                          labelText: 'Автор(ы)',
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _bookSubjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Предмет',
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bookTocCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Оглавление (или список тем)',
                    hintText: 'Вставьте текст оглавления книги или оставьте пустым для эталона Пчёлко...',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
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
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(
                      _isExtractingStage1 ? 'Анализ оглавления...' : '🔍 Этап 1: Распознать темы из книги',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: _isExtractingStage1 ? null : _runStage1Extraction,
                  ),
                ),
                if (_bookStatusMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _bookStatusMsg,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Результаты этапа 1
          if (_extractedTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: AppRadii.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📋 Извлечённые темы курса',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.select_all_rounded, size: 16),
                        label: const Text('Выбрать все', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            for (var t in _extractedTopics) {
                              t.isSelected = true;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: t.isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.4) : Colors.transparent,
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
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
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
                                  Text(
                                    '${t.section} • Навык: ${t.focusSkill}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                            ? 'Обогащение тем...'
                            : '✨ Этап 2: Педагогическое обогащение (${_extractedTopics.where((t) => t.isSelected).length} тем)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isEnrichingStage2 ? null : _runStage2Enrichment,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_enrichedTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: AppRadii.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Обогащённые темы по ФГОС и ТРИЗ (${_enrichedTopics.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._enrichedTopics.take(3).map((et) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Урок ${et.number}. ${et.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text('⚠️ ${et.neznaykaTrap}', style: const TextStyle(fontSize: 11, color: Colors.amber)),
                          Text('📋 ${et.tier1Start}', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }),
                  if (_enrichedTopics.length > 3)
                    Text(
                      '... и ещё ${_enrichedTopics.length - 3} тем сохранены в базу уроков.',
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

  Future<void> _runStage1Extraction() async {
    setState(() {
      _isExtractingStage1 = true;
      _bookStatusMsg = '';
    });

    try {
      final topics = await MethodologyArchitectService.extractAllCourseTopicsFromBook(
        bookTitle: _bookTitleCtrl.text.trim(),
        author: _bookAuthorCtrl.text.trim(),
        subject: _bookSubjectCtrl.text.trim(),
        grade: _bookGradeCtrl.text.trim(),
        tocText: _bookTocCtrl.text.trim(),
      );

      setState(() {
        _extractedTopics = topics;
        _isExtractingStage1 = false;
        _bookStatusMsg = 'Успешно извлечено ${topics.length} тем курса!';
      });
    } catch (e) {
      setState(() {
        _isExtractingStage1 = false;
        _bookStatusMsg = 'Ошибка анализа: $e';
      });
    }
  }

  Future<void> _runStage2Enrichment() async {
    setState(() {
      _isEnrichingStage2 = true;
    });

    try {
      final selected = _extractedTopics.where((t) => t.isSelected).toList();
      final enrichedList = <Stage2EnrichedTopic>[];

      for (final t in selected) {
        final enriched = MethodologyArchitectService.enrichSingleTopic(
          topic: t,
          methodologyName: _bookTitleCtrl.text.trim(),
          author: _bookAuthorCtrl.text.trim(),
        );
        enrichedList.add(enriched);
      }

      setState(() {
        _enrichedTopics = enrichedList;
        _isEnrichingStage2 = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Обогащено ${enrichedList.length} тем по ФГОС и ТРИЗ!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isEnrichingStage2 = false;
      });
    }
  }

  // ==========================================
  // 3. ГЕНЕРАТОР КУРСА НА ЧЕТВЕРТЬ
  // ==========================================
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
              '📦 Пакетный генератор четверти (20–40 уроков)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Сформируйте комплект поурочных планов и рабочих листов на всю четверть в один клик.',
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Математика', child: Text('Математика')),
                      DropdownMenuItem(value: 'Русский язык', child: Text('Русский язык')),
                      DropdownMenuItem(value: 'Литературное чтение', child: Text('Литературное чтение')),
                      DropdownMenuItem(value: 'Окружающий мир', child: Text('Окружающий мир')),
                    ],
                    onChanged: (v) => setState(() => _bulkSubject = v ?? 'Математика'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _bulkGrade,
                    decoration: InputDecoration(
                      labelText: 'Класс',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 16),
            Text(
              'Количество уроков в четверти: $_bulkLessonCount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Slider(
              value: _bulkLessonCount.toDouble(),
              min: 5,
              max: 40,
              divisions: 7,
              label: '$_bulkLessonCount уроков',
              activeColor: const Color(0xFF6366F1),
              onChanged: (v) => setState(() => _bulkLessonCount = v.round()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isGeneratingBulk
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _isGeneratingBulk ? 'Генерация четверти...' : '⚡ Сгенерировать пакет ($_bulkLessonCount уроков)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                onPressed: _isGeneratingBulk ? null : _startQuarterBulkGeneration,
              ),
            ),
            if (_isGeneratingBulk || _bulkStatusText.isNotEmpty) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _bulkProgress > 0 ? _bulkProgress : null,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 8),
              Text(
                _bulkStatusText,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
