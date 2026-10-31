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

  static PricingPlan get developer => defaultPlans.firstWhere((p) => p.id == 'developer');

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
        'Конструктор собственных авторских методик',
        'Экспорт в Word (DOCX) под требования завуча',
        'Аудио-скрипты объяснений для родителей',
        'Совместный доступ до 3 педагогов',
        'Приоритетная очередь нейросети',
      ],
    ),
    PricingPlan(
      id: 'developer',
      name: 'Разработчик',
      subtitle: 'Флагманский тариф для авторов, кафедр и гимназий',
      monthlyPrice: 1499,
      annualMonthlyPrice: 1199,
      annualTotalPrice: 14388,
      discountPercent: 20,
      badge: 'ФЛАГМАН',
      description: 'Полная свобода кастомизации, Студия миров, REST API и командный доступ',
      features: [
        '🎨 Студия авторских миров: выбор и переключение 5 миров',
        '✨ Создание собственного маскота школы/класса в YandexART',
        '🎯 Кастомные палитры, названия миссий и фразы поддержки',
        '🖌️ Прямое управление промптами и арт-стилями YandexART',
        '🧩 Конструктор авторских методик с настройкой тона YandexGPT Pro',
        '⚡ REST API и экспорт в JSON/HTML для МЭШ, ЭЖД и Сферум',
        '📦 Пакетный генератор курса на четверть (15–30 уроков в ZIP)',
        '🔬 Лаборатория отладки: лог двухпроходного Self-Refine и токены',
        '👥 Командный доступ кафедры (до 5 рабочих мест)',
      ],
    ),
  ];
}
