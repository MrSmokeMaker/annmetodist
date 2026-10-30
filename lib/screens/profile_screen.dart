import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pricing_plan.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isAnnualBilling = true;
  double _weeklyLessons = 16.0;

  @override
  Widget build(BuildContext context) {
    final user = _supabaseService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final currentTier = provider.userTier;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.violetMagenta,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                  boxShadow: AppShadows.glowAccent,
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Профиль и тарифы',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Управление аккаунтом и возможностями методиста',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // User Info Card
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    borderRadius: AppRadii.lg,
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppGradients.violetMagenta,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryViolet.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user?.email?.isNotEmpty == true
                                  ? user!.email!.substring(0, 1).toUpperCase()
                                  : '👤',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email ?? 'Гостевой доступ',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getTierColor(currentTier).withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(AppRadii.full),
                                      border: Border.all(
                                        color: _getTierColor(currentTier).withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getTierLabel(currentTier),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _getTierColor(currentTier),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    user != null ? 'Облако активно' : 'Только локально',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (user != null)
                          IconButton(
                            tooltip: 'Выйти',
                            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                            onPressed: () async {
                              await _supabaseService.signOut();
                              if (mounted) setState(() {});
                            },
                          )
                        else
                          ElevatedButton(
                            onPressed: () {
                              AuthDialog.show(context, onAuthSuccess: () {
                                if (mounted) setState(() {});
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryIndigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            child: const Text('Войти', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title for Pricing & Billing Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.accentAmber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Тарифные планы',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Billing Period Switcher (Month / School Year)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isAnnualBilling = false),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isAnnualBilling
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                boxShadow: !_isAnnualBilling
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Помесячно',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: !_isAnnualBilling ? FontWeight.bold : FontWeight.w500,
                                  color: !_isAnnualBilling
                                      ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isAnnualBilling = true),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _isAnnualBilling ? AppGradients.indigoViolet : null,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                boxShadow: _isAnnualBilling ? AppShadows.glowPrimary : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Учебный год',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: _isAnnualBilling ? FontWeight.bold : FontWeight.w500,
                                      color: _isAnnualBilling
                                          ? Colors.white
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _isAnnualBilling ? Colors.white : AppColors.success,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '-35%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: _isAnnualBilling ? AppColors.primaryIndigo : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Pricing Cards Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      final plans = PricingPlan.defaultPlans;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plans
                              .map((plan) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: _buildPricingCard(plan, currentTier),
                                    ),
                                  ))
                              .toList(),
                        );
                      }

                      return Column(
                        children: plans
                            .map((plan) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildPricingCard(plan, currentTier),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ROI / Time Savings Calculator for Teachers
                  _buildTimeSavingsCalculator(isDark),

                  const SizedBox(height: 20),

                  // Trust & Security Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '7 дней бесплатного пробного периода',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Оплата через СБП, Mir Pay или карты банков РФ. Без скрытых списаний, отмена в 1 клик в любое время.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comparison Table
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: AppRadii.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Подробное сравнение тарифов',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 22,
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                            columns: const [
                              DataColumn(label: Text('Возможность')),
                              DataColumn(label: Text('Старт (0 ₽)')),
                              DataColumn(label: Text('Практик (Хит)')),
                              DataColumn(label: Text('Pro (Максимум)')),
                            ],
                            rows: const [
                              DataRow(cells: [
                                DataCell(Text('Генераций конспектов')),
                                DataCell(Text('5 / мес')),
                                DataCell(Text('60 / мес (все уроки)')),
                                DataCell(Text('Безлимитно ✨')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Рабочие листы (6 механик)')),
                                DataCell(Text('—')),
                                DataCell(Text('Включено 📝')),
                                DataCell(Text('Включено 📝')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Домашние задания + памятки')),
                                DataCell(Text('—')),
                                DataCell(Text('Включено 👨‍👩‍👧')),
                                DataCell(Text('Включено 👨‍👩‍👧')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Режим Eco-Print (экономия тонера)')),
                                DataCell(Text('—')),
                                DataCell(Text('Включено 🌿')),
                                DataCell(Text('Включено 🌿')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Адаптация ОВЗ / ЗПР')),
                                DataCell(Text('—')),
                                DataCell(Text('—')),
                                DataCell(Text('Включено 💡')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Экспорт документов')),
                                DataCell(Text('Текст')),
                                DataCell(Text('Премиум PDF')),
                                DataCell(Text('PDF + Word (DOCX)')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Аудио-скрипт для родителей')),
                                DataCell(Text('—')),
                                DataCell(Text('—')),
                                DataCell(Text('Включено 🎙️')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Совместный доступ')),
                                DataCell(Text('1 педагог')),
                                DataCell(Text('1 педагог')),
                                DataCell(Text('До 3 педагогов 👥')),
                              ]),
                              DataRow(cells: [
                                DataCell(Text('Облачное хранилище')),
                                DataCell(Text('10 уроков')),
                                DataCell(Text('200 уроков')),
                                DataCell(Text('Безлимитно')),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Карточка одного тарифа
  Widget _buildPricingCard(PricingPlan plan, String currentTier) {
    final isCurrent = currentTier == plan.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: plan.isPopular
              ? AppColors.primaryViolet
              : (isCurrent
                  ? AppColors.accentCyan
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: plan.isPopular || isCurrent ? 2 : 1,
        ),
        boxShadow: plan.isPopular ? AppShadows.glowAccent : null,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge (e.g., ХИТ ВЫГОДЫ)
            if (plan.badge != null)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: plan.isPopular ? AppGradients.violetMagenta : AppGradients.amberOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Text(
              plan.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              plan.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.getPriceLabel(_isAnnualBilling),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              plan.getBillingPeriodNote(_isAnnualBilling),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: plan.id != 'free' && _isAnnualBilling
                    ? AppColors.success
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 8),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (plan.id == currentTier) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Тариф «${plan.name}» уже активен')),
                    );
                    return;
                  }
                  _showSubscribeDialog(plan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.isPopular
                      ? AppColors.primaryViolet
                      : (isCurrent
                          ? (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated)
                          : AppColors.primaryIndigo),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  isCurrent
                      ? 'Текущий тариф'
                      : (plan.id == 'free' ? 'Перейти на Старт' : 'Попробовать 7 дней бесплатно'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Интерактивный калькулятор экономии времени педагога
  Widget _buildTimeSavingsCalculator(bool isDark) {
    final hoursSavedPerWeek = (_weeklyLessons * 0.8).round();
    final costPerLesson = _isAnnualBilling
        ? (2390 / (10 * _weeklyLessons * 4)).toStringAsFixed(1)
        : (299 / (_weeklyLessons * 4)).toStringAsFixed(1);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.accentCyan, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Калькулятор выгоды и окупаемости времени',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сколько уроков вы ведете в неделю?',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              Text(
                '${_weeklyLessons.toInt()} уроков',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
              ),
            ],
          ),
          Slider(
            value: _weeklyLessons,
            min: 4,
            max: 32,
            divisions: 14,
            activeColor: AppColors.primaryIndigo,
            inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            onChanged: (val) => setState(() => _weeklyLessons = val),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Экономия времени:', style: TextStyle(fontSize: 11.5)),
                      const SizedBox(height: 2),
                      Text(
                        '~$hoursSavedPerWeek ч / неделю',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success),
                      ),
                      Text('свободы для семьи и отдыха', style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Себестоимость урока:', style: TextStyle(fontSize: 11.5)),
                      const SizedBox(height: 2),
                      Text(
                        '~$costPerLesson ₽ за урок',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryViolet),
                      ),
                      Text('дешевле чашки чая', style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Диалог оформления подписки
  void _showSubscribeDialog(PricingPlan plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedPayment = 'sbp';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          title: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.accentCyan),
              const SizedBox(width: 8),
              Text('Тариф «${plan.name}»'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAnnualBilling
                    ? 'Годовая подписка: ${plan.annualTotalPrice} ₽ / год (выгода 35%)'
                    : 'Помесячная подписка: ${plan.monthlyPrice} ₽ / месяц',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Первые 7 дней — бесплатно! Списание начнется только через неделю. Вы можете отменить подписку в любой момент в 1 клик.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text('Способ оплаты:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                dense: true,
                title: const Text('СБП (Система быстрых платежей 0% комиссии)', style: TextStyle(fontSize: 12.5)),
                value: 'sbp',
                groupValue: selectedPayment,
                onChanged: (v) => setDialogState(() => selectedPayment = v!),
              ),
              RadioListTile<String>(
                dense: true,
                title: const Text('Банковская карта (МИР, Visa, Mastercard РФ)', style: TextStyle(fontSize: 12.5)),
                value: 'card',
                groupValue: selectedPayment,
                onChanged: (v) => setDialogState(() => selectedPayment = v!),
              ),
              RadioListTile<String>(
                dense: true,
                title: const Text('SberPay / Mir Pay в 1 касание', style: TextStyle(fontSize: 12.5)),
                value: 'mirpay',
                groupValue: selectedPayment,
                onChanged: (v) => setDialogState(() => selectedPayment = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<AppProvider>().setUserTier(plan.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Тариф «${plan.name}» успешно активирован на 7 дней бесплатно!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Активировать 7 дней бесплатно'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'pro':
        return const Color(0xFFFFB300);
      case 'practice':
        return AppColors.accentCyan;
      default:
        return Colors.white70;
    }
  }

  String _getTierLabel(String tier) {
    switch (tier) {
      case 'pro':
        return 'ТАРИФ PRO';
      case 'practice':
        return 'ТАРИФ ПРАКТИК';
      default:
        return 'ТАРИФ СТАРТ';
    }
  }
}
