import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/scheduled_lesson.dart';
import '../models/conspect.dart';
import '../providers/app_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import 'conspect_view_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateFull(DateTime date) {
    const weekdays = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
    ];
    const monthsGenitive = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${monthsGenitive[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final lessonsForSelectedDate = provider.getLessonsForDate(_selectedDate);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Календарь занятий',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_rounded, size: 18, color: AppColors.accentCyan),
            label: const Text(
              'Сегодня',
              style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Calendar Grid
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _buildCalendarCard(provider, isDark),
                      ),
                    ),
                    // Right: Lessons for selected day
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _buildDayDetailsCard(lessonsForSelectedDate, provider, isDark),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _buildCalendarCard(provider, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildDayDetailsCard(lessonsForSelectedDate, provider, isDark),
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Запланировать'),
        onPressed: () => _showAddLessonDialog(context, provider),
      ),
    );
  }

  Widget _buildCalendarCard(AppProvider provider, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Month header & arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousMonth,
              ),
              Text(
                _formatMonthYear(_focusedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Days of week row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel('Пн'),
              _WeekdayLabel('Вт'),
              _WeekdayLabel('Ср'),
              _WeekdayLabel('Чт'),
              _WeekdayLabel('Пт'),
              _WeekdayLabel('Сб', isWeekend: true),
              _WeekdayLabel('Вс', isWeekend: true),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildMonthGrid(provider, isDark),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(AppProvider provider, bool isDark) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    
    // In DateTime: Monday is 1, Sunday is 7
    final firstWeekday = firstDayOfMonth.weekday; // 1 to 7
    final prevMonthDays = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    final List<Widget> dayCells = [];

    // Preceding days from previous month
    for (int i = firstWeekday - 1; i > 0; i--) {
      final dayNumber = prevMonthDays - i + 1;
      final date = DateTime(_focusedMonth.year, _focusedMonth.month - 1, dayNumber);
      dayCells.add(_buildDayCell(date, isCurrentMonth: false, provider: provider, isDark: isDark));
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      dayCells.add(_buildDayCell(date, isCurrentMonth: true, provider: provider, isDark: isDark));
    }

    // Trailing days to fill the grid (multiples of 7)
    final totalCells = dayCells.length;
    final remaining = (7 - (totalCells % 7)) % 7;
    for (int day = 1; day <= remaining; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month + 1, day);
      dayCells.add(_buildDayCell(date, isCurrentMonth: false, provider: provider, isDark: isDark));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.05,
      children: dayCells,
    );
  }

  Widget _buildDayCell(
    DateTime date, {
    required bool isCurrentMonth,
    required AppProvider provider,
    required bool isDark,
  }) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    final now = DateTime.now();
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;

    final lessonsOnDay = provider.getLessonsForDate(date);
    final hasLessons = lessonsOnDay.isNotEmpty;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day);
          if (!isCurrentMonth) {
            _focusedMonth = DateTime(date.year, date.month, 1);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryIndigo
              : (isToday
                  ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.accentCyan, width: 1.5)
              : (isToday
                  ? Border.all(color: AppColors.primaryIndigo.withOpacity(0.6), width: 1)
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isCurrentMonth
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white24 : Colors.black26)),
              ),
            ),
            if (hasLessons) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  lessonsOnDay.length > 3 ? 3 : lessonsOnDay.length,
                  (index) => Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.accentCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailsCard(
    List<ScheduledLesson> lessons,
    AppProvider provider,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateFull(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lessons.isEmpty
                          ? 'Нет запланированных занятий'
                          : 'Занятий на день: ${lessons.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Добавить занятие',
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryIndigo),
                onPressed: () => _showAddLessonDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          if (lessons.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 44,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'На эту дату уроки не запланированы',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _showAddLessonDialog(context, provider),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Запланировать занятие'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final lesson = lessons[index];
                return _buildLessonItem(lesson, provider, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(
    ScheduledLesson lesson,
    AppProvider provider,
    bool isDark,
  ) {
    Conspect? linkedConspect;
    if (lesson.conspectId != null) {
      try {
        linkedConspect = provider.conspects.firstWhere((c) => c.id == lesson.conspectId);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Time & Student
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⏰ ${lesson.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentCyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '👤 ${lesson.studentOrClass}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Удалить из расписания',
                onPressed: () => _confirmDeleteLesson(lesson, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Topic
          Text(
            '📚 Тема: ${lesson.topic}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (lesson.notes != null && lesson.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📝 Заметка: ${lesson.notes}',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Generated Materials Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildMaterialChip(
                label: 'Конспект',
                icon: Icons.menu_book_rounded,
                isAvailable: lesson.hasConspect,
                color: AppColors.primaryIndigo,
              ),
              _buildMaterialChip(
                label: 'Лист заданий',
                icon: Icons.assignment_outlined,
                isAvailable: lesson.hasWorksheet,
                color: const Color(0xFF2563EB),
              ),
              _buildMaterialChip(
                label: 'Домашка',
                icon: Icons.home_work_outlined,
                isAvailable: lesson.hasHomework,
                color: const Color(0xFF059669),
              ),
            ],
          ),

          if (linkedConspect != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      side: BorderSide(color: AppColors.primaryIndigo.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('Открыть конспект', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConspectViewScreen(existingConspect: linkedConspect),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Печать материалов PDF',
                  icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.accentCyan),
                  onPressed: () => _showExportMaterialOptions(linkedConspect!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialChip({
    required String label,
    required IconData icon,
    required bool isAvailable,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? color.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isAvailable ? color : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
              color: isAvailable ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportMaterialOptions(Conspect conspect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Печать / Экспорт материалов занятия',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: AppColors.primaryIndigo),
              title: const Text('PDF Конспект занятия'),
              subtitle: const Text('Пошаговый сценарий и методика'),
              onTap: () {
                Navigator.pop(ctx);
                PdfExportService.exportMaterialPdf(conspect, PdfMaterialType.conspect);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: Color(0xFF2563EB)),
              title: const Text('PDF Лист заданий для печати'),
              subtitle: const Text('Рабочий лист с правилом и упражнениями'),
              onTap: () {
                Navigator.pop(ctx);
                PdfExportService.exportMaterialPdf(conspect, PdfMaterialType.worksheet);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work_rounded, color: Color(0xFF059669)),
              title: const Text('PDF Домашняя работа'),
              subtitle: const Text('Задания на закрепление и памятка родителям'),
              onTap: () {
                Navigator.pop(ctx);
                PdfExportService.exportMaterialPdf(conspect, PdfMaterialType.homework);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLesson(ScheduledLesson lesson, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить занятие?'),
        content: Text('Удалить занятие с ${lesson.studentOrClass} по теме "${lesson.topic}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.removeScheduledLesson(lesson.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context, AppProvider provider) {
    final studentController = TextEditingController();
    final topicController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    DateTime lessonDate = _selectedDate;
    Conspect? selectedConspect;
    bool hasConspect = true;
    bool hasWorksheet = true;
    bool hasHomework = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final width = MediaQuery.of(context).size.width;
          final dialogWidth = width > 520 ? 480.0 : (width - 32);

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : AppColors.primaryIndigo.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.indigoViolet,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Запланировать занятие',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Добавьте урок в календарь и свяжите с материалами',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & Time pickers
                          const Text(
                            'Дата и время проведения',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: lessonDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => lessonDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primaryIndigo),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd.MM.yyyy').format(lessonDate),
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (picked != null) {
                                      setDialogState(() => selectedTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primaryIndigo),
                                        const SizedBox(width: 8),
                                        Text(
                                          selectedTime.format(context),
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Student or Class
                          TextField(
                            controller: studentController,
                            decoration: InputDecoration(
                              labelText: 'Ученик или класс *',
                              hintText: 'Миша (1 класс) или 3-Б',
                              prefixIcon: const Icon(Icons.person_rounded, size: 20),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Topic
                          TextField(
                            controller: topicController,
                            decoration: InputDecoration(
                              labelText: 'Тема занятия *',
                              hintText: 'Сложение в пределах 20',
                              prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Link existing conspect (optional)
                          if (provider.conspects.isNotEmpty) ...[
                            DropdownButtonFormField<Conspect?>(
                              value: selectedConspect,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Привязать материал из базы',
                                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                                filled: true,
                                fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<Conspect?>(
                                  value: null,
                                  child: Text('— Без привязки к конспекту —', style: TextStyle(fontSize: 13)),
                                ),
                                ...provider.conspects.map((c) => DropdownMenuItem<Conspect?>(
                                      value: c,
                                      child: Text(
                                        c.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    )),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedConspect = val;
                                  if (val != null) {
                                    topicController.text = val.topic.isNotEmpty ? val.topic : val.title;
                                    hasConspect = val.generatedMaterials.contains('conspect');
                                    hasWorksheet = val.generatedMaterials.contains('worksheet');
                                    hasHomework = val.generatedMaterials.contains('homework');
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Material Selector Chips
                          const Text(
                            'Материалы к уроку:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Конспект'),
                                avatar: Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: hasConspect ? AppColors.primaryIndigo : Colors.grey,
                                ),
                                selected: hasConspect,
                                onSelected: (val) => setDialogState(() => hasConspect = val),
                                selectedColor: AppColors.primaryIndigo.withOpacity(0.15),
                                checkmarkColor: AppColors.primaryIndigo,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              FilterChip(
                                label: const Text('Лист заданий'),
                                avatar: Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                  color: hasWorksheet ? const Color(0xFF2563EB) : Colors.grey,
                                ),
                                selected: hasWorksheet,
                                onSelected: (val) => setDialogState(() => hasWorksheet = val),
                                selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
                                checkmarkColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              FilterChip(
                                label: const Text('Домашка'),
                                avatar: Icon(
                                  Icons.home_work_outlined,
                                  size: 16,
                                  color: hasHomework ? const Color(0xFF059669) : Colors.grey,
                                ),
                                selected: hasHomework,
                                onSelected: (val) => setDialogState(() => hasHomework = val),
                                selectedColor: const Color(0xFF059669).withOpacity(0.15),
                                checkmarkColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Notes
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Заметки учителя (необязательно)',
                              hintText: 'Повторить счет, взять счетные палочки',
                              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dialog Footer Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.04),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Отмена', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Сохранить',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          onPressed: () async {
                            final student = studentController.text.trim();
                            final topic = topicController.text.trim();
                            if (student.isEmpty || topic.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Укажите ученика/класс и тему занятия')),
                              );
                              return;
                            }

                            final lesson = ScheduledLesson(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              date: lessonDate,
                              time: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              studentOrClass: student,
                              topic: topic,
                              conspectId: selectedConspect?.id,
                              hasConspect: hasConspect,
                              hasWorksheet: hasWorksheet,
                              hasHomework: hasHomework,
                              notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                            );

                            await provider.addScheduledLesson(lesson);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  final bool isWeekend;
  const _WeekdayLabel(this.text, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isWeekend ? AppColors.accentCyan : Colors.grey,
          ),
        ),
      ),
    );
  }
}
