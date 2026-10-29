import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/activity_technique.dart';

void main() {
  group('Activities Template Tests', () {
    test('activities.json loads and parses into enriched ActivityTechnique list', () {
      final file = File('assets/data/activities.json');
      expect(file.existsSync(), isTrue, reason: 'activities.json file must exist');

      final rawContent = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(rawContent) as List<dynamic>;

      expect(jsonList.length, greaterThanOrEqualTo(11));

      final activities = jsonList
          .map((item) => ActivityTechnique.fromJson(item as Map<String, dynamic>))
          .toList();

      for (final act in activities) {
        expect(act.id, isNotEmpty);
        expect(act.id.startsWith('act_'), isTrue);
        expect(act.title, isNotEmpty);
        expect(act.category, isNotEmpty);
        expect(act.shortDescription, isNotEmpty);

        // Проверка расширенных полей
        expect(act.durationMinutes, isNotNull);
        expect(act.durationMinutes!, greaterThan(0));
        expect(['easy', 'medium', 'hard'].contains(act.difficulty), isTrue);
        expect(act.steps.isNotEmpty, isTrue);

        for (final step in act.steps) {
          expect(step.order, greaterThan(0));
          expect(step.title, isNotEmpty);
          expect(step.description, isNotEmpty);
        }

        // Проверка effectiveSampleText
        expect(act.effectiveSampleText, isNotEmpty);
      }
    });

    test('categories.json loads and parses valid category list', () {
      final file = File('assets/data/categories.json');
      expect(file.existsSync(), isTrue);

      final rawContent = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(rawContent) as List<dynamic>;

      expect(jsonList.isNotEmpty, isTrue);
      for (final item in jsonList) {
        final map = item as Map<String, dynamic>;
        expect(map['id'], isNotEmpty);
        expect(map['name'], isNotEmpty);
      }
    });
  });
}
