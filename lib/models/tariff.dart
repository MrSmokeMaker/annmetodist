enum TariffLevel {
  free,
  practice,
  pro,
  developer,
}

extension TariffLevelExt on TariffLevel {
  bool get isDeveloper => this == TariffLevel.developer;
  bool get isPro => this == TariffLevel.pro || this == TariffLevel.developer;
}

class UserTariff {
  final TariffLevel level;
  const UserTariff([this.level = TariffLevel.free]);

  bool get isDeveloper => level == TariffLevel.developer;
  bool get isProOrHigher => level == TariffLevel.pro || level == TariffLevel.developer;
  bool get isPracticeOrHigher => level != TariffLevel.free;

  String get displayName {
    switch (level) {
      case TariffLevel.free:
        return 'Старт';
      case TariffLevel.practice:
        return 'Практик';
      case TariffLevel.pro:
        return 'Методист Pro';
      case TariffLevel.developer:
        return 'Разработчик';
    }
  }

  static TariffLevel fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'practice':
        return TariffLevel.practice;
      case 'pro':
      case 'premium':
        return TariffLevel.pro;
      case 'developer':
      case 'dev':
      case 'разработчик':
        return TariffLevel.developer;
      default:
        return TariffLevel.free;
    }
  }
}
