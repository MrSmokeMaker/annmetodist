import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/pricing_plan.dart';

void main() {
  group('Pricing Plan and Monetization Logic Tests', () {
    test('PricingPlan defaultPlans contain free, practice, pro, and developer tiers', () {
      final plans = PricingPlan.defaultPlans;
      expect(plans.length, 4);

      final planIds = plans.map((p) => p.id).toList();
      expect(planIds, contains('free'));
      expect(planIds, contains('practice'));
      expect(planIds, contains('pro'));
      expect(planIds, contains('developer'));
    });

    test('Practice tier offers 35% discount for annual billing and key value features', () {
      final practice = PricingPlan.defaultPlans.firstWhere((p) => p.id == 'practice');

      // Проверка цен
      expect(practice.monthlyPrice, 299);
      expect(practice.annualMonthlyPrice, 199);
      expect(practice.annualTotalPrice, 2390);

      // Проверка меток цены
      expect(practice.getPriceLabel(false), '299 ₽ / мес');
      expect(practice.getPriceLabel(true), '199 ₽ / мес');
      expect(practice.getBillingPeriodNote(true), contains('экономия'));

      // Проверка killer-фич тарифа «Практик»
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
}
