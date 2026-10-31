enum TariffLevel { free, premium, developer }

class UserTariff {
  final TariffLevel level;
  const UserTariff(this.level);
}
