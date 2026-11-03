import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/models/app_notification.dart';
import 'package:metodist/services/app_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppNotificationService Tests', () {
    test('1. Emits incoming notification and increases unread count', () async {
      final service = AppNotificationService();
      await service.initialize();

      expect(service.unreadCount, equals(0));
      expect(service.notifications.isEmpty, isTrue);

      final received = <AppNotification>[];
      final sub = service.onIncomingNotification.listen(received.add);

      await service.notify(
        title: 'Урок 1 готов',
        message: 'Конспект и раздаточный лист успешно созданы.',
        type: AppNotificationType.quarterProgress,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(received.length, equals(1));
      expect(received.first.title, equals('Урок 1 готов'));
      expect(service.unreadCount, equals(1));
      expect(service.notifications.length, equals(1));

      await sub.cancel();
    });

    test('2. Marks single notification as read and recalculates unread count', () async {
      final service = AppNotificationService();
      await service.initialize();

      await service.notify(title: 'A', message: '1');
      await service.notify(title: 'B', message: '2');

      expect(service.unreadCount, equals(2));

      final firstId = service.notifications.first.id;
      await service.markAsRead(firstId);

      expect(service.unreadCount, equals(1));
      expect(service.notifications.first.isRead, isTrue);
      expect(service.notifications.last.isRead, isFalse);
    });

    test('3. Marks all as read and clears history', () async {
      final service = AppNotificationService();
      await service.initialize();

      await service.notify(title: 'A', message: '1');
      await service.notify(title: 'B', message: '2');
      await service.notify(title: 'C', message: '3');

      expect(service.unreadCount, equals(3));

      await service.markAllAsRead();
      expect(service.unreadCount, equals(0));

      await service.clearAll();
      expect(service.notifications.isEmpty, isTrue);
    });
  });
}
