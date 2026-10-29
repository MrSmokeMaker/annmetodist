import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // Tier is synchronized with AppProvider

  @override
  Widget build(BuildContext context) {
    final user = _supabaseService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final _currentTier = provider.userTier;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Профиль и подписка',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
              const SizedBox(height: 16),

              // User Info Card
              GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: AppRadii.lg,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppGradients.violetMagenta,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryViolet.withOpacity(0.35),
                            blurRadius: 12,
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
                            fontWeight: FontWeight.bold,
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getTierColor(_currentTier).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getTierColor(_currentTier).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getTierLabel(_currentTier),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getTierColor(_currentTier),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user != null ? 'Облако активно' : 'Только локально',
                                style: TextStyle(
                                  fontSize: 12,
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
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: const Text('Войти', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title for Pricing
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.primaryViolet, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Тарифные планы',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pricing Cards Carousel / Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTierCard('free', 'Старт', '0 ₽', _currentTier, 'Для знакомства с приложением', [
                              '5 конспектов в месяц',
                              'Базовые методики ФГОС',
                              '1 вариант на занятие',
                              'Просмотр карточек уроков',
                              'Локальное сохранение',
                            ], false)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildTierCard('practice', 'Практик', '299 ₽ / мес', _currentTier, 'Для активных педагогов и репетиторов', [
                              '60 конспектов в месяц',
                              'Вся библиотека методик (ТРИЗ, Монтессори)',
                              'До 3 вариантов дифференциации',
                              'Генерация и печать карточек',
                              'Экспорт в красивый PDF',
                              'Облако на 200 конспектов',
                            ], true)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildTierCard('pro', 'Методист Pro', '699 ₽ / мес', _currentTier, 'Для авторов программ и руководителей', [
                              'Безлимитные конспекты',
                              'Конструктор своих методик',
                              'До 5 вариантов + адаптация ОВЗ',
                              'Карточки + рабочие листы + ДЗ',
                              'Экспорт в PDF и Word (DOCX)',
                              'Аудио-скрипты для родителей',
                              'Безлимитное облако и бэкап',
                            ], false)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTierCard('free', 'Старт', '0 ₽', _currentTier, 'Для знакомства с приложением', [
                              '5 конспектов в месяц',
                              'Базовые методики ФГОС',
                              '1 вариант на занятие',
                              'Просмотр карточек уроков',
                              'Локальное сохранение',
                            ], false),
                            const SizedBox(height: 14),
                            _buildTierCard('practice', 'Практик', '299 ₽ / мес', _currentTier, 'Для активных педагогов и репетиторов', [
                              '60 конспектов в месяц',
                              'Вся библиотека методик (ТРИЗ, Монтессори)',
                              'До 3 вариантов дифференциации',
                              'Генерация и печать карточек',
                              'Экспорт в красивый PDF',
                              'Облако на 200 конспектов',
                            ], true),
                            const SizedBox(height: 14),
                            _buildTierCard('pro', 'Методист Pro', '699 ₽ / мес', _currentTier, 'Для авторов программ и руководителей', [
                              'Безлимитные конспекты',
                              'Конструктор своих методик',
                              'До 5 вариантов + адаптация ОВЗ',
                              'Карточки + рабочие листы + ДЗ',
                              'Экспорт в PDF и Word (DOCX)',
                              'Аудио-скрипты для родителей',
                              'Безлимитное облако и бэкап',
                            ], false),
                          ],
                        );
                },
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('Возможность')),
                          DataColumn(label: Text('Старт (0 ₽)')),
                          DataColumn(label: Text('Практик (299 ₽)')),
                          DataColumn(label: Text('Pro (699 ₽)')),
                        ],
                        rows: const [
                          DataRow(cells: [
                            DataCell(Text('Генераций конспектов')),
                            DataCell(Text('5 / мес')),
                            DataCell(Text('60 / мес')),
                            DataCell(Text('Безлимитно ✨')),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Вариантов на занятие')),
                            DataCell(Text('1 вариант')),
                            DataCell(Text('3 варианта')),
                            DataCell(Text('До 5 + ОВЗ')),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Дидактические карточки')),
                            DataCell(Text('Только предпросмотр')),
                            DataCell(Text('Печать и экспорт')),
                            DataCell(Text('Карточки + Листы + ДЗ')),
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
                            DataCell(Text('Облачное хранилище')),
                            DataCell(Text('10 конспектов')),
                            DataCell(Text('200 конспектов')),
                            DataCell(Text('Без ограничений')),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Свой API-ключ Yandex')),
                            DataCell(Text('—')),
                            DataCell(Text('Поддерживается')),
                            DataCell(Text('Поддерживается')),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    String tierKey,
    String title,
    String price,
    String currentTier,
    String subtitle,
    List<String> features,
    bool isPopular,
  ) {
    final isCurrent = currentTier == tierKey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isPopular ? AppColors.primaryViolet : (isCurrent ? AppColors.accentCyan : Colors.white.withOpacity(0.12)),
          width: isPopular || isCurrent ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: AppColors.primaryViolet.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.violetMagenta,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ПОПУЛЯРНЫЙ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<AppProvider>().setUserTier(tierKey);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Выбран тариф «$title». Модуль оплаты будет подключен далее!'),
                      backgroundColor: AppColors.primaryIndigo,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular
                      ? AppColors.primaryViolet
                      : (isCurrent ? Colors.white.withOpacity(0.15) : AppColors.primaryIndigo),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  isCurrent ? 'Текущий план' : (tierKey == 'free' ? 'Выбрать' : 'Перейти на $title'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
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
