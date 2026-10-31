import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:metodist/models/conspect.dart';
import 'package:metodist/models/thematic_world.dart';
import 'package:metodist/services/pdf_export_service.dart';
import 'package:metodist/services/pdf_icons_helper.dart';
import 'package:metodist/services/yandex_art_service.dart';

class _AllowRealNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealNetworkHttpOverrides();

  group('5 Thematic Worlds PDF & YandexART Tests', () {
    test('1. Intelligent auto-routing resolves correct worlds for different subjects and age groups', () {
      // 1. Космос (математика, счет)
      final spaceWorld = ThematicWorld.fromTopic(
        topic: 'Сложение и вычитание в пределах 20',
        subject: 'Математика',
        ageGroup: '1 класс',
      );
      expect(spaceWorld.type, equals(ThematicWorldType.space));
      expect(spaceWorld.mascotName, equals('Лисёнок Астро'));

      // 2. Лес (чтение, буквы, звуки)
      final forestWorld = ThematicWorld.fromTopic(
        topic: 'Буква А и звук [а], слоги',
        subject: 'Обучение грамоте и чтению',
        ageGroup: '1 класс',
      );
      expect(forestWorld.type, equals(ThematicWorldType.forest));
      expect(forestWorld.mascotName, equals('Сова-Профессор Филя'));

      // 3. Детектив (орфографические ловушки, ошибки)
      final detectiveWorld = ThematicWorld.fromTopic(
        topic: 'Орфографические ловушки и безударные гласные в корне',
        subject: 'Русский язык',
        ageGroup: '2 класс',
      );
      expect(detectiveWorld.type, equals(ThematicWorldType.detective));
      expect(detectiveWorld.mascotName, equals('Енот-Следопыт Шерлок'));

      // 4. Мастерская (геометрия, доли, умножение)
      final workshopWorld = ThematicWorld.fromTopic(
        topic: 'Отрезок, сантиметр и геометрические фигуры',
        subject: 'Математика',
        ageGroup: '1 класс',
      );
      expect(workshopWorld.type, equals(ThematicWorldType.workshop));
      expect(workshopWorld.mascotName, equals('Бобрёнок-Инженер Винтик'));

      // 5. Полянка (дошкольники 4-5 лет)
      final meadowWorld = ThematicWorld.fromTopic(
        topic: 'Веселый счет и пальчиковые игры',
        subject: 'Развитие речи',
        ageGroup: 'Дошкольники (4-5 лет)',
      );
      expect(meadowWorld.type, equals(ThematicWorldType.meadow));
      expect(meadowWorld.mascotName, equals('Медвежонок Миша и Пчёлка'));
    });

    test('2. Generate and verify PDF documents for each of the 5 Thematic Worlds', () async {
      final nunitoRegularBytes = File('Nunito-Regular.ttf').readAsBytesSync();
      final nunitoBoldBytes = File('Nunito-Bold.ttf').readAsBytesSync();
      final fontRegular = pw.Font.ttf(nunitoRegularBytes.buffer.asByteData());
      final fontBold = pw.Font.ttf(nunitoBoldBytes.buffer.asByteData());

      final materialIcon = await PdfIconsHelper.loadIcon('icon_worksheet');
      final starGold = await PdfIconsHelper.loadStarGold();
      final starGray = await PdfIconsHelper.loadStarGray();

      final outDir = Directory(r'docs\thematic_worlds_pdf');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      for (final world in ThematicWorld.allWorlds) {
        final conspect = Conspect(
          id: 'world_test_${world.id}',
          title: '${world.title}: Учебный лист',
          topic: '${world.title} — исследование темы',
          methodId: 'method_01',
          methodName: 'Классическая методика ФГОС',
          subject: world.type == ThematicWorldType.space || world.type == ThematicWorldType.workshop ? 'Математика' : 'Русский язык',
          ageGroup: world.type == ThematicWorldType.meadow ? 'Дошкольники (4-5 лет)' : '1 класс',
          duration: '35 мин',
          thematicWorldId: world.id,
          content: '''
# Лист заданий для печати: ${world.title}
## 1. Задание первой линии [ПОИСК]
Внимательно посмотри на подсказку маскота ${world.mascotName} и выполни действие.

## 2. Задание со звездочкой [ПРАКТИКА]
Реши пример и заполни рабочую область.

## ⭐⭐⭐ Оцени свои успехи
Оцени, насколько интересно и понятно было выполнять миссию "${world.missionBadge}".
''',
          generatedMaterials: ['worksheet'],
          createdAt: DateTime.now(),
        );

        // Pre-generate / load high-resolution vector avatar and banner
        final mascotBase64 = await YandexArtService.generateFallbackEducationalArt(
          type: 'world_mascot_${world.id}',
          label: world.mascotName,
          width: 140,
          height: 140,
        );
        final bannerBase64 = await YandexArtService.generateFallbackEducationalArt(
          type: 'world_banner_${world.id}',
          label: world.title,
          width: 640,
          height: 160,
        );

        final mascotImage = pw.MemoryImage(base64Decode(mascotBase64));
        final bannerImage = pw.MemoryImage(base64Decode(bannerBase64));

        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            theme: pw.ThemeData.withFont(
              base: fontRegular,
              bold: fontBold,
              italic: fontRegular,
              fontFallback: [fontRegular, fontBold],
            ),
            header: (context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.only(bottom: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.indigo200, width: 0.8),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: world.pdfPrimary,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'МЕТОДИСТ PRO • ${world.missionBadge}',
                      style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 7.5),
                    ),
                  ),
                  pw.Text(
                    '${world.title} • Маскот: ${world.mascotName}',
                    style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700, fontSize: 8.5),
                  ),
                ],
              ),
            ),
            build: (context) => [
              PdfExportService.buildPdfTitleForTest(
                conspect,
                PdfMaterialType.worksheet,
                materialIcon,
                world: world,
                mascotImage: mascotImage,
                bannerImage: bannerImage,
              ),
              pw.SizedBox(height: 8),
              PdfExportService.buildMaterialInfoForTest(conspect, PdfMaterialType.worksheet),
              pw.SizedBox(height: 10),
              ...PdfExportService.buildContentWidgetsForTest(
                conspect.content,
                fontRegular,
                fontBold,
                {},
                starGold: starGold,
                starGray: starGray,
                isWorksheetOrHomework: true,
              ),
            ],
          ),
        );

        final bytes = await pdf.save();
        expect(bytes.length, greaterThan(30000), reason: 'PDF для мира ${world.title} должен быть валидным и содержать графику');

        final targetFile = File('${outDir.path}/world_${world.id}.pdf');
        await targetFile.writeAsBytes(bytes);
        expect(targetFile.existsSync(), isTrue);
      }
    });
  });
}
