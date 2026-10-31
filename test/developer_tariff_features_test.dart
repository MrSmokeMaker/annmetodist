import 'package:flutter_test/flutter_test.dart';
import 'package:metodist/models/pricing_plan.dart';
import 'package:metodist/models/tariff.dart';
import 'package:metodist/models/custom_world.dart';
import 'package:metodist/models/custom_methodology.dart';
import 'package:metodist/models/department_team.dart';
import 'package:metodist/services/developer_api_service.dart';
import 'package:metodist/services/curriculum_bulk_service.dart';
import 'package:metodist/services/docx_export_service.dart';

void main() {
  group('Тариф «Разработчик»: ценообразование и уровни доступа', () {
    test('Тариф Разработчик имеет точную цену 1199 при оплате за год и 1499 в месяц', () {
      final devPlan = PricingPlan.developer;
      expect(devPlan.id, anyOf('developer', 'director'));
      expect(devPlan.name, anyOf('Разработчик', 'Директор'));
      expect(devPlan.annualMonthlyPrice, 1199);
      expect(devPlan.monthlyPrice, 1499);
      expect(devPlan.annualTotalPrice, 14388);
      expect(devPlan.badge, 'ФЛАГМАН');
      expect(devPlan.features.length, greaterThanOrEqualTo(6));
    });

    test('UserTariff корректно определяет флаг isDeveloper', () {
      final freeTariff = UserTariff(TariffLevel.free);
      final practiceTariff = UserTariff(TariffLevel.practice);
      final proTariff = UserTariff(TariffLevel.pro);
      final devTariff = UserTariff(TariffLevel.developer);

      expect(freeTariff.isDeveloper, isFalse);
      expect(practiceTariff.isDeveloper, isFalse);
      expect(proTariff.isDeveloper, isFalse);
      expect(devTariff.isDeveloper, isTrue);

      expect(TariffLevelExt(UserTariff.fromString('developer')).isDeveloper, isTrue);
      expect(TariffLevelExt(UserTariff.fromString('Разработчик')).isDeveloper, isTrue);
    });
  });

  group('Модуль 1: Студия авторских миров и YandexART', () {
    test('CustomWorldConfig корректно преобразуется в ThematicWorld', () {
      final config = CustomWorldConfig(
        id: 'school_lyceum_1',
        title: 'Мир Лицея №1',
        subtitle: 'Исследовательская станция Лицея',
        schoolName: 'Лицей №1',
        mascotName: 'Кот Учёный',
        mascotRole: 'Главный наставник',
        primaryColorHex: 0xFF4F46E5,
        accentColorHex: 0xFF818CF8,
        yandexArtStylePrompt: 'советский диафильм 1970-х',
        supportPhrase: 'Каждая задача делает нас сильнее!',
      );

      final world = config.toThematicWorld();
      expect(world.id, 'school_lyceum_1');
      expect(world.title, 'Мир Лицея №1');
      expect(world.mascotName, 'Кот Учёный');
      expect(world.primaryColorHex, 0xFF4F46E5);
      expect(world.accentColorHex, 0xFF818CF8);
      expect(world.missionBadge, 'Лицей №1');
      expect(world.greetingPhrase, 'Каждая задача делает нас сильнее!');
    });
  });

  group('Модуль 2: Конструктор авторских методик', () {
    test('CustomMethodology генерирует системный промпт с учетом стоп-слов и тона', () {
      final method = CustomMethodology(
        id: 'triz_method_1',
        name: 'ТРИЗ-Педагогика',
        creatorName: 'Учитель-новатор',
        tone: PedagogicalTone.triz,
        stopWords: ['очевидно', 'легко', 'глупый'],
        structureBlocks: ['Противоречие', 'Идеальный конечный результат', 'Творческая задача'],
        systemPromptTemplate: 'Используй методы ТРИЗ и развивай изобретательское мышление.',
      );

      final fullPrompt = method.buildSystemPrompt();
      expect(fullPrompt, contains('ТРИЗ-Педагогика'));
      expect(fullPrompt, contains('Игровой ТРИЗ'));
      expect(fullPrompt, contains('очевидно, легко, глупый'));
      expect(fullPrompt, contains('Противоречие'));
      expect(fullPrompt, contains('Идеальный конечный результат'));
    });
  });

  group('Модуль 3: REST API и экспорт в LMS (МЭШ, ЭЖД, Сферум, Moodle)', () {
    test('DeveloperApiService генерирует уникальный живой токен', () {
      final token = DeveloperApiService.generateDevToken();
      expect(token, startsWith('mdev_live_'));
      expect(token.length, greaterThan(25));
    });

    test('DeveloperApiService экспортирует конспект в JSON, Markdown и HTML', () {
      final conspects = CurriculumBulkService.generateQuarterCurriculum(
        subject: 'Математика',
        ageGroup: '3 класс',
        methodId: 'pchelko',
        methodName: 'Методика А.С. Пчёлко',
        worldId: 'space',
        lessonCount: 1,
      );
      final sampleConspect = conspects.first;

      final jsonExport = DeveloperApiService.exportConspectToJson(sampleConspect);
      expect(jsonExport, contains('"subject": "Математика"'));
      expect(jsonExport, contains('"thematicWorld": "Звёздная Одиссея"'));

      final mdExport = DeveloperApiService.exportConspectToMarkdown(sampleConspect);
      expect(mdExport, contains('# '));
      expect(mdExport, contains('Математика'));
      expect(mdExport, contains('Лисёнок Астро'));

      final htmlExport = DeveloperApiService.exportConspectToHtml(sampleConspect);
      expect(htmlExport, contains('<!DOCTYPE html>'));
      expect(htmlExport, contains('header-banner'));
      expect(htmlExport, contains('Лисёнок Астро'));
    });
  });

  group('Модуль 4: Пакетный генератор курса на четверть (15-30 уроков) и аудит объёма', () {
    test('Генерация сквозного блока из 20 уроков с сюжетной линией игрового мира', () {
      final quarterConspects = CurriculumBulkService.generateQuarterCurriculum(
        subject: 'Математика',
        ageGroup: '3 класс',
        methodId: 'pchelko',
        methodName: 'Методика А.С. Пчёлко',
        worldId: 'space',
        lessonCount: 20,
      );

      expect(quarterConspects.length, 20);
      expect(quarterConspects[0].title, contains('Урок 1'));
      expect(quarterConspects[19].title, contains('Урок 20'));
      expect(quarterConspects[0].content, contains('Эпизод 1 / 20'));
      expect(quarterConspects[19].content, contains('Эпизод 20 / 20'));
    });

    test('Обязательный автоматический аудит объёма и качества уроков курса', () {
      final quarterConspects = CurriculumBulkService.generateQuarterCurriculum(
        subject: 'Математика',
        ageGroup: '3 класс',
        methodId: 'pchelko',
        methodName: 'Методика А.С. Пчёлко',
        worldId: 'space',
        lessonCount: 1,
      );

      final result = CurriculumBulkService.validateLessonQuality(quarterConspects.first);
      expect(result.isValid, isTrue);
      expect(result.wordCount, greaterThanOrEqualTo(300));
      expect(result.hasObjectives, isTrue);
      expect(result.hasWorksheet, isTrue);
      expect(result.hasHomework, isTrue);
      expect(result.hasAnswerKeys, isTrue);
      expect(result.qualityScore, greaterThanOrEqualTo(90.0));
      expect(result.passedAudits.length, greaterThanOrEqualTo(4));
    });

    test('Создание DOCX файла урока через DocxExportService.generateDocxBytes', () {
      final quarterConspects = CurriculumBulkService.generateQuarterCurriculum(
        subject: 'Математика',
        ageGroup: '3 класс',
        methodId: 'pchelko',
        methodName: 'Методика А.С. Пчёлко',
        worldId: 'space',
        lessonCount: 1,
      );

      final docxBytes = DocxExportService.generateDocxBytes(quarterConspects.first);
      expect(docxBytes, isNotNull);
      expect(docxBytes.length, greaterThan(100));
      // First 2 bytes of ZIP/DOCX are always PK (0x50, 0x4B)
      expect(docxBytes[0], 0x50);
      expect(docxBytes[1], 0x4B);
    });
  });

  group('Модуль 6: Лицензия кафедры (Командный доступ)', () {
    test('Управление составом кафедры (до 5 рабочих мест)', () {
      final team = DepartmentTeam.createDefault();
      expect(team.maxSeats, 5);
      expect(team.activeSeatsCount, 3);
      expect(team.remainingSeats, 2);
      expect(team.canAddMember, isTrue);

      team.members.add(
        DepartmentMember(
          id: 'mem_4',
          name: 'Ольга Николаевна',
          email: 'olga@school.ru',
          role: 'Учитель',
          joinedAt: DateTime.now(),
        ),
      );
      expect(team.activeSeatsCount, 4);
      expect(team.remainingSeats, 1);
      expect(team.canAddMember, isTrue);

      team.members.add(
        DepartmentMember(
          id: 'mem_5',
          name: 'Дмитрий Сергеевич',
          email: 'dmitry@school.ru',
          role: 'Ассистент',
          joinedAt: DateTime.now(),
        ),
      );
      expect(team.activeSeatsCount, 5);
      expect(team.remainingSeats, 0);
      expect(team.canAddMember, isFalse);
    });
  });
}
