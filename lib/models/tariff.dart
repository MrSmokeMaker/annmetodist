enum TariffLevel {
  free,
  practice,
  pro,
  director;

  static const TariffLevel developer = TariffLevel.director;
}

extension TariffLevelExtension on TariffLevel {
  String get id {
    switch (this) {
      case TariffLevel.free:
        return 'free';
      case TariffLevel.practice:
        return 'practice';
      case TariffLevel.pro:
        return 'pro';
      case TariffLevel.director:
        return 'director';
    }
  }

  String get nameRu {
    switch (this) {
      case TariffLevel.free:
        return 'Старт';
      case TariffLevel.practice:
        return 'Практик';
      case TariffLevel.pro:
        return 'Методист Pro';
      case TariffLevel.director:
        return 'Директор';
    }
  }

  bool get isDirector => this == TariffLevel.director;
  bool get isDeveloper => isDirector;
  bool get isProOrHigher => this == TariffLevel.pro || this == TariffLevel.director;
  bool get canSwitchThematicWorlds => this == TariffLevel.director;
  bool get canCreateCustomMascot => this == TariffLevel.director;
  bool get canUseCustomMethodology => this == TariffLevel.director;
  bool get canUseRestApi => this == TariffLevel.director;
  bool get canGenerateQuarterCourse => this == TariffLevel.director;
  bool get canInspectTokens => this == TariffLevel.director;

  int get maxTeamSeats {
    switch (this) {
      case TariffLevel.director:
        return 5;
      case TariffLevel.pro:
        return 1;
      case TariffLevel.practice:
      case TariffLevel.free:
        return 1;
    }
  }

  static TariffLevel fromId(String? id) {
    switch (id?.toLowerCase()) {
      case 'director':
      case 'директор':
      case 'developer':
      case 'разработчик':
        return TariffLevel.director;
      case 'pro':
      case 'premium':
        return TariffLevel.pro;
      case 'practice':
      case 'практик':
        return TariffLevel.practice;
      default:
        return TariffLevel.free;
    }
  }
}

class TariffLevelExt {
  final UserTariff tariff;
  TariffLevelExt(this.tariff);

  bool get isDeveloper => tariff.isDirector;
  bool get isDirector => tariff.isDirector;

  static TariffLevel fromString(String str) => TariffLevelExtension.fromId(str);
}

class UserTariff {
  final TariffLevel level;
  final DateTime? validUntil;
  final bool isAnnual;

  const UserTariff(
    this.level, {
    this.validUntil,
    this.isAnnual = true,
  });

  bool get isDirector => level.isDirector;
  bool get isDeveloper => isDirector;
  bool get isProOrHigher => level.isProOrHigher;
  bool get canSwitchThematicWorlds => level.canSwitchThematicWorlds;

  static UserTariff fromString(String str) {
    return UserTariff(TariffLevelExtension.fromId(str));
  }
}
