import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metodist/models/method_prompt.dart';
import 'package:metodist/models/quarter_plan.dart';
import 'package:metodist/models/topic.dart';
import 'package:metodist/providers/app_provider.dart';
import 'package:metodist/services/storage_service.dart';
import 'package:metodist/data/method_repository.dart';

class MockMethodRepository extends MethodRepository {
  final List<MethodPrompt> _mockMethods;
  final List<Topic> _mockTopics;

  MockMethodRepository(this._mockMethods, this._mockTopics);

  @override
  List<MethodPrompt> get methods => _mockMethods;

  @override
  List<Topic> get topics => _mockTopics;

  @override
  Future<void> loadData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppProvider provider;
  late MethodPrompt sampleMethod;
  late List<Topic> sampleTopics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sampleMethod = const MethodPrompt(
      id: 'pchelko_math',
      name: 'Арифметика Пчёлко',
      subject: 'Математика',
      description: 'Классика',
      promptBlock: 'Методика',
    );

    sampleTopics = [
      const Topic(id: 't1', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Счёт до 10'),
      const Topic(id: 't2', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Число 5'),
      const Topic(id: 't3', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Число 6'),
      const Topic(id: 't4', methodId: 'pchelko_math', ageGroup: 'grade_1', title: 'Сложение'),
    ];

    final storage = StorageService();
    await storage.init();
    final repo = MockMethodRepository([sampleMethod], sampleTopics);
    provider = AppProvider(storageService: storage, methodRepository: repo);
  });

  group('Quarter Batch Planning & Calendar Integration Tests', () {
    test('1. AppProvider starts quarter planning and generates topics', () async {
      final plan = await provider.startQuarterPlanning(
        method: sampleMethod,
        ageGroup: '1 класс',
        quarterNumber: 2,
        lessonsCount: 4,
        useAi: false,
      );

      expect(plan.quarterNumber, equals(2));
      expect(plan.topics.length, equals(4));
      expect(provider.activeQuarterPlan, isNotNull);
      expect(provider.activeQuarterPlan!.topics.length, equals(4));

      // Проверяем уведомление
      expect(provider.notificationService.notifications.isNotEmpty, isTrue);
      expect(provider.notificationService.notifications.first.title, contains('2 четверть'));
    });

    test('2. AppProvider edits topic title manually', () async {
      final plan = await provider.startQuarterPlanning(
        method: sampleMethod,
        ageGroup: '1 класс',
        quarterNumber: 1,
        lessonsCount: 4,
        useAi: false,
      );

      provider.updateQuarterTopicTitle(1, 'Кастомная тема учителя: Римские цифры');

      expect(provider.activeQuarterPlan!.topics[1].title, equals('Кастомная тема учителя: Римские цифры'));
    });

    test('3. AppProvider distributes quarter lessons in calendar', () async {
      final plan = await provider.startQuarterPlanning(
        method: sampleMethod,
        ageGroup: '1 класс',
        quarterNumber: 1,
        lessonsCount: 4,
        useAi: false,
      );

      final startDate = DateTime(2026, 9, 1);
      final weekdays = [DateTime.monday, DateTime.wednesday, DateTime.friday];

      await provider.distributeQuarterInCalendar(
        plan,
        startDate: startDate,
        weekdays: weekdays,
        time: '10:00',
        studentClass: '1-А класс',
      );

      expect(provider.activeQuarterPlan!.isCalendarScheduled, isTrue);
      expect(provider.scheduledLessons.length, greaterThanOrEqualTo(4));

      final scheduled = provider.scheduledLessons.where((l) => l.studentOrClass == '1-А класс').toList();
      expect(scheduled.length, equals(4));
      expect(scheduled.first.time, equals('10:00'));
      expect(scheduled.first.topic, equals(plan.topics.first.title));

      // Проверяем уведомление о календаре
      expect(provider.notificationService.notifications.first.title, contains('календаре'));
    });
  });
}
