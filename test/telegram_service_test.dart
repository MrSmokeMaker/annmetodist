import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/services/telegram/telegram_web_app_service.dart';

void main() {
  group('Telegram WebApp Integration and Models', () {
    test('TelegramUser correctly parses user data from initData', () {
      final user = TelegramUser.fromMap({
        'id': 12345678,
        'first_name': 'Анна',
        'last_name': 'Иванова',
        'username': 'anna_teacher',
        'language_code': 'ru',
        'is_premium': true,
      });

      expect(user.id, 12345678);
      expect(user.firstName, 'Анна');
      expect(user.lastName, 'Иванова');
      expect(user.fullName, 'Анна Иванова');
      expect(user.displayName, '@anna_teacher');
      expect(user.isPremium, isTrue);

      final json = user.toMap();
      final restored = TelegramUser.fromMap(json);
      expect(restored.id, user.id);
      expect(restored.fullName, user.fullName);
    });

    test('TelegramThemeParams correctly parses hex colors from themeParams', () {
      final params = TelegramThemeParams.fromMap({
        'bg_color': '#0d0f14',
        'text_color': '#ffffff',
        'button_color': '#24a1de',
        'button_text_color': '#ffffff',
      });

      expect(params.bgColor, isNotNull);
      expect(params.bgColor!.value, 0xFF0D0F14);
      expect(params.buttonColor!.value, 0xFF24A1DE);
    });

    test('TelegramWebAppService behaves gracefully outside of browser (in VM tests)', () {
      final service = TelegramWebAppService();

      expect(service.isInsideTelegram, isFalse);
      expect(service.user, isNull);
      expect(service.startParam, isNull);

      // Safe no-op calls should not throw
      expect(() => service.init(), returnsNormally);
      expect(() => service.expand(), returnsNormally);
      expect(() => service.hapticSelection(), returnsNormally);
      expect(() => service.hapticImpact('heavy'), returnsNormally);
      expect(() => service.hapticNotification('success'), returnsNormally);
      expect(() => service.hideBackButton(), returnsNormally);
      expect(() => service.hideMainButton(), returnsNormally);
    });
  });
}
