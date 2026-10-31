/// Модель тарифного плана приложения «Методист»
class PricingPlan {
  final String id;
  final String name;
  final String subtitle;
  final int monthlyPrice;
  final int annualMonthlyPrice;
  final int annualTotalPrice;
  final int discountPercent;
  final String? badge;
  final bool isPopular;
  final List<String> features;
  final String description;

  const PricingPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.monthlyPrice,
    required this.annualMonthlyPrice,
    required this.annualTotalPrice,
    required this.discountPercent,
    this.badge,
    this.isPopular = false,
    required this.features,
    required this.description,
  });

  /// Форматированная цена в зависимости от периода
  String getPriceLabel(bool isAnnual) {
    if (monthlyPrice == 0) return '0 ₽';
    final price = isAnnual ? annualMonthlyPrice : monthlyPrice;
    return '$price ₽ / мес';
  }

  /// Пояснение к расчетному периоду
  String getBillingPeriodNote(bool isAnnual) {
    if (monthlyPrice == 0) return 'Навсегда бесплатно';
    if (isAnnual) {
      final savings = (monthlyPrice * 12) - annualTotalPrice;
      return '$annualTotalPrice ₽ в год (экономия $savings ₽)';
    }
    return 'Оплата раз в месяц';
  }

  static PricingPlan get director => defaultPlans.firstWhere((p) => p.id == 'director');
  static PricingPlan get developer => director;

  /// Базовые планы приложения
  static const List<PricingPlan> defaultPlans = [
    PricingPlan(
      id: 'free',
      name: 'Старт',
      subtitle: 'Для первого знакомства с приложением',
      monthlyPrice: 0,
      annualMonthlyPrice: 0,
      annualTotalPrice: 0,
      discountPercent: 0,
      description: 'Базовый набор для редких разовых уроков',
      features: [
        '5 конспектов в месяц',
        '1 базовый вариант урока',
        'Каталог проверенных тем ФГОС',
        'Просмотр карточек уроков',
        'Печать простого текста',
        'Локальное сохранение',
      ],
    ),
    PricingPlan(
      id: 'practice',
      name: 'Практик',
      subtitle: 'Хит для школьных учителей и репетиторов',
      monthlyPrice: 299,
      annualMonthlyPrice: 199,
      annualTotalPrice: 2390,
      discountPercent: 35,
      badge: 'ХИТ ВЫГОДЫ',
      isPopular: true,
      description: 'Закрывает всю учебную нагрузку учителя на месяц',
      features: [
        '60 конспектов в месяц (хватит на все уроки)',
        'До 3 вариантов дифференциации на класс',
        'Листы заданий с 6 механиками',
        'Домашние задания с памяткой для родителей',
        'Режим Eco-Print (экономия картриджа до 1000 ₽)',
        'Экспорт в премиум PDF (клетка 5х5 и косая линейка)',
        'Облачное хранилище на 200 уроков',
      ],
    ),
    PricingPlan(
      id: 'pro',
      name: 'Методист Pro',
      subtitle: 'Для завучей, авторов программ и кафедр',
      monthlyPrice: 699,
      annualMonthlyPrice: 449,
      annualTotalPrice: 5390,
      discountPercent: 35,
      badge: 'МАКСИМУМ',
      description: 'Безлимитный доступ и эксклюзивные функции',
      features: [
        'Безлимитные генерации без счета',
        'Премиум-дизайн PDF со школьной разлиновкой',
        'Дидактические карточки для вырезания',
        'Арт-пакет YandexART: иллюстрации, маскот, раскраски, медали',
        'Адаптация для детей с ОВЗ и ЗПР (инклюзия)',
        'Базовый конструктор методик и адаптация',
        'Экспорт в Word (DOCX) под требования завуча',
        'Аудио-скрипты объяснений для родителей',
        'Совместный доступ до 3 педагогов',
        'Приоритетная очередь нейросети',
      ],
    ),
    PricingPlan(
      id: 'director',
      name: 'Директор',
      subtitle: 'Флагманский тариф для директоров, завучей, кафедр и гимназий',
      monthlyPrice: 1499,
      annualMonthlyPrice: 1199,
      annualTotalPrice: 14388,
      discountPercent: 20,
      badge: 'ФЛАГМАН',
      description: 'Корпоративная идентичность школы, Студия миров, авторские методики, REST API и пакетный курс на четверть',
      features: [
        '⭐ Все возможности тарифа «Методист Pro»',
        '🎨 [ДИРЕКТОР] Студия авторских миров: переключение 5 вселенных',
        '🏫 [ДИРЕКТОР] Собственный маскот школы/класса в YandexART',
        '🎯 [ДИРЕКТОР] Кастомные палитры, названия миссий и фразы поддержки',
        '🖌️ [ДИРЕКТОР] Прямое управление промптами и стилями YandexART',
        '🧩 [ДИРЕКТОР] Конструктор авторских методик (тон, стоп-слова, этапы)',
        '⚡ [ДИРЕКТОР] Персональный REST API и экспорт в JSON/HTML (МЭШ, Сферум)',
        '📦 [ДИРЕКТОР] Пакетный генератор курса на четверть (15–30 уроков) в ZIP',
        '🔬 [ДИРЕКТОР] Лаборатория отладки и лог двухпроходного Self-Refine',
        '👥 [ДИРЕКТОР] Командный доступ кафедры (до 5 рабочих мест)',
      ],
    ),
  ];
}