import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/tariff.dart';
import 'package:metodist/services/audio_speech_service.dart';
import 'package:metodist/services/dictation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tariff Audio Features Permissions Test', () {
    test('Free tariff cannot use Audio Note Studio or Dictation', () {
      const tariff = TariffLevel.free;
      expect(tariff.canUseAudioSpeechStudio, isFalse);
      expect(tariff.canUseAudioDictation, isFalse);
    });

    test('Practice tariff cannot use Audio Note Studio or Dictation', () {
      const tariff = TariffLevel.practice;
      expect(tariff.canUseAudioSpeechStudio, isFalse);
      expect(tariff.canUseAudioDictation, isFalse);
    });

    test('Pro tariff can use Audio Note Studio and Dictation', () {
      const tariff = TariffLevel.pro;
      expect(tariff.canUseAudioSpeechStudio, isTrue);
      expect(tariff.canUseAudioDictation, isTrue);
    });

    test('Director tariff can use Audio Note Studio and Dictation', () {
      const tariff = TariffLevel.director;
      expect(tariff.canUseAudioSpeechStudio, isTrue);
      expect(tariff.canUseAudioDictation, isTrue);
    });
  });

  group('DictationService Extraction Tests', () {
    test('Extracts Russian orthographic dictation correctly', () {
      final conspect = Conspect(
        id: 'c-ru-1',
        title: 'Правописание безударных гласных в корне',
        topic: 'Безударные гласные',
        methodName: 'Костин Н.А.',
        methodId: 'kostin',
        subject: 'Русский язык',
        ageGroup: '2 класс',
        duration: '45 минут',
        content: '''
# План урока
## Этап 3. Первичное закрепление
Диктант слов: трава, река, сосна, дворы, вода.
Обратите внимание на безударную букву о в слове вода и букву е в слове река.
        ''',
        createdAt: DateTime.now(),
      );

      final exercise = DictationService.extractDictation(
        content: conspect.content,
        topic: conspect.topic,
        subject: 'Русский язык',
        ageGroup: conspect.ageGroup,
      );
      expect(exercise.subject, equals('Русский язык'));
      expect(exercise.items, isNotEmpty);
      expect(exercise.ageGroup, equals('2 класс'));

      // Check first item properties
      final firstItem = exercise.items.first;
      expect(firstItem.spokenText, isNotEmpty);
      expect(firstItem.cleanWord, isNotEmpty);
      expect(firstItem.ruleHint, isNotEmpty);
      expect(firstItem.pauseSeconds, greaterThanOrEqualTo(3));
    });

    test('Extracts Math arithmetic dictation correctly', () {
      final conspect = Conspect(
        id: 'c-math-1',
        title: 'Сложение и вычитание в пределах 20',
        topic: 'Устный счёт',
        methodName: 'Пчёлко А.С.',
        methodId: 'pchelko',
        subject: 'Математика',
        ageGroup: '1 класс',
        duration: '45 минут',
        content: '''
# План урока
## Этап 2. Устный счёт
Решите примеры:
- К 7 прибавить 5
- От 14 отнять 6
- 8 + 4
        ''',
        createdAt: DateTime.now(),
      );

      final exercise = DictationService.extractDictation(
        content: conspect.content,
        topic: conspect.topic,
        subject: 'Математика',
        ageGroup: conspect.ageGroup,
      );
      expect(exercise.subject, equals('Математика'));
      expect(exercise.items, isNotEmpty);
      expect(exercise.items.length, greaterThan(0));

      final firstMath = exercise.items.first;
      expect(firstMath.spokenText, isNotEmpty);
      expect(firstMath.cleanWord, isNotEmpty);
      expect(firstMath.pauseSeconds, inInclusiveRange(4, 7));
    });

    test('Falls back to safe default items for sparse conspect', () {
      final exercise = DictationService.extractDictation(
        content: 'Краткий текст без выраженных упражнений.',
        topic: 'Вводное занятие',
        subject: 'Русский язык',
        ageGroup: '3 класс',
      );

      expect(exercise.items, isNotEmpty);
      expect(exercise.items.length, greaterThanOrEqualTo(3));
    });
  });

  group('AudioSpeechService & Platform Stub Tests', () {
    final audio = AudioSpeechService.instance;

    test('Speech lifecycle methods execute cleanly in stub environment', () {
      expect(audio.isSpeaking, isFalse);

      final success = audio.speak('Тестовая фраза для диктанта', rate: 0.9, pitch: 1.0);
      expect(success, isTrue);
      expect(audio.isSpeaking, isTrue);

      audio.pause();
      audio.resume();
      audio.stop();
      expect(audio.isSpeaking, isFalse);
    });

    test('School bell sound and gong trigger without throwing', () {
      expect(() => audio.playSchoolBell(), returnsNormally);
      expect(() => audio.playClickGong(), returnsNormally);
    });
  });
}
