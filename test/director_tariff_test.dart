import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/custom_methodology.dart';
import 'package:metodist/models/custom_world_config.dart';
import 'package:metodist/models/department_team.dart';

void main() {
  group('Director Tariff Models and Custom Studio Tests', () {
    test('CustomWorldConfig defaultLyceum initializes correctly', () {
      final config = CustomWorldConfig.defaultLyceum();

      expect(config.schoolName, contains('Лицей №1'));
      expect(config.mascotName, contains('Архимед'));
      expect(config.missionTitle, contains('Миссия Лицея'));
      expect(config.teacherSlogans.length, greaterThanOrEqualTo(3));
      expect(config.primaryColorHex, 0xFF4F46E5);
      expect(config.yandexArtStylePrompt, contains('диафильм'));
      expect(config.isCustomHeaderGenerated, isTrue);

      final json = config.toJson();
      final restored = CustomWorldConfig.fromJson(json);
      expect(restored.schoolName, config.schoolName);
      expect(restored.mascotName, config.mascotName);
      expect(restored.teacherSlogans, config.teacherSlogans);
    });

    test('CustomMethodology defaults and serialization', () {
      final method = CustomMethodology.defaultLyceumMethodology();

      expect(method.title, contains('Лицейского'));
      expect(method.tone, PedagogicalTone.trizGaming);
      expect(method.stopWords, contains('просто запомни'));
      expect(method.strictPchelkoMultiplierCheck, isTrue);
      expect(method.requireReflectiveQuestions, isTrue);
      expect(method.enforceFgosComplianceReport, isTrue);

      final json = method.toJson();
      final restored = CustomMethodology.fromJson(json);
      expect(restored.title, method.title);
      expect(restored.tone, PedagogicalTone.trizGaming);
      expect(restored.stopWords.length, method.stopWords.length);
    });

    test('DepartmentTeam seats and capacity', () {
      final team = DepartmentTeam.createDefault();

      expect(team.maxSeats, 5);
      expect(team.members.length, 3);
      expect(team.activeSeatsCount, 3);
      expect(team.remainingSeats, 2);
      expect(team.canAddMember, isTrue);

      final json = team.toJson();
      final restored = DepartmentTeam.fromJson(json);
      expect(restored.teamName, team.teamName);
      expect(restored.maxSeats, 5);
      expect(restored.members.length, 3);
    });
  });
}
