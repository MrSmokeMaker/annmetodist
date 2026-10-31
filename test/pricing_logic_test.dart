import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/pricing_plan.dart';
import 'package:metodist/models/tariff.dart';

void main() {
  group('Pricing Plan and Monetization Logic Tests', () {
    test('PricingPlan defaultPlans contain free, practice, pro, and director tiers', () {
      final plans = PricingPlan.defaultPlans;
      expect(plans.length, 4);

      final planIds = plans.map((p) => p.id).toList();
      expect(planIds, contains('free'));
      expect(planIds, contains('practice'));
      expect(planIds, contains('pro'));
      expect(planIds, contains('director'));
    });

    test('Director tier offers 1 199 ₽/month annually and 1 499 ₽/month monthly', () {
      final director = PricingPlan.defaultPlans.firstWhere((p) => p.id == 'director');

      expect(director.name, 'Директор');
      expect(director.monthlyPrice, 1499);
      expect(director.annualMonthlyPrice, 1199);
      expect(director.annualTotalPrice, 14388);
      expect(director.badge, 'ФЛАГМАН');

      // Price labels
      expect(director.getPriceLabel(false), '1499 ₽ / мес');
      expect(director.getPriceLabel(true), '1199 ₽ / мес');
      expect(director.getBillingPeriodNote(true), contains('14388 ₽ в год'));
      expect(director.getBillingPeriodNote(true), contains('экономия'));

      // Check director features
      final featuresJoined = director.features.join(' ');
      expect(featuresJoined, contains('Студия авторских миров'));
      expect(featuresJoined, contains('Конструктор авторских методик'));
      expect(featuresJoined, contains('REST API'));
      expect(featuresJoined, contains('Пакетный генератор курса на четверть'));
      expect(featuresJoined, contains('Лаборатория отладки'));
      expect(featuresJoined, contains('Командный доступ кафедры'));
      expect(featuresJoined, contains('YandexART'));
      expect(featuresJoined, contains('Все возможности тарифа «Методист Pro»'));
    });

    test('Practice tier offers discount for annual billing and key value features', () {
      final practice = PricingPlan.defaultPlans.firstWhere((p) => p.id == 'practice');

      // Проверка цен
      expect(practice.monthlyPrice, 299);
      expect(practice.annualMonthlyPrice, 199);
      expect(practice.annualTotalPrice, 2390);

      // Проверка меток цены
      expect(practice.getPriceLabel(false), '299 ₽ / мес');
      expect(practice.getPriceLabel(true), '199 ₽ / мес');
      expect(practice.getBillingPeriodNote(true), contains('экономия'));

      // Проверка фич тарифа «Практик»
      final featuresJoined = practice.features.join(' ');
      expect(featuresJoined, contains('60 конспектов'));
      expect(featuresJoined, contains('Листы заданий'));
      expect(featuresJoined, contains('Домашние задания'));
      expect(featuresJoined, contains('Eco-Print'));
      expect(featuresJoined, contains('премиум PDF'));
    });

    test('Pro tier offers inclusive OVR/ZPR, Word export, and multi-user access', () {
      final pro = PricingPlan.defaultPlans.firstWhere((p) => p.id == 'pro');

      // Проверка цен
      expect(pro.monthlyPrice, 699);
      expect(pro.annualMonthlyPrice, 449);
      expect(pro.annualTotalPrice, 5390);

      // Проверка ценности для администрации и завучей
      final featuresJoined = pro.features.join(' ');
      expect(featuresJoined, contains('Безлимит'));
      expect(featuresJoined, contains('ОВЗ'));
      expect(featuresJoined, contains('Word'));
      expect(featuresJoined, contains('до 3 педагогов'));
    });
  });

  group('TariffLevel Enum and Capabilities', () {
    test('TariffLevel director grants exclusive privileges', () {
      const director = TariffLevel.director;
      expect(director.isDirector, isTrue);
      expect(director.isProOrHigher, isTrue);
      expect(director.canSwitchThematicWorlds, isTrue);
      expect(director.canCreateCustomMascot, isTrue);
      expect(director.canUseCustomMethodology, isTrue);
      expect(director.canUseRestApi, isTrue);
      expect(director.canGenerateQuarterCourse, isTrue);
      expect(director.maxTeamSeats, 5);

      const pro = TariffLevel.pro;
      expect(pro.isDirector, isFalse);
      expect(pro.canSwitchThematicWorlds, isFalse);
      expect(pro.canCreateCustomMascot, isFalse);
      expect(pro.canUseRestApi, isFalse);
      expect(pro.maxTeamSeats, 1);
    });
  });
}
