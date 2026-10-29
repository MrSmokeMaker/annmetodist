import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/printable_card.dart';
import 'package:metodist/services/yandex_art_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YandexArtService & Pro Visual Features Tests', () {
    test('generateFallbackEducationalArt generates valid non-empty base64 PNG', () async {
      final base64Art = await YandexArtService.generateFallbackEducationalArt(
        type: 'card',
        label: 'Яблоко',
        width: 100,
        height: 100,
      );

      expect(base64Art, isNotEmpty);
      final bytes = base64Decode(base64Art);
      // Valid PNG header starts with [137, 80, 78, 71]
      expect(bytes.length, greaterThan(8));
      expect(bytes[0], 137);
      expect(bytes[1], 80);
      expect(bytes[2], 78);
      expect(bytes[3], 71);
    });

    test('Conspect correctly stores and serializes YandexART illustrations', () {
      final conspect = Conspect(
        id: 'test_art_conspect',
        title: 'Урок с YandexART',
        methodId: 'redo',
        methodName: 'Редозубов',
        subject: 'Чтение',
        ageGroup: '5-6',
        topic: 'Гласные буквы',
        duration: '25 мин',
        content: '# Конспект\n\nТело урока',
        cards: [
          PrintableCard(
            id: 'c1',
            frontText: 'А',
            backText: 'Арбуз',
            imageHint: 'Спелый арбуз',
            imageUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
          ),
        ],
        illustrationMascot: 'mascot_base64_data',
        illustrationColoring: 'coloring_base64_data',
        illustrationReward: 'reward_base64_data',
        createdAt: DateTime.now(),
      );

      final map = conspect.toMap();
      expect(map['illustrationMascot'], 'mascot_base64_data');
      expect(map['illustrationColoring'], 'coloring_base64_data');
      expect(map['illustrationReward'], 'reward_base64_data');
      expect(conspect.cards?.first.imageUrl, isNotEmpty);

      final reconstructed = Conspect.fromMap(map);
      expect(reconstructed.illustrationMascot, 'mascot_base64_data');
      expect(reconstructed.illustrationColoring, 'coloring_base64_data');
      expect(reconstructed.illustrationReward, 'reward_base64_data');
      expect(reconstructed.cards?.first.imageUrl, conspect.cards?.first.imageUrl);
    });
  });
}
