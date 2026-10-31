import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/models/app_story.dart';
import 'package:metodist/widgets/stories_tray_widget.dart';
import 'package:metodist/widgets/stories_player_modal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'viewed_stories_ids': <String>[]});
  });

  group('AppStories Data and Model Tests', () {
    test('getSampleStories returns 6 rich educational stories', () {
      final stories = AppStoriesData.getSampleStories();
      expect(stories.length, equals(6));

      for (final story in stories) {
        expect(story.id.isNotEmpty, isTrue);
        expect(story.title.isNotEmpty, isTrue);
        expect(story.authorName.isNotEmpty, isTrue);
        expect(story.slides.isNotEmpty, isTrue);
        for (final slide in story.slides) {
          expect(slide.id.isNotEmpty, isTrue);
          expect(slide.badge.isNotEmpty, isTrue);
          expect(slide.title.isNotEmpty, isTrue);
          expect(slide.bulletPoints.isNotEmpty, isTrue);
          expect(slide.ctaLabel.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Stories UI Widgets Tests', () {
    testWidgets('StoriesTrayWidget renders avatars properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoriesTrayWidget(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check titles of stories in tray
      expect(find.text('Методист Pro'), findsOneWidget);
      expect(find.text('5 Миров'), findsOneWidget);
      expect(find.text('Раздатки Pro'), findsOneWidget);
    });

    testWidgets('Tapping story avatar opens StoriesPlayerModal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoriesTrayWidget(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on first avatar
      await tester.tap(find.text('Методист Pro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Stories player should be visible
      expect(find.byType(StoriesPlayerModal), findsOneWidget);
      expect(find.text('Умный генератор уроков за секунды'), findsOneWidget);
      expect(find.text('Создать конспект'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StoriesPlayerModal), findsNothing);
    });
  });
}
