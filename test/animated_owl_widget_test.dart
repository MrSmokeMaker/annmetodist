import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/widgets/animated_owl_widget.dart';

void main() {
  group('AnimatedOwlWidget Tests', () {
    testWidgets('renders properly in idle state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.idle,
              size: 100,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOwlWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders in thinking state with glow aura', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.thinking,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOwlWidget), findsOneWidget);
    });

    testWidgets('renders in speaking and listening states', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.speaking,
              size: 90,
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedOwlWidget), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.listening,
              size: 90,
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedOwlWidget), findsOneWidget);
    });

    testWidgets('tap triggers callback', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.idle,
              size: 100,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedOwlWidget));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);

      // Advance clock past the wink duration so timer does not leak
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('renders speech bubble when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOwlWidget(
              state: OwlState.idle,
              size: 100,
              showSpeechBubble: true,
              speechText: 'У-ху! Я готов помочь!',
            ),
          ),
        ),
      );

      expect(find.text('У-ху! Я готов помочь!'), findsOneWidget);
    });
  });
}
