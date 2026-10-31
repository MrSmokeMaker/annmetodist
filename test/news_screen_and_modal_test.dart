import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/screens/news_screen.dart';
import 'package:metodist/widgets/app_news_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NewsScreen and AppNewsModal Tests', () {
    testWidgets('NewsScreen renders header and title properly', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: NewsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Что нового'), findsAtLeastNWidgets(1));
      expect(find.text('История обновлений платформы'), findsOneWidget);
    });

    testWidgets('AppNewsModal.show opens NewsScreen on mobile size', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppNewsModal.show(ctx),
                child: const Text('Open News'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open News'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Should open NewsScreen on mobile
      expect(find.byType(NewsScreen), findsOneWidget);
      expect(find.text('Что нового'), findsAtLeastNWidgets(1));
    });

    testWidgets('AppNewsModal.show opens modal dialog on desktop size', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppNewsModal.show(ctx),
                child: const Text('Open News'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open News'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AppNewsModal), findsOneWidget);
      expect(find.text('Отлично'), findsOneWidget);
    });
  });
}
