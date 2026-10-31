import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/widgets/telegram_bots_sheet.dart';

void main() {
  group('TelegramBotsSheet and TelegramBotsMenuButton Widget Tests', () {
    testWidgets('TelegramBotsMenuButton renders in full and compact modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TelegramBotsMenuButton(isCompact: false),
                TelegramBotsMenuButton(isCompact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Telegram боты'), findsOneWidget);
      expect(find.text('@annmetodist & @MetodistAI'), findsOneWidget);
      expect(find.text('Боты'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNWidgets(2));
    });

    testWidgets('Tapping TelegramBotsMenuButton opens TelegramBotsSheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 800));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelegramBotsMenuButton(isCompact: false),
          ),
        ),
      );

      await tester.tap(find.byType(TelegramBotsMenuButton));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Экосистема Telegram'), findsOneWidget);
      expect(find.text('2 БОТА'), findsOneWidget);

      // Check Bot 1
      expect(find.text('Методист Pro | Mini App'), findsOneWidget);
      expect(find.text('@annmetodist_bot'), findsOneWidget);
      expect(find.text('Mini App 🚀'), findsOneWidget);

      // Check Bot 2
      expect(find.text('Metodist AI Pro | Ассистент'), findsOneWidget);
      expect(find.text('@MetodistAIpro_bot'), findsOneWidget);
      expect(find.text('👑 Директор'), findsOneWidget);

      // Switch to Commands Tab
      await tester.tap(find.text('Команды и фичи ⚡'));
      await tester.pumpAndSettle();

      expect(find.textContaining('/addaction родителям'), findsOneWidget);
      expect(find.textContaining('/addaction дз3уровня'), findsOneWidget);
      expect(find.textContaining('/actions'), findsOneWidget);
    });
  });
}
