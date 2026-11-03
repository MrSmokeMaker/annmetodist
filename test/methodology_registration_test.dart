import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/data/method_repository.dart';
import 'package:metodist/models/methodology_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Methodology Addition Algorithm Tests', () {
    late MethodRepository repository;

    setUp(() {
      repository = MethodRepository();
    });

    test('1. MethodologyDefinition builds full pedagogical prompt directives with field constraints', () {
      final petersonMethod = MethodologyDefinition(
        id: 'peterson_math',
        name: 'Деятельностная математика',
        authorName: 'Л. Г. Петерсон',
        year: 1996,
        subjectArea: 'Математика',
        paradigm: 'Системно-деятельностный подход и самостоятельное открытие математических истин',
        keyPrinciples: [
          'Принцип психологической комфортности',
          'Принцип деятельности: ученик сам открывает новое правило',
          'Принцип минимакса: школа предлагает максимум, ученик осваивает минимум стандарта',
        ],
        stopWords: ['заучи правило наизусть', 'делай строго по образцу без размышлений'],
        customSystemPrompt: 'Включай задачи с графическим моделированием и числовыми лучами.',
        fieldProfile: const DidacticFieldProfile(
          preferMathGrid5x5: true,
          preferNarrowObliqueRuling65: false,
          preferNumberHouses: true,
          preferCipherGrids: true,
        ),
        artStyle: ArtStylePreference.cpaRealistic,
        createdAt: DateTime.now(),
      );

      final promptBlock = petersonMethod.buildMethodPromptBlock();
      expect(promptBlock.contains('Л. Г. Петерсон'), isTrue);
      expect(promptBlock.contains('Системно-деятельностный подход'), isTrue);
      expect(promptBlock.contains('Принцип психологической комфортности'), isTrue);
      expect(promptBlock.contains('тетрадную клетку 5х5 мм по Пчёлке'), isTrue);
      expect(promptBlock.contains('числовые домики состава числа'), isTrue);
      expect(promptBlock.contains('детективные шифровки и дешифраторы'), isTrue);

      final methodPrompt = petersonMethod.toMethodPrompt();
      expect(methodPrompt.id, equals('peterson_math'));
      expect(methodPrompt.name, contains('Петерсон'));
      expect(methodPrompt.subject, equals('Математика'));
    });

    test('2. Dynamic registration of new methodology into MethodRepository', () {
      final montessoriMethod = MethodologyDefinition(
        id: 'montessori_sensory',
        name: 'Сенсорная методика',
        authorName: 'Мария Монтессори',
        year: 1907,
        subjectArea: 'Окружающий мир и развитие речи',
        paradigm: 'Свободное саморазвитие в подготовленной сенсорной среде',
        keyPrinciples: [
          'Помоги мне сделать это самому',
          'Сенсорная изоляция признака предмета',
          'Самоконтроль ошибок',
        ],
        fieldProfile: const DidacticFieldProfile(
          preferMultipleChoice: true,
          preferTrizContradiction: true,
        ),
        artStyle: ArtStylePreference.classicBookGraphic,
        createdAt: DateTime.now(),
      );

      // Register new methodology
      repository.registerCustomMethodology(montessoriMethod);

      expect(repository.customMethodologies.length, equals(1));
      expect(repository.customMethodologies.first.id, equals('montessori_sensory'));

      // Check it is also available in methods
      final registeredPrompt = repository.getMethodById('montessori_sensory');
      expect(registeredPrompt, isNotNull);
      expect(registeredPrompt!.name, contains('Монтессори'));

      // Lookup by ID
      final retrieved = repository.getCustomMethodologyById('montessori_sensory');
      expect(retrieved, isNotNull);
      expect(retrieved!.authorName, equals('Мария Монтессори'));

      // Remove methodology
      repository.removeCustomMethodology('montessori_sensory');
      expect(repository.customMethodologies.isEmpty, isTrue);
      expect(repository.getMethodById('montessori_sensory'), isNull);
    });

    test('3. Methodology serialization to and from JSON', () {
      final method = MethodologyDefinition(
        id: 'zaytsev_reading',
        name: 'Обучение чтению по складам',
        authorName: 'Н. А. Зайцев',
        year: 1989,
        subjectArea: 'Обучение чтению',
        paradigm: 'Звучащие кубики и таблицы складов',
        keyPrinciples: ['Пение складов', 'Никаких букв и слогов — только склады'],
        fieldProfile: const DidacticFieldProfile(
          preferLetterBoxes: true,
          preferNarrowObliqueRuling65: true,
        ),
        createdAt: DateTime.now(),
      );

      final jsonStr = method.toJson();
      final restored = MethodologyDefinition.fromJson(jsonStr);

      expect(restored.id, equals(method.id));
      expect(restored.name, equals(method.name));
      expect(restored.authorName, equals(method.authorName));
      expect(restored.fieldProfile.preferLetterBoxes, isTrue);
      expect(restored.fieldProfile.preferNarrowObliqueRuling65, isTrue);
    });
  });
}
